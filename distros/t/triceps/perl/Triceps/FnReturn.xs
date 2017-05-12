//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
// The wrapper for FnReturn.

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "TricepsPerl.h"
#include "TricepsOpt.h"
#include "PerlCallback.h"

// A streaming function context that executes Perl code.
class PerlFnContext: public FnContext
{
public:
	PerlFnContext(Onceref<PerlCallback> cbPush, Onceref<PerlCallback> cbPop) :
		cbPush_(cbPush),
		cbPop_(cbPop)
	{ }

	// the callbacks are public and can be modified later
	Autoref<PerlCallback> cbPush_, cbPop_;

protected:
	// from FnContext
	virtual void onPush(const FnReturn *fret);
	virtual void onPop(const FnReturn *fret);

	// the common underlying implementation
	void call(const FnReturn *fret, PerlCallback *cb, const char *which);
};

void PerlFnContext::onPush(const FnReturn *fret)
{
	call(fret, cbPush_, "onPush");
}
	
void PerlFnContext::onPop(const FnReturn *fret)
{
	call(fret, cbPop_, "onPop");
}
	

void PerlFnContext::call(const FnReturn *fret, PerlCallback *cb, const char *which)
{
	if (cb == NULL)
		return;

	dSP;

	WrapFnReturn *wret = new WrapFnReturn(const_cast<FnReturn *>(fret));
	SV *svret = newSV(0);
	sv_setref_pv(svret, "Triceps::FnReturn", (void *)wret);

	PerlCallbackStartCall(cb);

	XPUSHs(svret);

	PerlCallbackDoCall(cb);

	// this calls the DELETE methods on wrappers
	SvREFCNT_dec(svret);

	callbackSuccessOrThrow("Detected in the unit '%s' function return '%s' %s handler.",
		fret->getUnitName().c_str(), fret->getName().c_str(), which);
}

MODULE = Triceps::FnReturn		PACKAGE = Triceps::FnReturn
###################################################################################

int
CLONE_SKIP(...)
	CODE:
		RETVAL = 1;
	OUTPUT:
		RETVAL

void
DESTROY(WrapFnReturn *self)
	CODE:
		// warn("FnReturn destroyed!");
		delete self;

#// check whether both refs point to the same object
int
same(WrapFnReturn *self, WrapFnReturn *other)
	CODE:
		clearErrMsg();
		FnReturn *f = self->get();
		FnReturn *of = other->get();
		RETVAL = (f == of);
	OUTPUT:
		RETVAL

#// Args are the option pairs. The options are:
#//
#// name => $name
#// The name of the object.
#//
#// unit => $unit
#// Defines the unit where this FnReturn belongs. If at least one of the labels in
#// this object (see option "labels") is built by chaining from another label,
#// the unit can be implicitly taken from there, and the option "unit" becomes
#// optional. All the labels must belong to the same unit.
#//
#// labels => [ 
#//   name => $rowType,
#//   name => $fromLabel,
#// ]
#// Defines the labels of this return in a referenced array. The array contains
#// the pairs of (label_name, label_definition). The definition may be either
#// a RowType, and then a label of this row type will be created, or a Label,
#// and then a label of the same row type will be created and chained from that
#// original label. The created label objects can be later found, and used
#// like normal labels, by chaining them or sending rowops to them (but
#// chaining _from_ them is probably not the best idea, although it works anyway).
#// At least one definition pair must be present.
#//
#// onPush => $code
#// onPush => [$code, @args]
#// Defines a function and possibly arguments to be executed when a new 
#// FnBinding is pushed onto this return. The function is called:
#//   &$code($thisFnReturn, @args)
#//
#// onPop => $code
#// onPop => [$code, @args]
#// Defines a function and possibly arguments to be executed when a 
#// FnBinding is popped from this return. The function is called:
#//   &$code($thisFnReturn, @args)
#//
WrapFnReturn *
new(char *CLASS, ...)
	CODE:
		static char funcName[] =  "Triceps::FnReturn::new";
		Autoref<FnReturn> fretret;
		clearErrMsg();
		try {
			int len, i;
			Unit *u = NULL;
			AV *labels = NULL;
			string name;
			Autoref<PerlCallback> onPush, onPop;
			bool chainFront = true;

			if (items % 2 != 1) {
				throw Exception("Usage: Triceps::FnReturn::new(CLASS, optionName, optionValue, ...), option names and values must go in pairs", false);
			}
			for (int i = 1; i < items; i += 2) {
				const char *optname = (const char *)SvPV_nolen(ST(i));
				SV *arg = ST(i+1);
				if (!strcmp(optname, "unit")) {
					u = TRICEPS_GET_WRAP(Unit, arg, "%s: option '%s'", funcName, optname)->get();
				} else if (!strcmp(optname, "name")) {
					GetSvString(name, arg, "%s: option '%s'", funcName, optname);
				} else if (!strcmp(optname, "labels")) {
					labels = GetSvArray(arg, "%s: option '%s'", funcName, optname);
				} else if (!strcmp(optname, "onPush")) {
					onPush = GetSvCall(arg, "%s: option '%s'", funcName, optname);
				} else if (!strcmp(optname, "onPop")) {
					onPop = GetSvCall(arg, "%s: option '%s'", funcName, optname);
				} else if (!strcmp(optname, "chainFront")) {
					chainFront = SvTRUE(arg);
				} else {
					throw Exception(strprintf("%s: unknown option '%s'", funcName, optname), false);
				}
			}

			// parse and do the basic checks of the labels
			if (labels == NULL)
				throw Exception(strprintf("%s: missing mandatory option 'labels'", funcName), false);
			checkLabelList(funcName, "labels", u, labels);

			if (u == NULL)
				throw Exception(strprintf("%s: the unit can not be auto-deduced, must use an explicit option 'unit'", funcName), false);
			if (name.empty())
				throw Exception(strprintf("%s: must specify a non-empty name with option 'name'", funcName), false);

			// now finally start building the object
			Autoref<FnReturn> fret = new FnReturn(u, name);

			addFnReturnLabels(funcName, "labels", u, labels, chainFront, fret);

			if (!onPush.isNull() || !onPop.isNull()) {
				fret->setContext(new PerlFnContext(onPush, onPop));
			}

			try {
				initializeOrThrow(fret);
			} catch (Exception e) {
				throw Exception(e, strprintf("%s: invalid arguments:", funcName));
			}

			fretret = fret; // no exceptions after this
		} TRICEPS_CATCH_CROAK;

		RETVAL = new WrapFnReturn(fretret);
	OUTPUT:
		RETVAL


