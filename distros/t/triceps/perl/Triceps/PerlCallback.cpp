//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
// Helpers to call Perl code back from C++.

#include <typeinfo>
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "TricepsPerl.h"
#include "PerlCallback.h"

// ###################################################################################

using namespace TRICEPS_NS;

namespace TRICEPS_NS
{
namespace TricepsPerl 
{

///////////////////////// PerlCallback ///////////////////////////////////////////////

PerlCallback::PerlCallback(bool threadable) :
	threadinit_(threadable),
	threadable_(threadable),
	deepCopied_(false),
	code_(NULL)
{ }

PerlCallback::PerlCallback(const PerlCallback *other) :
	threadinit_(other->threadinit_),
	threadable_(other->threadable_),
	deepCopied_(true),
	code_(NULL),
	argst_(other->argst_),
	codestr_(other->codestr_),
	errt_(other->errt_)
{
}

PerlCallback::~PerlCallback()
{
	clear();
}

PerlCallback *PerlCallback::deepCopy()
{
	if (this == NULL)
		return NULL;
	return new PerlCallback(this);
}

void PerlCallback::clear()
{
	if (code_) {
		SvREFCNT_dec(code_);
		code_ = NULL;
	}
	if (!args_.empty()) {
		for (size_t i = 0; i < args_.size(); i++) {
			SvREFCNT_dec(args_[i]);
		}
		args_.clear();
	}
	codestr_.clear();
	argst_.clear();
	threadable_ = threadinit_;
	errt_ = NULL;
}

void PerlCallback::setCode(SV *code, const char *fname)
{
	setCodeFmt(code, "%s", fname);
}

void PerlCallback::setCodeFmt(SV *code, const char *fmt, ...)
{
	va_list ap;
	va_start(ap, fmt);
	try {
		setCodeVa(code, fmt, ap);
	} catch(Exception) {
		va_end(ap);
		throw;
	}
	va_end(ap);
}

void PerlCallback::setCodeVa(SV *code, const char *fmt, va_list ap)
{
	clear();

	if (code == NULL) {
		string smsg = vstrprintf(fmt, ap);
		throw Exception::f("%s: code must not be NULL", smsg.c_str());
	}

	// printf("DBG %s: threadable\n", fmt);
	if (SvPOK(code)) {
		STRLEN len;
		char *s = SvPV(code, len);
		codestr_.assign(s, len);

		Erref err = compileCodeVa(fmt, ap);

		if (err->hasError()) {
			throw Exception(err, false); // XXX add a heading message?
		}
	} else { 
		if (!SvROK(code) || SvTYPE(SvRV(code)) != SVt_PVCV) {
			string smsg = vstrprintf(fmt, ap);
			throw Exception::f("%s: code must be a source code string or a reference to Perl function", smsg.c_str());
		}

		if (threadable_) {
			threadable_ = false;
			// here it's not a fatal error, just remember for the future,
			// in case if someone would ever want to make a deep copy
			string smsg = vstrprintf(fmt, ap);
			errt_.f("%s: the code is not a source code string", smsg.c_str());
		}

		code_ = newSV(0);
		sv_setsv(code_, code);
	}
}

// Append another argument to args_.
// @param arg - argument value to append; will make a copy of it.
void PerlCallback::appendArg(SV *arg)
{
	SV *argcp = newSV(0);
	sv_setsv(argcp, arg);
	args_.push_back(argcp);

	if (threadable_) {
		try {
			argst_.push_back(PerlValue::make(arg));
		} catch(Exception e) {
			threadable_ = false;
			errt_.fAppend(e.getErrors(), "argument %d is not threadable:", (int)args_.size()); // args counted from 1
		}
	}
}

bool PerlCallback::equals(const PerlCallback *other) const
{
	if (threadable_ != other->threadable_)
		return false;

	if (threadable_) {
		// compare the internal representations, it's faster and better, and
		// the Perl-exported representation might be not initialized yet
		if (codestr_ != other->codestr_)
			return false;
		if (argst_.size() != other->argst_.size())
			return false;
		for (size_t i = 0; i < argst_.size(); ++i) {
			if (!argst_[i]->equals(other->argst_[i]))
				return false;
		}
		return true;
	}

	if (args_.size() != other->args_.size())
		return false;
	if ((code_ == NULL) ^ (other->code_ == NULL))
		return false;

	if (code_ != NULL && SvIV(code_) != SvIV(other->code_)) // same reference
		return false;

	dSP;

	for (size_t i = 0; i < args_.size(); ++i) {
		int nv;
		int result;
		bool error = false;
		SV *a1 = args_[i];
		SV *a2 = other->args_[i];

		ENTER; SAVETMPS; 

		PUSHMARK(SP);
		XPUSHs(a1);
		XPUSHs(a2);
		PUTBACK; 

		const char *func = ((SvIOK(a1) || SvNOK(a1)) && (SvIOK(a2) || SvNOK(a2))) ? "Triceps::_compareNumber" :  "Triceps::_compareText" ;
		nv = call_pv(func, G_SCALAR|G_EVAL);

		if (SvTRUE(ERRSV)) {
			warn("Internal error in function %s: %s", func, SvPV_nolen(ERRSV));
			error = true;
		}

		SPAGAIN;
		if (nv < 1) { 
			result = 1; // doesn't match
		} else {
			for (; nv > 1; nv--)
				POPs;
			SV *perlres = POPs;
			result = SvTRUE(perlres);
		}
		PUTBACK; 

		FREETMPS; LEAVE;

		if (error || result) // if equal, the comparison will be 0
			return false;
	}
	
	return true;
}

void PerlCallback::initialize(HoldRowTypes *holder)
{
	if (threadable_ && deepCopied_ && !errt_->hasError()) {
		errt_ = compileCodeFmt("recompilation in a new thread");
		if (errt_->hasError())
			return; // error remembered, nothing else to do

		for (PerlValueVec::iterator it = argst_.begin(); it != argst_.end(); ++it)
			args_.push_back((*it)->restore(holder));

		deepCopied_ = false;
	}
}

Erref PerlCallback::compileCodeFmt(const char *fmt, ...)
{
	va_list ap;
	va_start(ap, fmt);
	Erref err = compileCodeVa(fmt, ap);
	va_end(ap);
	return err;
}

Erref PerlCallback::compileCodeVa(const char *fmt, va_list ap)
{
	// printf("DBG %s: source code\n", fmt);
	// try to compile the code from a string
	Erref err;

	// XXX should it check for an empty string?

	string subcode = "sub {\n";
	subcode += codestr_;
	subcode += "\n}\n";

	SV *code = NULL;
	dSP;

	ENTER; SAVETMPS; 

	PUSHMARK(SP);
	XPUSHs( sv_2mortal(newSVpv(subcode.c_str(), subcode.size())) );
	PUTBACK; 

	// eval_pv() and eval_sv() don't report the errors properly
	int nv = call_pv("::_Triceps_eval_", G_SCALAR|G_EVAL);

	if (SvTRUE(ERRSV)) {
		// printf("DBG compilation got an error\n");
		va_list copy_ap;
		va_copy(copy_ap, ap);
		string smsg = vstrprintf(fmt, copy_ap);
		va_end(copy_ap);
		err.f("%s: failed to compile the source code", smsg.c_str());
		err.f("Compilation error: %s", SvPV_nolen(ERRSV));
	}

	SPAGAIN;
	if (nv < 1) { 
		va_list copy_ap;
		va_copy(copy_ap, ap);
		string smsg = vstrprintf(fmt, copy_ap);
		va_end(copy_ap);
		err.f("%s: source code compilation returned nothing", smsg.c_str());
	} else {
		for (; nv > 1; nv--)
			POPs;
		code = POPs;
	}
	PUTBACK; 

	if (code != NULL)
		SvREFCNT_inc(code); // to get over the LEAVE

	FREETMPS; LEAVE;

	if (!err->hasError()) {
		if (code == NULL) {
			va_list copy_ap;
			va_copy(copy_ap, ap);
			string smsg = vstrprintf(fmt, copy_ap);
			va_end(copy_ap);
			err.f("%s: internal error: the source code compilation returned NULL", smsg.c_str());
		} else if (!SvROK(code) || SvTYPE(SvRV(code)) != SVt_PVCV) {
			va_list copy_ap;
			va_copy(copy_ap, ap);
			string smsg = vstrprintf(fmt, copy_ap);
			va_end(copy_ap);
			err.f("%s: the source code compilation returned not a code object", smsg.c_str());
		}
	}

	if (err->hasError()) {
		err.fAppend(new Errors(subcode), "The source code was:");
	} else {
		code_ = newSV(0);
		sv_setsv(code_, code);
	}
	if (code != NULL)
		SvREFCNT_dec(code); // by now it's either copied or not needed

	return err;
}

bool callbackEquals(const PerlCallback *p1, const PerlCallback *p2)
{
	if (p1 == NULL || p2 == NULL) {
		return p1 == p2;
	} else {
		return p1->equals(p2);
	}
}

void callbackSuccessOrThrow(const char *fmt, ...)
{
	if (SvTRUE(ERRSV)) {
		clearErrMsg(); // in case if it was thrown by Triceps, clean up
		// propagate to the caller
		Erref err = new Errors(SvPV_nolen(ERRSV));

		va_list ap;
		va_start(ap, fmt);
		string s = vstrprintf(fmt, ap);
		va_end(ap);
		err->appendMsg(true, s);

		throw TRICEPS_NS::Exception(err, false);
	}
}

///////////////////////// PerlLabel ///////////////////////////////////////////////

PerlLabel::PerlLabel(Unit *unit, const_Onceref<RowType> rtype, const string &name, 
		Onceref<PerlCallback> clr, Onceref<PerlCallback> cb) :
	Label(unit, rtype, name),
	clear_(clr),
	cb_(cb)
{ }

PerlLabel::~PerlLabel()
{ }

Onceref<PerlLabel> PerlLabel::makeSimple(Unit *unit, const_Onceref<RowType> rtype,
	const string &name, SV *code, const char *fmt, ...)
{
	Onceref<PerlCallback> clr = new PerlCallback();
	try {
		clr->setCode(get_sv("Triceps::_DEFAULT_CLEAR_LABEL", 0), "");
	} catch (Exception e) {
		// should really never fail, but just in case
		va_list ap;
		va_start(ap, fmt);
		string s = vstrprintf(fmt, ap);
		va_end(ap);
		throw Exception::f("%s: internal error, bad value in $Triceps::_DEFAULT_CLEAR_LABEL", s.c_str());
	}

	Onceref<PerlCallback> cb = new PerlCallback();
	string errmsg = "Label '";
	errmsg += name;
	errmsg += "'";
	cb->setCode(code, errmsg.c_str()); // may throw
	return new PerlLabel(unit, rtype, name, clr, cb);
}

void PerlLabel::execute(Rowop *arg) const
{
	dSP;

	if (cb_.isNull()) {
		warn("Error in label %s handler: attempted to call the label that has been cleared", getName().c_str());
		return;
	}

	WrapRowop *wrop = new WrapRowop(arg);
	SV *svrop = newSV(0);
	sv_setref_pv(svrop, "Triceps::Rowop", (void *)wrop);

	WrapLabel *wlab = new WrapLabel(const_cast<PerlLabel *>(this));
	SV *svlab = newSV(0);
	sv_setref_pv(svlab, "Triceps::Label", (void *)wlab);

	PerlCallbackStartCall(cb_);

	XPUSHs(svlab);
	XPUSHs(svrop);

	PerlCallbackDoCall(cb_);

	// this calls the DELETE methods on wrappers
	SvREFCNT_dec(svrop);
	SvREFCNT_dec(svlab);

	callbackSuccessOrThrow("Detected in the unit '%s' label '%s' execution handler.", getUnitName().c_str(), getName().c_str());
}

void PerlLabel::clearSubclass()
{
	dSP;

	cb_ = NULL; // drop the execution callback

	if (clear_.isNull()) 
		return; // nothing to do
	
	WrapLabel *wlab = new WrapLabel(const_cast<PerlLabel *>(this));
	SV *svlab = newSV(0);
	sv_setref_pv(svlab, "Triceps::Label", (void *)wlab);

	PerlCallbackStartCall(clear_);

	XPUSHs(svlab);

	PerlCallbackDoCall(clear_);

	// this calls the DELETE methods on wrappers
	SvREFCNT_dec(svlab);

	clear_ = NULL; // eventually drop the callback, before any chance of throwing!

	callbackSuccessOrThrow("Detected in the unit '%s' label '%s' clearing handler.", getUnitName().c_str(), getName().c_str());
}

///////////////////////// UnitTracerPerl ///////////////////////////////////////////////

UnitTracerPerl::UnitTracerPerl(Onceref<PerlCallback> cb) :
	cb_(cb)
{ }

void UnitTracerPerl::execute(Unit *unit, const Label *label, const Label *fromLabel, Rowop *rop, Unit::TracerWhen when)
{
	dSP;

	if (cb_.isNull()) {
		warn("Error in unit %s tracer: attempted to call the tracer that has been cleared", 
			unit->getName().c_str());
		return;
	}

	SV *svunit = newSV(0);
	sv_setref_pv(svunit, "Triceps::Unit", (void *)(new WrapUnit(unit)));

	SV *svlab = newSV(0);
	sv_setref_pv(svlab, "Triceps::Label", (void *)(new WrapLabel(const_cast<Label *>(label))));

	SV *svfrlab = newSV(0);
	if (fromLabel != NULL)
		sv_setref_pv(svfrlab, "Triceps::Label", (void *)(new WrapLabel(const_cast<Label *>(fromLabel))));

	SV *svrop = newSV(0);
	sv_setref_pv(svrop, "Triceps::Rowop", (void *)(new WrapRowop(rop)));

	SV *svwhen = newSViv(when);

	PerlCallbackStartCall(cb_);

	XPUSHs(svunit);
	XPUSHs(svlab);
	XPUSHs(svfrlab);
	XPUSHs(svrop);
	XPUSHs(svwhen);

	PerlCallbackDoCall(cb_);

	// this calls the DELETE methods on wrappers
	SvREFCNT_dec(svunit);
	SvREFCNT_dec(svlab);
	SvREFCNT_dec(svfrlab);
	SvREFCNT_dec(svrop);
	SvREFCNT_dec(svwhen);

	if (SvTRUE(ERRSV)) {
		// If in eval, croak may cause issues by doing longjmp(), so better just warn.
		// Would exit(1) be better?
		warn("Error in unit %s tracer: %s", 
			unit->getName().c_str(), SvPV_nolen(ERRSV));

	}
}

Onceref<PerlCallback> GetSvCall(SV *svptr, const char *fmt, ...)
{
	Autoref<PerlCallback> cb = new PerlCallback();

	va_list ap;
	va_start(ap, fmt);

	try {
		if (SvROK(svptr)) {
			if (SvTYPE(SvRV(svptr)) == SVt_PVAV) {
				AV *array = (AV*)SvRV(svptr);
				int len = av_len(array)+1; // av_len returns the index of last element
				if (len > 0) {
					SV *code = *av_fetch(array, 0, 0);
					if (SvROK(code) && SvTYPE(SvRV(code)) == SVt_PVCV
					|| SvPOK(code)) {
						cb->setCodeVa(code, fmt, ap); // may throw
						for (int i = 1; i < len; i++) { // pick up the args
							cb->appendArg(*av_fetch(array, i, 0));
						}
						va_end(ap);
						return cb;
					}
				}
			} else if (SvTYPE(SvRV(svptr)) == SVt_PVCV) {
				cb->setCodeVa(svptr, fmt, ap); // may throw
				va_end(ap);
				return cb;
			}
		} else if (SvPOK(svptr)) {
			cb->setCodeVa(svptr, fmt, ap); // may throw
			va_end(ap);
			return cb;
		}
	} catch (Exception) {
		va_end(ap);
		throw;
	}
	string smsg = vstrprintf(fmt, ap);
	va_end(ap);
	throw TRICEPS_NS::Exception::f("%s value must be a reference to a function or an array starting with a reference to function", smsg.c_str());
}

}; // Triceps::TricepsPerl
}; // Triceps


