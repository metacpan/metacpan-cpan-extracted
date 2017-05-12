//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
// The Triceps aggregator for Perl calls and the wrapper for it.

#include <typeinfo>
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "TricepsPerl.h"
#include "PerlCallback.h"
#include "PerlAggregator.h"
#include "WrapAggregatorContext.h"

// ###################################################################################

using namespace TRICEPS_NS;

namespace TRICEPS_NS
{
namespace TricepsPerl 
{

// ####################### PerlAggregatorType ########################################

PerlAggregatorType::PerlAggregatorType(const string &name, const RowType *rt, 
		Onceref<PerlCallback> cbInit,
		Onceref<PerlCallback> cbConstructor, Onceref<PerlCallback> cbHandler):
	AggregatorType(name, rt),
	cbInit_(cbInit),
	cbConstructor_(cbConstructor),
	cbHandler_(cbHandler)
{ }

PerlAggregatorType::PerlAggregatorType(const PerlAggregatorType &agg, HoldRowTypes *holder):
	AggregatorType(agg, holder),
	cbInit_(agg.cbInit_->deepCopy()),
	cbConstructor_(agg.cbConstructor_->deepCopy()),
	cbHandler_(agg.cbHandler_->deepCopy()),
	hrt_(holder)
{ }

AggregatorType *PerlAggregatorType::copy() const
{
	return new PerlAggregatorType(*this);
}

AggregatorType *PerlAggregatorType::deepCopy(HoldRowTypes *holder) const
{
	return new PerlAggregatorType(*this, holder);
}

AggregatorGadget *PerlAggregatorType::makeGadget(Table *table, IndexType *intype) const
{
	// just use the generic gadget, there is nothing special about it
	return new AggregatorGadget(this, table, intype);
}

Aggregator *PerlAggregatorType::makeAggregator(Table *table, AggregatorGadget *gadget) const
{
	SV *state = NULL;

	if (!cbConstructor_.isNull()) {
		dSP;

		PerlCallbackStartCall(cbConstructor_);
		PerlCallbackDoCallScalar(cbConstructor_, state);
		
		if (SvTRUE(ERRSV)) {
			Erref err;
			err.f("Error in unit %s table %s aggregator %s constructor: %s", 
				gadget->getUnit()->getName().c_str(), table->getName().c_str(), gadget->getName().c_str(), SvPV_nolen(ERRSV));
			table->setStickyError(err);
		}
	}
	return new PerlAggregator(table, gadget, state);
}

bool PerlAggregatorType::equals(const Type *t) const
{
	if (!AggregatorType::equals(t))
		return false;

	const PerlAggregatorType *at = static_cast<const PerlAggregatorType *>(t);

	// XXX this means that it may differ before and after initialization
	return callbackEquals(cbInit_, at->cbInit_)
		&& callbackEquals(cbConstructor_, at->cbConstructor_)
		&& callbackEquals(cbHandler_, at->cbHandler_);
}

bool PerlAggregatorType::match(const Type *t) const
{
	if (!AggregatorType::match(t))
		return false;

	const PerlAggregatorType *at = static_cast<const PerlAggregatorType *>(t);

	// XXX this means that it may differ before and after initialization
	return callbackEquals(cbInit_, at->cbInit_)
		&& callbackEquals(cbConstructor_, at->cbConstructor_)
		&& callbackEquals(cbHandler_, at->cbHandler_);
}

void PerlAggregatorType::initialize(TableType *tabtype, IndexType *intype)
{
	if (initialized_)
		return; // skip the second initialization

	if (errors_->hasError())
		return; // already failed, don't try any more

	dSP;

	Erref errInit, errConstructor, errHandler;

	if (!cbInit_.isNull()) {
		cbInit_->initialize(hrt_);
		errInit = cbInit_->getErrors();
		errors_.fAppend(errInit, "PerlAggregatorType: the init function is not compatible with multithreading:");
	}
	if (!cbConstructor_.isNull()) {
		cbConstructor_->initialize(hrt_);
		errConstructor = cbConstructor_->getErrors();
		errors_.fAppend(errConstructor, "PerlAggregatorType: the constructor function is not compatible with multithreading:");
	}
	if (!cbHandler_.isNull()) {
		cbHandler_->initialize(hrt_);
		errHandler = cbHandler_->getErrors();
		errors_.fAppend(errHandler, "PerlAggregatorType: the handler function is not compatible with multithreading:");
	}

	hrt_ = NULL; // its work is done

	if (errors_->hasError()) {
		return; // no point in going further
	}

	if (!cbInit_.isNull()) {
		SV *svself = newSV(0);
		sv_setref_pv(svself, "Triceps::AggregatorType", (void *)(new WrapAggregatorType(this)));

		SV *svtabt = newSV(0);
		sv_setref_pv(svtabt, "Triceps::TableType", (void *)(new WrapTableType(tabtype)));

		SV *svidxt = newSV(0);
		sv_setref_pv(svidxt, "Triceps::IndexType", (void *)(new WrapIndexType(intype)));

		SV *svtabrowt = newSV(0);
		sv_setref_pv(svtabrowt, "Triceps::RowType", (void *)(new WrapRowType(const_cast<RowType *>(tabtype->rowType()))));

		SV *svresrowt = newSV(0);
		if (!rowType_.isNull()) { // otherwise svresrowt will be left undef
			sv_setref_pv(svresrowt, "Triceps::RowType", (void *)(new WrapRowType(const_cast<RowType *>(rowType_.get()))));
		}

		PerlCallbackStartCall(cbInit_);
		XPUSHs(svself);
		XPUSHs(svtabt);
		XPUSHs(svidxt);
		XPUSHs(svtabrowt);
		XPUSHs(svresrowt);

		SV *sverrmsg = NULL;
		PerlCallbackDoCallScalar(cbInit_, sverrmsg);

		// this calls the DELETE methods on wrappers
		SvREFCNT_dec(svself);
		SvREFCNT_dec(svtabt);
		SvREFCNT_dec(svidxt);
		SvREFCNT_dec(svtabrowt);
		SvREFCNT_dec(svresrowt);

		if (sverrmsg != NULL && SvTRUE(sverrmsg)) {
			errors_->appendMultiline(true, SvPV_nolen(sverrmsg));
			return;
		}

		if (SvTRUE(ERRSV)) {
			errors_->appendMultiline(true, SvPV_nolen(ERRSV));
			return;
		}
	}

	// the handler must be set by now, or it's an error
	if (cbHandler_.isNull()) {
		errors_.f("PerlAggregatorType: the mandatory handler Perl function is still not set after initialization");
	}
	// the result row type must be set by now, or it's an error
	if (rowType_.isNull()) {
		errors_.f("PerlAggregatorType: the mandatory result row type is still not set after initialization");
	}

	initialized_ = true;
}

bool PerlAggregatorType::setRowType(const RowType *rt)
{
	if (initialized_)
		return false;
	rowType_ = rt;
	return true;
}
bool PerlAggregatorType::setConstructor(Onceref<PerlCallback> cbConstructor)
{
	if (initialized_)
		return false;
	cbConstructor_ = cbConstructor;
	return true;
}
bool PerlAggregatorType::setHandler(Onceref<PerlCallback> cbHandler)
{
	if (initialized_)
		return false;
	cbHandler_ = cbHandler;
	return true;
}

// ######################## PerlAggregator ###########################################

PerlAggregator::PerlAggregator(Table *table, AggregatorGadget *gadget, SV *sv):
	sv_(sv)
{ 
	if (sv_ != NULL)
		SvREFCNT_inc(sv_);
}

PerlAggregator::~PerlAggregator()
{
	if (sv_ != NULL)
		SvREFCNT_dec(sv_);
}

void PerlAggregator::setsv(SV *sv)
{
	if (sv_ != NULL)
		SvREFCNT_dec(sv_);
	sv_= sv;
	if (sv_ != NULL)
		SvREFCNT_inc(sv_);
}

void PerlAggregator::handle(Table *table, AggregatorGadget *gadget, Index *index,
	const IndexType *parentIndexType, GroupHandle *gh, Tray *dest,
	AggOp aggop, Rowop::Opcode opcode, RowHandle *rh)
{
	dSP;

	const PerlAggregatorType *at = static_cast<const PerlAggregatorType *>(gadget->getType());

	WrapTable *wtab = new WrapTable(table);
	SV *svtab = newSV(0);
	sv_setref_pv(svtab, "Triceps::Table", (void *)wtab);

	WrapAggregatorContext *ctx = new WrapAggregatorContext(table, gadget, index, parentIndexType, gh, dest);
	SV *svctx = newSV(0); 
	sv_setref_pv(svctx, "Triceps::AggregatorContext", (void *)ctx); // takes over the reference
	// warn("DEBUG PerlAggregator::handle context %p created with refcnt %d ptr %d", ctx, SvREFCNT(svctx), SvROK(svctx));
	SV *svctxcopy = newSV(0); // makes sure that the context stays referenced even if Perl code thanges its SV
	sv_setsv(svctxcopy, svctx);

	SV *svaggop = newSViv(aggop);

	SV *svopcode = newSViv(opcode);

	WrapRowHandle *wrh = new WrapRowHandle(table, rh);
	SV *svrh = newSV(0);
	sv_setref_pv(svrh, "Triceps::RowHandle", (void *)wrh);

	PerlCallbackStartCall(at->cbHandler_);

	XPUSHs(svtab);
	XPUSHs(svctx);
	XPUSHs(svaggop);
	XPUSHs(svopcode);
	XPUSHs(svrh);
	if (sv_ != NULL)
		XPUSHs(sv_);
	else
		XPUSHs(&PL_sv_undef);

	PerlCallbackDoCall(at->cbHandler_);
	
	// warn("DEBUG PerlAggregator::handle invalidating context");
	ctx->invalidate(); // context will stop working, even if Perl code kept a reference

	// this calls the DELETE methods on wrappers
	SvREFCNT_dec(svtab);
	// warn("DEBUG PerlAggregator::handle context decrease refcnt %d ptr %d", SvREFCNT(svctx), SvROK(svctx));
	SvREFCNT_dec(svctx);
	// warn("DEBUG PerlAggregator::handle context copy decrease refcnt %d ptr %d", SvREFCNT(svctxcopy), SvROK(svctxcopy));
	SvREFCNT_dec(svctxcopy);
	SvREFCNT_dec(svaggop);
	SvREFCNT_dec(svopcode);
	SvREFCNT_dec(svrh);

	if (SvTRUE(ERRSV)) {
		Erref err;
		err.f("Error in unit %s table %s aggregator %s handler: %s", 
			gadget->getUnit()->getName().c_str(), table->getName().c_str(), gadget->getName().c_str(), SvPV_nolen(ERRSV));
		table->setStickyError(err);

	}
	// warn("DEBUG PerlAggregator::handle done");
}

// ########################## wraps ##################################################

WrapMagic magicWrapAggregatorType = { "AggType" };

}; // Triceps::TricepsPerl
}; // Triceps

