//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
// The wrapper for FnBinding.

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "TricepsPerl.h"
#include "TricepsOpt.h"
#include "PerlCallback.h"


// Build a binding from components.
// Throws an Exception on errors.
//
// @param funcName - name of the calling function, for error messages.
// @param name - name of the FnBinding object to create.
// @param u - unit for creation of labels in the FnBinding.
// @param fnr - function return to bind to.
// @param labels - definition of labels in the bindings (a Perl array of elements that are
//        either label objects or code snippets)
// @param clearLabels - flag: on binding destruction automatically clear the labels that
//        have been passed as ready labels (the ones created from code snippets are always
//        cleared)
// @return - the creaed binding.
static Onceref<FnBinding> makeBinding(const char *funcName, const string &name, Unit *u, FnReturn *fnr, AV *labels, bool clearLabels)
{
	Autoref<FnBinding> fbind = new FnBinding(name, fnr);

	// parse labels, and create labels around the code snippets
	int len = av_len(labels)+1; // av_len returns the index of last element
	if (len % 2 != 0) // 0 elements is OK
		throw Exception(strprintf("%s: option 'labels' must contain elements in pairs, has %d elements", funcName, len), false);
	for (int i = 0; i < len; i+=2) {
		SV *svname, *svval;
		svname = *av_fetch(labels, i, 0);
		svval = *av_fetch(labels, i+1, 0);
		string entryname;
		bool cl = clearLabels;

		GetSvString(entryname, svname, "%s: in option 'labels' element %d name", funcName, i/2+1);

		Autoref<Label> lb = GetSvLabelOrCode(svval, "%s: in option 'labels' element %d with name '%s'", 
			funcName, i/2+1, SvPV_nolen(svname));
		if (lb.isNull()) {
			// it's a code snippet, make a label
			if (u == NULL) {
				throw Exception(strprintf("%s: option 'unit' must be set to handle the code reference in option 'labels' element %d with name '%s'", 
					funcName, i/2+1, SvPV_nolen(svname)), false);
			}
			string lbname = name + "." + entryname;
			RowType *rt = fnr->getRowType(entryname);
			if (rt == NULL) {
				throw Exception(strprintf("%s: in option 'labels' element %d has an unknown return label name '%s'", 
					funcName, i/2+1, SvPV_nolen(svname)), false);
			}
			lb = PerlLabel::makeSimple(u, rt, lbname, svval, "%s: in option 'labels' element %d with name '%s'",
				funcName, i/2+1, SvPV_nolen(svname));
			cl = true; // always clear these
		}
		fbind->addLabel(entryname, lb, cl);
	}
	try {
		checkOrThrow(fbind);
	} catch (Exception e) {
		throw Exception(e, strprintf("%s: invalid arguments:", funcName));
	}

	return fbind;
}

MODULE = Triceps::FnBinding		PACKAGE = Triceps::FnBinding
###################################################################################

int
CLONE_SKIP(...)
	CODE:
		RETVAL = 1;
	OUTPUT:
		RETVAL

