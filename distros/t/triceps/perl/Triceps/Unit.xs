//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
// The wrapper for Unit.

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "TricepsPerl.h"
#include "PerlCallback.h"
#include "sched/FnReturn.h"

MODULE = Triceps::Unit		PACKAGE = Triceps::Unit
###################################################################################

int
CLONE_SKIP(...)
	CODE:
		RETVAL = 1;
	OUTPUT:
		RETVAL

void
DESTROY(WrapUnit *self)
	CODE:
		Unit *unit = self->get();
		// warn("Unit %s %p wrap %p destroyed!", unit->getName().c_str(), unit, self);
		delete self;


WrapUnit *
Triceps::Unit::new(char *name)
	CODE:
		clearErrMsg();

		Autoref<Unit> unit = new Unit(name);
		WrapUnit *wu = new WrapUnit(unit);
		// warn("Created unit %s %p wrap %p", name, unit.get(), wu);
		RETVAL = wu;
	OUTPUT:
		RETVAL

#// returns true on success, undef on error;
#// the argument array can be a mix of rowops and trays;
#// on error some of the records may end up enqueued
int
schedule(WrapUnit *self, ...)
	CODE:
		try {
			static char funcName[] =  "Triceps::Unit::schedule";
			clearErrMsg();
			Unit *u = self->get();
			for (int i = 1; i < items; i++)
				enqueueSv(funcName, u, NULL, Gadget::EM_SCHEDULE, ST(i), i); // may throw
		} TRICEPS_CATCH_CROAK;
		RETVAL = 1;
	OUTPUT:
		RETVAL

#// see comment for schedule
int
fork(WrapUnit *self, ...)
	CODE:
		try {
			static char funcName[] =  "Triceps::Unit::fork";
			clearErrMsg();
			Unit *u = self->get();
			for (int i = 1; i < items; i++)
				enqueueSv(funcName, u, NULL, Gadget::EM_FORK, ST(i), i); // may throw
		} TRICEPS_CATCH_CROAK;
		RETVAL = 1;
	OUTPUT:
		RETVAL

#// see comment for schedule
int
call(WrapUnit *self, ...)
	CODE:
		try {
			static char funcName[] =  "Triceps::Unit::call";
			clearErrMsg();
			Unit *u = self->get();
			for (int i = 1; i < items; i++)
				enqueueSv(funcName, u, NULL, Gadget::EM_CALL, ST(i), i); // may throw
		} TRICEPS_CATCH_CROAK;
		RETVAL = 1;
	OUTPUT:
		RETVAL

#// see comment for schedule
int
enqueue(WrapUnit *self, SV *enqMode, ...)
	CODE:
		try {
			static char funcName[] =  "Triceps::Unit::enqueue";
			clearErrMsg();
			Unit *u = self->get();
			Gadget::EnqMode em = parseEnqMode(funcName, enqMode); // may throw

			for (int i = 2; i < items; i++)
				enqueueSv(funcName, u, NULL, em, ST(i), i); // may throw
		} TRICEPS_CATCH_CROAK;
		RETVAL = 1;
	OUTPUT:
		RETVAL

#// work with marks
void
setMark(WrapUnit *self, WrapFrameMark *wm)
	CODE:
		try {
			static char funcName[] =  "Triceps::Unit::setMark";
			clearErrMsg();
			Unit *u = self->get();
			FrameMark *mark = wm->get();
			u->setMark(mark);
		} TRICEPS_CATCH_CROAK;

#// see comment for schedule
int
loopAt(WrapUnit *self, WrapFrameMark *wm, ...)
	CODE:
		try {
			static char funcName[] =  "Triceps::Unit::loopAt";
			clearErrMsg();
			Unit *u = self->get();
			FrameMark *mark = wm->get();
			Unit *mu = mark->getUnit();
			if (mu != NULL && mu != u) {
				throw Exception( strprintf("%s: mark belongs to a different unit '%s'", funcName, mu->getName().c_str()), false );
			}
			for (int i = 2; i < items; i++)
				enqueueSv(funcName, u, mark, Gadget::EM_FORK, ST(i), i); // may throw
		} TRICEPS_CATCH_CROAK;
		RETVAL = 1;
	OUTPUT:
		RETVAL

void
callNext(WrapUnit *self)
	CODE:
		try {
			clearErrMsg();
			Unit *u = self->get();
			u->callNext();
		} TRICEPS_CATCH_CROAK;

