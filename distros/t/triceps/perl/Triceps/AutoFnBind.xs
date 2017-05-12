//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
// The wrapper for AutoFnBind.

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "TricepsPerl.h"
#include "TricepsOpt.h"

MODULE = Triceps::AutoFnBind		PACKAGE = Triceps::AutoFnBind
###################################################################################

int
CLONE_SKIP(...)
	CODE:
		RETVAL = 1;
	OUTPUT:
		RETVAL

#// This one is tricky because croaking in a DESTROY doesn't work, 
#// so have to do something more horrible.
void
DESTROY(WrapAutoFnBind *self)
	CODE:
		// warn("AutoFnBind destroyed!");
		clearErrMsg();
		try {
			self->get()->clear();
		} catch(Exception e) {
			Erref err;
			err.fAppend(e.getErrors(), "Triceps::AutoFnBind::DESTROY: encountered an FnReturn corruption");
			err->appendMsg(true, "Perl does not allow to die properly in a destructor, so will just exit.");
			warn("%sTo see a full call stack, add an explicit clear() of the AutoFnBind before the end of block starting", err->print().c_str());
			_exit(1);
		}
		delete self;

#// A scoped binding for multiple FnReturns.
#// The FnReturns and FnBindings go in pairs.
#//
#// $ab = AutoFnBind->new($ret1 => $binding1, ...)
WrapAutoFnBind *
new(char *CLASS, ...)
	CODE:
		static char funcName[] =  "Triceps::AutoFnBind::new";
		clearErrMsg();
		Autoref<AutoFnBind> mbret;
		try {
			if (items % 2 != 1) {
				throw Exception("Usage: Triceps::AutoFnBind::new(CLASS, ret1 => binding1, ...), FnReturn and FnBinding objects must go in pairs", false);
			}
			Autoref<AutoFnBind> mb = new AutoFnBind;
			for (int i = 1; i < items; i += 2) {
				FnReturn *ret = TRICEPS_GET_WRAP(FnReturn, ST(i), "%s: argument %d", funcName, i)->get();
				FnBinding *bind = TRICEPS_GET_WRAP(FnBinding, ST(i+1), "%s: argument %d", funcName, i+1)->get();
				
				try {
					mb->add(ret, bind);
				} catch (Exception e) {
					throw Exception(e, strprintf("%s: invalid arguments:", funcName));
				}
			}
			mbret = mb; // no exceptions may happen after this
		} TRICEPS_CATCH_CROAK;

		RETVAL = new WrapAutoFnBind(mbret);
	OUTPUT:
		RETVAL

#// An explicit clearing of the auto-scope, without waiting for it to
#// be destroyed. This allows to confess properly, since Perl ignores
#// any attempts to die in DESTROY().
void
clear(WrapAutoFnBind *self)
	CODE:
		clearErrMsg();
		try {
			try {
				self->get()->clear();
			} catch(Exception e) {
				throw Exception(e, "Triceps::AutoFnBind::clear: encountered an FnReturn corruption");
			}
		} TRICEPS_CATCH_CROAK;

#// check whether both refs point to the same object
int
same(WrapAutoFnBind *self, WrapAutoFnBind *other)
	CODE:
		clearErrMsg();
		AutoFnBind *fb = self->get();
		AutoFnBind *ofb = other->get();
		RETVAL = (fb == ofb);
	OUTPUT:
		RETVAL