#// The use is like this:
#//
#// $fnr = FnReturn->new(...);
#// $bind = FnBinding->new(
#//     name => "bind1", # used for diagnostics and the names of direct Perl labels
#//     on => $fnr, # determines the type of return
#//     unit => $unit, # needed only for the direct Perl code
#//     withTray => 1, # default is 0
#//     clearLabels => 1, # default is 0, affects only $labels, the ones created from subs are always cleared
#//     labels => [
#//         "name" => $label,
#//         "name" => sub { ... }, # will directly create a Perl label
#//     ]
#// );
#//
#// $bind->withTray($on); # can change later
#// $sz = $bind->getTraySize(); # 0 if  either no tray or tray is empty
#// $tray = $bind->swapTray(); # undef if no tray or empty, error if a mix of units in the tray
#// $bind->callTray(); # can handle a mix of units in the tray
#//
#// $fnr->push($bind);
#// $fnr->pop($bind);
#// $fnr->pop();
#// {
#//     $auto = AutoFnBind->new($fnr => $bind, ...);
#//     $unit->call(...);
#// }
#// $unit->callBound( # pushes all the bindings, does the call, pops
#//     $rowop, # or $tray, or [ @rowops ]
#//     $fnr => $bind, ...
#// );
#// Create a binding on the fly and call with it:
#// FnBinding::call( # create and push/call/pop right away
#//     name => "bind1", # used for diagnostics and the names of direct Perl labels
#//     on => $fnr, # determines the type of return
#//     unit => $unit, # needed only for the direct Perl code in labels or for auto-creation of rowops
#//     clearLabels => 1, # default is 0, affects only $labels, the ones created from subs are always cleared
#//     delayed => 1, # default is 0, causes the data to be collected in a tray and then executed
#//     labels => [
#//         "name" => $label,
#//         "name" => sub { ... }, # will directly create a Perl label
#//     ]
#//     rowop => $rowop, # what to call can be a rowop
#//     tray => $tray, # or a tray
#//     rowops => \@rowops, # or an array of rowops
#//     code => \$code, # or a procedural function to call
#// );
#//     
#// 

void
DESTROY(WrapFnBinding *self)
	CODE:
		// warn("FnBinding destroyed!");
		delete self;

#// check whether both refs point to the same object
int
same(WrapFnBinding *self, WrapFnBinding *other)
	CODE:
		clearErrMsg();
		FnBinding *f = self->get();
		FnBinding *of = other->get();
		RETVAL = (f == of);
	OUTPUT:
		RETVAL

#// Args are the option pairs. The options are:
#//
#// XXX describe options, from the sample above
WrapFnBinding *
new(char *CLASS, ...)
	CODE:
		static char funcName[] =  "Triceps::FnBinding::new";
		Autoref<FnBinding> fbind;
		clearErrMsg();
		try {
			clearErrMsg();
			Unit *u = NULL;
			AV *labels = NULL;
			string name;
			FnReturn *fnr = NULL;
			bool wtray = false;
			bool clearLabels = false;

			if (items % 2 != 1) {
				throw Exception("Usage: Triceps::FnBinding::new(CLASS, optionName, optionValue, ...), option names and values must go in pairs", false);
			}
			for (int i = 1; i < items; i += 2) {
				const char *optname = (const char *)SvPV_nolen(ST(i));
				SV *arg = ST(i+1);
				if (!strcmp(optname, "unit")) {
					u = TRICEPS_GET_WRAP(Unit, arg, "%s: option '%s'", funcName, optname)->get();
				} else if (!strcmp(optname, "name")) {
					GetSvString(name, arg, "%s: option '%s'", funcName, optname);
				} else if (!strcmp(optname, "on")) {
					fnr = TRICEPS_GET_WRAP(FnReturn, arg, "%s: option '%s'", funcName, optname)->get();
				} else if (!strcmp(optname, "labels")) {
					labels = GetSvArray(arg, "%s: option '%s'", funcName, optname);
				} else if (!strcmp(optname, "withTray")) {
					wtray = (SvIV(arg) != 0);
				} else if (!strcmp(optname, "clearLabels")) {
					clearLabels = (SvIV(arg) != 0);
				} else {
					throw Exception(strprintf("%s: unknown option '%s'", funcName, optname), false);
				}
			}

			if (name.empty())
				throw Exception(strprintf("%s: missing or empty mandatory option 'name'", funcName), false);
			if (fnr == NULL)
				throw Exception(strprintf("%s: missing mandatory option 'on'", funcName), false);
			if (labels == NULL)
				throw Exception(strprintf("%s: missing mandatory option 'labels'", funcName), false);

			// no exception may happen after makeBinding()
			fbind = makeBinding(funcName, name, u, fnr, labels, clearLabels);
			fbind->withTray(wtray);
		} TRICEPS_CATCH_CROAK;

		RETVAL = new WrapFnBinding(fbind);
	OUTPUT:
		RETVAL