void
drainFrame(WrapUnit *self)
	CODE:
		try {
			clearErrMsg();
			Unit *u = self->get();
			u->drainFrame();
		} TRICEPS_CATCH_CROAK;

int
empty(WrapUnit *self)
	CODE:
		clearErrMsg();
		Unit *u = self->get();
		RETVAL = u->empty();
	OUTPUT:
		RETVAL

int
isFrameEmpty(WrapUnit *self)
	CODE:
		clearErrMsg();
		Unit *u = self->get();
		RETVAL = u->isFrameEmpty();
	OUTPUT:
		RETVAL

int
isInOuterFrame(WrapUnit *self)
	CODE:
		clearErrMsg();
		Unit *u = self->get();
		RETVAL = u->isInOuterFrame();
	OUTPUT:
		RETVAL

#// Work with the streaming functions: call one or more rowops
#// in a scope of pushed function bindings. Same thing as push the
#// bindings, do the calls, pop the bindings.
#//
#// $unit->callBound( # pushes all the bindings, does the call, pops
#//     $rowop, # or $tray, or [ @rowops ]
#//     $fnr => $bind, ...
#// );
#//
#// Always returns 1, unless it confesses on errors.
int
callBound(WrapUnit *self, SV *ops, ...)
	CODE:
		try {
			static char funcName[] =  "Triceps::Unit::callBound";
			clearErrMsg();
			Unit *u = self->get();
			Autoref<AutoFnBind> ab = new AutoFnBind;

			// first push the bindings
			if (items % 2 != 0) {
				throw Exception::f("Usage: %s(self, ops, fnret1 => fnbinding1, ...), returns and bindings must go in pairs", funcName);
			}

			// first push the bindings
			for (int i = 2; i < items; i += 2) {
				FnReturn *ret = TRICEPS_GET_WRAP(FnReturn, ST(i), "%s: argument %d", funcName, i)->get();
				FnBinding *bind = TRICEPS_GET_WRAP(FnBinding, ST(i+1), "%s: argument %d", funcName, i+1)->get();
				try {
					ab->add(ret, bind);
				} catch(Exception e) {
					throw Exception::f(e, "%s: arguments %d, %d:", funcName, i, i+1);
				}
			}

			// now find out what rowops the process
			if (SvROK(ops) && (SvTYPE(SvRV(ops)) == SVt_PVAV)) {
				// an array of rowops
				AV *arops = (AV*)SvRV(ops);
				int len = av_len(arops)+1; // av_len returns the index of last element
				for (int i = 0; i < len; i++) {
					SV *svop = *av_fetch(arops, i, 0);
					u->call(TRICEPS_GET_WRAP(Rowop, svop, "%s: element %d of the rowop array", funcName, i)->get()); // not i+1 by design
				}
			} else {
				WrapRowop *wrop;
				WrapTray *wtray;
				TRICEPS_GET_WRAP2(Rowop, wrop, Tray, wtray, ops, "%s: ops argument", funcName);
				if (wrop) {
					u->call(wrop->get());
				} else {
					u->callTray(wtray->get());
				}
			}

			// the bindings get popped
			try {
				ab->clear();
			} catch(Exception e) {
				throw Exception::f(e, "%s: error on popping the bindings:", funcName);
			}
		} TRICEPS_CATCH_CROAK;
		RETVAL = 1;
	OUTPUT:
		RETVAL

#// check whether both refs point to the same object
int
same(WrapUnit *self, WrapUnit *other)
	CODE:
		clearErrMsg();
		Unit *u = self->get();
		Unit *ou = other->get();
		RETVAL = (u == ou);
	OUTPUT:
		RETVAL

#// operations on unit name
char *
getName(WrapUnit *self)
	CODE:
		clearErrMsg();
		Unit *u = self->get();
		RETVAL = (char *)u->getName().c_str();
	OUTPUT:
		RETVAL

int
getStackDepth(WrapUnit *self)
	CODE:
		clearErrMsg();
		Unit *u = self->get();
		RETVAL = u->getStackDepth();
	OUTPUT:
		RETVAL

void
setMaxStackDepth(WrapUnit *self, int v)
	CODE:
		clearErrMsg();
		Unit *u = self->get();
		u->setMaxStackDepth(v);

int
maxStackDepth(WrapUnit *self)
	CODE:
		clearErrMsg();
		Unit *u = self->get();
		RETVAL = u->maxStackDepth();
	OUTPUT:
		RETVAL

void
setMaxRecursionDepth(WrapUnit *self, int v)
	CODE:
		clearErrMsg();
		Unit *u = self->get();
		u->setMaxRecursionDepth(v);