#// Push the binding onto a return.
void 
push(WrapFnReturn *self, WrapFnBinding *arg)
	CODE:
		static char funcName[] =  "Triceps::FnReturn::push";
		clearErrMsg();
		try {
			FnReturn *ret = self->get();
			FnBinding *bind = arg->get();
			try {
				ret->push(bind);
			} catch (Exception e) {
				throw Exception(e, "Triceps::FnReturn::push: invalid arguments:");
			}
		} TRICEPS_CATCH_CROAK;

#// Pop the binding from a return. If the binding argument is specfied,
#// this will assert that it's the binding being popped.
void 
pop(WrapFnReturn *self, ...)
	CODE:
		static char funcName[] =  "Triceps::FnReturn::pop";
		clearErrMsg();
		try {
			if (items != 1 && items != 2)
				throw Exception(strprintf("Usage: %s(self, [binding]) does not allow more arguments", funcName), false);

			FnBinding *fbind;

			if (items == 2)
				fbind = TRICEPS_GET_WRAP(FnBinding, ST(1), "%s: argument", funcName)->get();

			try {
				if (items == 1) {
					self->get()->pop();
				} else {
					self->get()->pop(fbind);
				}
			} catch (Exception e) {
				throw Exception(e, strprintf("%s: invalid arguments:", funcName));
			}
		} TRICEPS_CATCH_CROAK;

char *
getName(WrapFnReturn *self)
	CODE:
		clearErrMsg();
		RETVAL = (char *)self->get()->getName().c_str();
	OUTPUT:
		RETVAL

#// Get the stack size.
int 
bindingStackSize(WrapFnReturn *self)
	CODE:
		clearErrMsg();
		RETVAL = self->get()->bindingStackSize();
	OUTPUT:
		RETVAL

#// Get the stack contents. Used mostly for diagnostics.
#// Returns an array of FnBindings with the top of stack on the right.
SV *
bindingStack(WrapFnReturn *self)
	PPCODE:
		clearErrMsg();
		const FnReturn::BindingVec &stack = self->get()->bindingStack();
		
		// for casting of return value
		static char CLASS[] = "Triceps::FnBinding";

		int nf = stack.size();
		for (int i = 0;  i < nf; i++) {
			SV *bindv = sv_newmortal();
			sv_setref_pv( bindv, CLASS, (void*)(new WrapFnBinding(stack[i])) );
			XPUSHs(bindv);
		}

#// Get the names of bindings in the contents. Useful for printing the contents.
#// Returns an array of strings with the top of stack on the right.
SV *
bindingStackNames(WrapFnReturn *self)
	PPCODE:
		clearErrMsg();
		const FnReturn::BindingVec &stack = self->get()->bindingStack();
		
		// for casting of return value
		static char CLASS[] = "Triceps::FnBinding";

		int nf = stack.size();
		for (int i = 0;  i < nf; i++) {
			const string &name = stack[i]->getName();
			XPUSHs(sv_2mortal(newSVpvn(name.c_str(), name.size())));
		}

#// Comparison of the underlying RowSetTypes.
int
equals(WrapFnReturn *self, SV *other)
	CODE:
		static char funcName[] =  "Triceps::FnReturn::equals";
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
match(WrapFnReturn *self, SV *other)
	CODE:
		static char funcName[] =  "Triceps::FnReturn::match";
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