#// Args are the option pairs. The options are:
#//
#// XXX describe options, from the sample above
#// Always returns 1.
int
call(...)
	CODE:
		static char funcName[] =  "Triceps::FnBinding::call";
		clearErrMsg();
		try {
			clearErrMsg();
			int len, i;
			Unit *u = NULL;
			AV *labels = NULL;
			string name;
			FnReturn *fnr = NULL;
			Rowop *rop = NULL;
			Tray *tray = NULL;
			AV *roparray = NULL; // array of rowops
			Autoref<PerlCallback> code = NULL;
			bool clearLabels = false;
			bool delayed = false;

			if (items % 2 != 0) {
				throw Exception::f("Usage: %s(optionName, optionValue, ...), option names and values must go in pairs", funcName);
			}
			for (int i = 0; i < items; i += 2) {
				const char *optname = (const char *)SvPV_nolen(ST(i));
				SV *arg = ST(i+1);
				if (!strcmp(optname, "unit")) {
					u = TRICEPS_GET_WRAP(Unit, arg, "%s: option '%s'", funcName, optname)->get();
				} else if (!strcmp(optname, "name")) {
					GetSvString(name, arg, "%s: option '%s'", funcName, optname);
				} else if (!strcmp(optname, "on")) {
					fnr = TRICEPS_GET_WRAP(FnReturn, arg, "%s: option '%s'", funcName, optname)->get();
				} else if (!strcmp(optname, "labels")) {
					labels = GetSvArray(arg, "%s: option '%s'", funcName, optname);
				} else if (!strcmp(optname, "rowop")) {
					rop = TRICEPS_GET_WRAP(Rowop, arg, "%s: option '%s'", funcName, optname)->get();
				} else if (!strcmp(optname, "tray")) {
					tray = TRICEPS_GET_WRAP(Tray, arg, "%s: option '%s'", funcName, optname)->get();
				} else if (!strcmp(optname, "rowops")) {
					roparray = GetSvArray(arg, "%s: option '%s'", funcName, optname);
				} else if (!strcmp(optname, "code")) {
					code = GetSvCall(arg, "%s: option '%s'", funcName, optname);
				} else if (!strcmp(optname, "clearLabels")) {
					clearLabels = (SvIV(arg) != 0);
				} else if (!strcmp(optname, "delayed")) {
					delayed = (SvIV(arg) != 0);
				} else {
					throw Exception(strprintf("%s: unknown option '%s'", funcName, optname), false);
				}
			}

			if (u == NULL)
				throw Exception(strprintf("%s: missing mandatory option 'unit'", funcName), false);
			if (name.empty())
				throw Exception(strprintf("%s: missing or empty mandatory option 'name'", funcName), false);
			if (fnr == NULL)
				throw Exception(strprintf("%s: missing mandatory option 'on'", funcName), false);
			if (labels == NULL)
				throw Exception(strprintf("%s: missing mandatory option 'labels'", funcName), false);

			// the mutually exclusive ways to specify a rowop
			int rowop_spec = 0;
			if (rop != NULL) rowop_spec++;
			if (tray != NULL) rowop_spec++;
			if (roparray != NULL) rowop_spec++;
			if (!code.isNull()) rowop_spec++;

			if (rowop_spec != 1)
				throw Exception::f("%s: exactly 1 of options 'rowop', 'tray', 'rowops', 'code' must be specified, got %d of them.",
					funcName, rowop_spec);

			// create and set up the binding
			Autoref<FnBinding> fbind = makeBinding(funcName, name, u, fnr, labels, clearLabels);
			fbind->withTray(delayed);
			Autoref<AutoFnBind> ab = new AutoFnBind;
			ab->add(fnr, fbind);

			// call the labels
			if (roparray != NULL) {
				int len = av_len(roparray)+1; // av_len returns the index of last element
				for (int i = 0; i < len; i++) {
					SV *svop = *av_fetch(roparray, i, 0);
					u->call(TRICEPS_GET_WRAP(Rowop, svop, "%s: element %d of the option 'rowops' array", funcName, i)->get()); // not i+1 by design
				}
			} else if (rop) {
				u->call(rop);
			} else if (tray) {
				u->callTray(tray);
			} else if (!code.isNull()) {
				PerlCallbackStartCall(code);
				PerlCallbackDoCall(code);
				callbackSuccessOrThrow("Error detected in %s option 'code'", funcName);
			}

			// The bindings get popped. If the call above throws an exception, the
			// execution won't get here but it's not a problem: ab will be cleared
			// on leaving the block anyway. The only thing this code does is a nicer
			// reporting of popping order errors. But if there was another error
			// that caused a throw, the popping order errors become unimportant
			// and will be ignored.
			try {
				ab->clear();
			} catch(Exception e) {
				throw Exception::f(e, "%s: error on popping the bindings:", funcName);
			}

			if (delayed)
				fbind->callTray(); // after the bindings are popped, to avoid the possible loops
		} TRICEPS_CATCH_CROAK;

		RETVAL = 1;
	OUTPUT:
		RETVAL