int
maxRecursionDepth(WrapUnit *self)
	CODE:
		clearErrMsg();
		Unit *u = self->get();
		RETVAL = u->maxRecursionDepth();
	OUTPUT:
		RETVAL

#// get the empty row type
WrapRowType *
getEmptyRowType(WrapUnit *self)
	CODE:
		// for casting of return value
		static char CLASS[] = "Triceps::RowType";
		clearErrMsg();
		Unit *u = self->get();
		RETVAL = new WrapRowType(u->getEmptyRowType());
	OUTPUT:
		RETVAL

#// operations on tracer
WrapUnitTracer *
getTracer(WrapUnit *self)
	CODE:
		clearErrMsg();
		Unit *u = self->get();
		Autoref<Unit::Tracer> tracer = u->getTracer();
		if (tracer.isNull())
			XSRETURN_UNDEF; // not croak!

		// find the class to use for blessing
		char *CLASS = translateUnitTracerSubclass(tracer.get());
		RETVAL = new WrapUnitTracer(tracer);
	OUTPUT:
		RETVAL

#// use SV* for argument because may pass undef
void
setTracer(WrapUnit *self, SV *arg)
	CODE:
		try { do {
			clearErrMsg();
			Unit *u = self->get();
			Unit::Tracer *tracer = NULL;
			if (SvOK(arg)) {
				if( sv_isobject(arg) && (SvTYPE(SvRV(arg)) == SVt_PVMG) ) {
					WrapUnitTracer *twrap = (WrapUnitTracer *)SvIV((SV*)SvRV( arg ));
					if (twrap == 0 || twrap->badMagic()) {
						throw TRICEPS_NS::Exception("Unit::setTracer: tracer has an incorrect magic for WrapUnitTracer", false);
					}
					tracer = twrap->get();
				} else{
					throw TRICEPS_NS::Exception("Unit::setTracer: tracer is not a blessed SV reference to WrapUnitTracer", false);
				}
			} // otherwise leave the tracer as NULL
			u->setTracer(tracer);
		} while(0); } TRICEPS_CATCH_CROAK;

WrapTable *
makeTable(WrapUnit *unit, WrapTableType *wtt, char *name)
	CODE:
		static char funcName[] =  "Triceps::Unit::makeTable";
		// for casting of return value
		static char CLASS[] = "Triceps::Table";
		RETVAL = NULL; // shut up the warning

		try { do {
			clearErrMsg();
			TableType *tbt = wtt->get();

			Autoref<Table> t = tbt->makeTable(unit->get(), name);
			if (t.isNull()) {
				throw Exception::f("%s: table type was not successfully initialized", funcName);
			}
			RETVAL = new WrapTable(t);
		} while(0); } TRICEPS_CATCH_CROAK;
	OUTPUT:
		RETVAL

WrapTray *
makeTray(WrapUnit *self, ...)
	CODE:
		static char funcName[] =  "Triceps::Unit::makeTray";
		// for casting of return value
		static char CLASS[] = "Triceps::Tray";

		clearErrMsg();
		Unit *unit = self->get();

		try { do {
			for (int i = 1; i < items; i++) {
				SV *arg = ST(i);
				if( sv_isobject(arg) && (SvTYPE(SvRV(arg)) == SVt_PVMG) ) {
					WrapRowop *var = (WrapRowop *)SvIV((SV*)SvRV( arg ));
					if (var == 0 || var->badMagic()) {
						throw Exception::f("%s: argument %d has an incorrect magic for Rowop", funcName, i);
					}
					if (var->get()->getLabel()->getUnitPtr() != unit) {
						throw Exception::f("%s: argument %d is a Rowop for label %s from a wrong unit %s", funcName, i,
							var->get()->getLabel()->getName().c_str(), var->get()->getLabel()->getUnitName().c_str());
					}
				} else{
					throw Exception::f("%s: argument %d is not a blessed SV reference to Rowop", funcName, i);
				}
			}
		} while(0); } TRICEPS_CATCH_CROAK;

		Autoref<Tray> tray = new Tray;
		for (int i = 1; i < items; i++) {
			SV *arg = ST(i);
			WrapRowop *var = (WrapRowop *)SvIV((SV*)SvRV( arg ));
			tray->push_back(var->get());
		}
		RETVAL = new WrapTray(unit, tray);
	OUTPUT:
		RETVAL