#// number of labels in the return
int 
size(WrapFnReturn *self)
	CODE:
		clearErrMsg();
		RETVAL = self->get()->size();
	OUTPUT:
		RETVAL

#// get the names of the labels (not of labels themselves but of logical names in return)
SV *
getLabelNames(WrapFnReturn *self)
	PPCODE:
		clearErrMsg();
		FnReturn *obj = self->get();

		const RowSetType::NameVec &names = obj->getLabelNames();
		int nf = names.size();
		for (int i = 0; i < nf; i++) {
			XPUSHs(sv_2mortal(newSVpvn(names[i].c_str(), names[i].size())));
		}

#// get the actual labels (NOT the ones used as the constructor
#// arguments, these are used for chaining from)
SV *
getLabels(WrapFnReturn *self)
	PPCODE:
		// for casting of return valus
		static char CLASS[] = "Triceps::Label";
		clearErrMsg();
		FnReturn *obj = self->get();

		const FnReturn::ReturnVec &labels = obj->getLabels();
		int nf = labels.size();
		for (int i = 0; i < nf; i++) {
			SV *sub = newSV(0);
			sv_setref_pv( sub, CLASS, (void*)(new WrapLabel(labels[i])) );
			XPUSHs(sv_2mortal(sub));
		}

#// get the pairs of (name1, label1, ..., nameN, labelN) in the correct order,
#// and also suitable for the assignment to a hash
SV *
getLabelHash(WrapFnReturn *self)
	PPCODE:
		// for casting of return valus
		static char CLASS[] = "Triceps::Label";
		clearErrMsg();
		FnReturn *obj = self->get();

		const FnReturn::ReturnVec &labels = obj->getLabels();
		int nf = labels.size();
		for (int i = 0; i < nf; i++) {
			const string &name = *obj->getLabelName(i);
			XPUSHs(sv_2mortal(newSVpvn(name.c_str(), name.size())));
			SV *sub = newSV(0);
			sv_setref_pv( sub, CLASS, (void*)(new WrapLabel(labels[i])) );
			XPUSHs(sv_2mortal(sub));
		}

#// get the pairs of (name1, rt1, ..., nameN, rtN) in the correct order,
#// and also suitable for the assignment to a hash
SV *
getRowTypeHash(WrapFnReturn *self)
	PPCODE:
		// for casting of return valus
		static char CLASS[] = "Triceps::RowType";
		clearErrMsg();
		FnReturn *obj = self->get();

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
getLabelMapping(WrapFnReturn *self)
	PPCODE:
		clearErrMsg();
		FnReturn *obj = self->get();

		const RowSetType::NameVec &names = obj->getLabelNames();
		int nf = names.size();
		for (int i = 0; i < nf; i++) {
			XPUSHs(sv_2mortal(newSVpvn(names[i].c_str(), names[i].size())));
			XPUSHs(sv_2mortal(newSViv(i)));
		}

#// Get a label by name. Confesses on the unknown names.
WrapLabel *
getLabel(WrapFnReturn *self, char *name)
	CODE:
		// for casting of return valus
		static char CLASS[] = "Triceps::Label";
		clearErrMsg();
		RETVAL = NULL;
		try {
			FnReturn *obj = self->get();
			Label *lb = obj->getLabel(name);
			if (lb == NULL)
				throw Exception::f("Triceps::FnReturn::getLabel: unknown label name '%s'.", name);
			RETVAL = new WrapLabel(lb);
		} TRICEPS_CATCH_CROAK;
	OUTPUT:
		RETVAL

#// Get a label by index. Confesses on the indexes out of range.
WrapLabel *
getLabelAt(WrapFnReturn *self, int idx)
	CODE:
		// for casting of return valus
		static char CLASS[] = "Triceps::Label";
		clearErrMsg();
		RETVAL = NULL;
		try {
			FnReturn *obj = self->get();
			Label *lb = obj->getLabel(idx);
			if (lb == NULL)
				throw Exception::f("Triceps::FnReturn::getLabelAt: bad index %d, valid range is 0..%d.", idx, obj->size()-1);
			RETVAL = new WrapLabel(lb);
		} TRICEPS_CATCH_CROAK;
	OUTPUT:
		RETVAL

#// Translate a label name to index. Confesses on the unknown names
int
findLabel(WrapFnReturn *self, char *name)
	CODE:
		clearErrMsg();
		FnReturn *obj = self->get();
		RETVAL = obj->findLabel(name);
		try {
			if (RETVAL < 0)
				throw Exception::f("Triceps::FnReturn::findLabel: unknown label name '%s'.", name);
		} TRICEPS_CATCH_CROAK;
	OUTPUT:
		RETVAL

int 
isFaceted(WrapFnReturn *self)
	CODE:
		clearErrMsg();
		RETVAL = self->get()->isFaceted();
	OUTPUT:
		RETVAL