char *
getName(WrapFnBinding *self)
	CODE:
		clearErrMsg();
		RETVAL = (char *)self->get()->getName().c_str();
	OUTPUT:
		RETVAL

#// returns whether previously was with tray
#// The optional argument: 
#//    int on - enables or disables the tray
int
withTray(WrapFnBinding *self, ...)
	CODE:
		clearErrMsg();
		if (items != 1 && items != 2)
		   Perl_croak(aTHX_ "Usage: Triceps::FnBinding::withTray(self, [on])");
		FnBinding *bind = self->get();
		RETVAL = (bind->getTray() != NULL);
		if (items == 2) {
			IV on = SvIV(ST(1));
			bind->withTray((on != 0));
		}
	OUTPUT:
		RETVAL

#// always returns 1;
#// handles properly a mix of units
int
callTray(WrapFnBinding *self)
	CODE:
		clearErrMsg();
		try {
			self->get()->callTray();
		} TRICEPS_CATCH_CROAK;
		RETVAL = 1;
	OUTPUT:
		RETVAL

#// with no tray, returns 0
IV
traySize(WrapFnBinding *self)
	CODE:
		clearErrMsg();
		Tray *tray = self->get()->getTray();
		RETVAL = (tray == NULL)? 0 : tray->size();
	OUTPUT:
		RETVAL

#// returns 1 if tre tray is empty or not present, 0 if not
IV
trayEmpty(WrapFnBinding *self)
	CODE:
		clearErrMsg();
		Tray *tray = self->get()->getTray();
		RETVAL = (tray == NULL || tray->size() == 0)? 1 : 0;
	OUTPUT:
		RETVAL

#// no tray or an empty tray returns an undef;
#// a mix of units in the labels in the tray is an error
WrapTray *
swapTray(WrapFnBinding *self)
	CODE:
		// for casting of return value
		static char CLASS[] = "Triceps::Tray";
		static char funcName[] =  "Triceps::FnBinding::swapTray";
		clearErrMsg();
		Unit *u = NULL;

		{ // first check the cheap way
			Tray *t = self->get()->getTray();
			if (t == NULL || t->empty())
				XSRETURN_UNDEF; // not a croak!
		}

		Autoref<Tray> ttret;
		try {
			Autoref<Tray> tt = self->get()->swapTray();
			const Label *lb;
			lb = (*tt)[0]->getLabel();
			u = lb->getUnitPtr();
			if (u == NULL)
				throw Exception::f("%s: tray contains a rowop for cleared label '%s'.", funcName, lb->getName().c_str());
			int n = tt->size();
			for (int i = 1; i < n; i++) {
				lb = (*tt)[i]->getLabel();
				Unit *u2 = lb->getUnitPtr();
				if (u2 == NULL)
					throw Exception::f("%s: tray contains a rowop for cleared label '%s'.", funcName, lb->getName().c_str());
				if (u2 != u)
					throw Exception::f("%s: tray contains a mix of rowops for units '%s' and '%s'.", 
						funcName, u->getName().c_str(), u2->getName().c_str());
			}
			ttret = tt; // no exceptions after this
		} TRICEPS_CATCH_CROAK;
		RETVAL = new WrapTray(u, ttret);
	OUTPUT:
		RETVAL