#// make a label without any executable code (that is useful for chaining)
WrapLabel *
makeDummyLabel(WrapUnit *self, WrapRowType *wrt, char *name)
	CODE:
		static char funcName[] =  "Triceps::Unit::makeDummyLabel";
		// for casting of return value
		static char CLASS[] = "Triceps::Label";

		clearErrMsg();
		Unit *unit = self->get();
		RowType *rt = wrt->get();

		RETVAL = new WrapLabel(new DummyLabel(unit, rt, name));
	OUTPUT:
		RETVAL

#// make a label with executable Perl code
#// @param self - unit where the new label belongs
#// @param wrt - row type for the label
#// @param name - name of the label
#// @param clear - the Perl function reference to be called when the label gets cleared,
#//        may be undef
#// @param exec - the Perl function reference for label execution
#// @param ... - extra args used for both clear and exec callbacks
WrapLabel *
makeLabel(WrapUnit *self, WrapRowType *wrt, char *name, SV *clear, SV *exec, ...)
	CODE:
		// for casting of return value
		static char CLASS[] = "Triceps::Label";
		RETVAL = NULL; // shut up the warning

		try { do {
			clearErrMsg();
			Unit *unit = self->get();
			RowType *rt = wrt->get();

			Onceref<PerlCallback> clr;
			if (!SvOK(clear)) {
				// take the default
				clear = get_sv("Triceps::_DEFAULT_CLEAR_LABEL", 0);
			}
			if (SvOK(clear)) {
				clr = new PerlCallback();
				PerlCallbackInitializeSplit(clr, "Triceps::Unit::makeLabel(clear)", clear, 5, items-5); // may throw
			}

			Onceref<PerlCallback> cb = new PerlCallback();
			PerlCallbackInitialize(cb, "Triceps::Unit::makeLabel(callback)", 4, items-4); // may throw

			RETVAL = new WrapLabel(new PerlLabel(unit, rt, name, clr, cb));
		} while(0); } TRICEPS_CATCH_CROAK;
	OUTPUT:
		RETVAL

#// Make a label that does nothing other than clearing of the argument objects.
#// The row type of this label is always the empty row type.
#// Confesses on errors.
#// @param self - unit where the new label belongs
#// @param name - name of the label
#// @param ... -  args used for clearing with Triceps::clearArgs()
WrapLabel *
makeClearingLabel(WrapUnit *self, char *name, ...)
	CODE:
		static char funcName[] =  "Triceps::Unit::makeClearingLabel";
		// for casting of return value
		static char CLASS[] = "Triceps::Label";
		RETVAL = NULL; // shut up the warning

		try { do {
			clearErrMsg();
			Unit *unit = self->get();
			RowType *rt = unit->getEmptyRowType();

			Onceref<PerlCallback> clr;
			SV *clear = get_sv("Triceps::_DEFAULT_CLEAR_LABEL", 0);

			if (!SvOK(clear)) {
				throw TRICEPS_NS::Exception(strprintf("%s: $Triceps::_DEFAULT_CLEAR_LABEL does not contain a reference to clearArgs function", funcName), false);
			}

			clr = new PerlCallback();
			PerlCallbackInitializeSplit(clr, funcName, clear, 2, items-2); // may throw

			RETVAL = new WrapLabel(new PerlLabel(unit, rt, name, clr, NULL));
		} while(0); } TRICEPS_CATCH_CROAK;
	OUTPUT:
		RETVAL


#// clear the labels, makes the unit non-runnable
void
clearLabels(WrapUnit *self)
	CODE:
		try {
			clearErrMsg();
			Unit *unit = self->get();
			unit->clearLabels();
		} TRICEPS_CATCH_CROAK;

#// make a clearing trigger
#// (once it's destroyed, the unit will get cleared!)
WrapUnitClearingTrigger *
makeClearingTrigger(WrapUnit *self)
	CODE:
		static char funcName[] =  "Triceps::Unit::makeLabel";
		// for casting of return value
		static char CLASS[] = "Triceps::UnitClearingTrigger";

		clearErrMsg();
		Unit *unit = self->get();

		RETVAL = new WrapUnitClearingTrigger(new UnitClearingTrigger(unit));
	OUTPUT:
		RETVAL

MODULE = Triceps::Unit		PACKAGE = Triceps::UnitClearingTrigger
###################################################################################

int
CLONE_SKIP(...)
	CODE:
		RETVAL = 1;
	OUTPUT:
		RETVAL

void
DESTROY(WrapUnitClearingTrigger *self)
	CODE:
		// warn("UnitClearingTrigger destroyed!");
		delete self;