#// Comparison of the underlying RowSetTypes.
int
equals(WrapFnBinding *self, SV *other)
	CODE:
		static char funcName[] =  "Triceps::FnBinding::equals";
		clearErrMsg();
		WrapFnReturn *wret;
		WrapFnBinding *wbind;
		try {
			TRICEPS_GET_WRAP2(FnReturn, wret, FnBinding, wbind, other, "%s: argument", funcName);
		} TRICEPS_CATCH_CROAK;
		if (wret)
			RETVAL = self->get()->equals(wret->get());
		else
			RETVAL = self->get()->equals(wbind->get());
	OUTPUT:
		RETVAL

int
match(WrapFnBinding *self, SV *other)
	CODE:
		static char funcName[] =  "Triceps::FnBinding::match";
		clearErrMsg();
		WrapFnReturn *wret;
		WrapFnBinding *wbind;
		try {
			TRICEPS_GET_WRAP2(FnReturn, wret, FnBinding, wbind, other, "%s: argument", funcName);
		} TRICEPS_CATCH_CROAK;
		if (wret)
			RETVAL = self->get()->match(wret->get());
		else
			RETVAL = self->get()->match(wbind->get());
	OUTPUT:
		RETVAL

#// number of labels in the binding type (that can be defined, not that are actually
#// defined in this binding)
int 
size(WrapFnBinding *self)
	CODE:
		clearErrMsg();
		RETVAL = self->get()->size();
	OUTPUT:
		RETVAL

#// get the names of the labels (not of labels themselves but if logical names in binding);
#// all thos that could be defined
SV *
getLabelNames(WrapFnBinding *self)
	PPCODE:
		clearErrMsg();
		FnBinding *obj = self->get();

		const RowSetType::NameVec &names = obj->getLabelNames();
		int nf = names.size();
		for (int i = 0; i < nf; i++) {
			XPUSHs(sv_2mortal(newSVpvn(names[i].c_str(), names[i].size())));
		}

#// like getLabelNames() but skip those that are not define din the binding
SV *
getDefinedLabelNames(WrapFnBinding *self)
	PPCODE:
		clearErrMsg();
		FnBinding *obj = self->get();

		const RowSetType::NameVec &names = obj->getLabelNames();
		int nf = names.size();
		for (int i = 0; i < nf; i++) {
			if (obj->getLabel(i) != NULL)
				XPUSHs(sv_2mortal(newSVpvn(names[i].c_str(), names[i].size())));
		}

#// get the actual labels;
#// when some label is not defined, its value will be undef
SV *
getLabels(WrapFnBinding *self)
	PPCODE:
		// for casting of return valus
		static char CLASS[] = "Triceps::Label";
		clearErrMsg();
		FnBinding *obj = self->get();

		const FnBinding::LabelVec &labels = obj->getLabels();
		int nf = labels.size();
		for (int i = 0; i < nf; i++) {
			Label *lb = labels[i];
			if (lb == NULL) {
				XPUSHs(&PL_sv_undef);
			} else {
				SV *sub = newSV(0);
				sv_setref_pv( sub, CLASS, (void*)(new WrapLabel(lb)) );
				XPUSHs(sv_2mortal(sub));
			}
		}

#// get the pairs of (name1, label1, ..., nameN, labelN) in the correct order,
#// and also suitable for the assignment to a hash;
#// when some label is not defined, its value will be undef
SV *
getLabelHash(WrapFnBinding *self)
	PPCODE:
		// for casting of return valus
		static char CLASS[] = "Triceps::Label";
		clearErrMsg();
		FnBinding *obj = self->get();

		const FnBinding::LabelVec &labels = obj->getLabels();
		int nf = labels.size();
		for (int i = 0; i < nf; i++) {
			const string &name = *obj->getLabelName(i);
			XPUSHs(sv_2mortal(newSVpvn(name.c_str(), name.size())));
			Label *lb = labels[i];
			if (lb == NULL) {
				XPUSHs(&PL_sv_undef);
			} else {
				SV *sub = newSV(0);
				sv_setref_pv( sub, CLASS, (void*)(new WrapLabel(lb)) );
				XPUSHs(sv_2mortal(sub));
			}
		}

#// get the pairs of (name1, rt1, ..., nameN, rtN) in the correct order,
#// and also suitable for the assignment to a hash
SV *
getRowTypeHash(WrapFnBinding *self)
	PPCODE:
		// for casting of return valus
		static char CLASS[] = "Triceps::RowType";
		clearErrMsg();
		FnBinding *obj = self->get();

		const RowSetType::RowTypeVec &rts = obj->getRowTypes();
		int nf = rts.size();
		for (int i = 0; i < nf; i++) {
			const string &name = *obj->getLabelName(i);
			XPUSHs(sv_2mortal(newSVpvn(name.c_str(), name.size())));
			SV *sub = newSV(0);
			sv_setref_pv( sub, CLASS, (void*)(new WrapRowType(rts[i])) );
			XPUSHs(sv_2mortal(sub));
		}

#// get the mapping of the label names to indexes
SV *
getLabelMapping(WrapFnBinding *self)
	PPCODE:
		clearErrMsg();
		FnBinding *obj = self->get();

		const RowSetType::NameVec &names = obj->getLabelNames();
		int nf = names.size();
		for (int i = 0; i < nf; i++) {
			XPUSHs(sv_2mortal(newSVpvn(names[i].c_str(), names[i].size())));
			XPUSHs(sv_2mortal(newSViv(i)));
		}

#// Get a label by name. Confesses on the unknown names.
#// Returns undef on undefined labels for known names.
#// Would it be better to confess on undefined labels too?
WrapLabel *
getLabel(WrapFnBinding *self, char *name)
	CODE:
		// for casting of return valus
		static char CLASS[] = "Triceps::Label";
		clearErrMsg();
		FnBinding *obj = self->get();
		int idx = obj->findLabel(name);
		try {
			if (idx < 0)
				throw Exception::f("Triceps::FnBinding::getLabel: unknown label name '%s'.", name);
		} TRICEPS_CATCH_CROAK;
		Label *lb = obj->getLabel(idx);
		if (lb == NULL)
			XSRETURN_UNDEF; // properly return an undef
		RETVAL = new WrapLabel(lb);
	OUTPUT:
		RETVAL

#// Get a label by index. Confesses on the indexes out of range.
#// Returns undef on undefined labels for known names.
#// Would it be better to confess on undefined labels too?
WrapLabel *
getLabelAt(WrapFnBinding *self, int idx)
	CODE:
		// for casting of return valus
		static char CLASS[] = "Triceps::Label";
		clearErrMsg();
		FnBinding *obj = self->get();
		try {
			if (idx < 0 || idx >= obj->size())
				throw Exception::f("Triceps::FnBinding::getLabelAt: bad index %d, valid range is 0..%d.", idx, obj->size()-1);
		} TRICEPS_CATCH_CROAK;
		Label *lb = obj->getLabel(idx);
		if (lb == NULL)
			XSRETURN_UNDEF; // properly return an undef
		RETVAL = new WrapLabel(lb);
	OUTPUT:
		RETVAL

#// Translate a label name to index. Confesses on the unknown names
int
findLabel(WrapFnBinding *self, char *name)
	CODE:
		clearErrMsg();
		FnBinding *obj = self->get();
		RETVAL = obj->findLabel(name);
		try {
			if (RETVAL < 0)
				throw Exception::f("Triceps::FnBinding::findLabel: unknown label name '%s'.", name);
		} TRICEPS_CATCH_CROAK;
	OUTPUT:
		RETVAL
