//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
// The wrapper for AutoDrain varieties.

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "TricepsPerl.h"
#include <app/TrieadOwner.h>
#include <app/AutoDrain.h>

// Makes the shared drain from a 3-way argument.
// Throws an Exception if the argument is not valid.
// @param funcName - calling function name for the error messages
// @param arg - the argument, a string, App or TrieadOwner
// @param wait - flag: right away wait for the drain to complete
static WrapAutoDrain *makeDrainShared(const char *funcName, SV *arg, bool wait)
{
	Autoref<AutoDrain> adret;
	if ( sv_isobject(arg) && (SvTYPE(SvRV(arg)) == SVt_PVMG) ) {
		WrapApp *wa = (WrapApp *)SvIV((SV*)SvRV( arg ));
		WrapTrieadOwner *wto = (WrapTrieadOwner *)wa;
		if (wa != 0 && !wa->badMagic()) {
			adret = new AutoDrainShared(wa->get(), wait);
		} else if (wto != 0 && !wto->badMagic()) {
			adret = new AutoDrainShared(wto->get(), wait);
		} else {
			throw Exception::f("%s: argument has an incorrect magic for App or TrieadOwner", funcName);
		}
	} else if (SvPOK(arg)) {
		STRLEN len;
		char *s = SvPV(arg, len);
		string appname(s, len);
		Autoref<App> app = App::find(appname); // will throw if can't find
		adret = new AutoDrainShared(app, wait);
	} else {
		throw Exception::f("%s: argument is not an App nor TrieadOwner reference nor a string", funcName);
	}
	return new WrapAutoDrain(adret);
}

MODULE = Triceps::AutoDrain		PACKAGE = Triceps::AutoDrain
###################################################################################

int
CLONE_SKIP(...)
	CODE:
		RETVAL = 1;
	OUTPUT:
		RETVAL

void
DESTROY(WrapAutoDrain *self)
	CODE:
		// warn("AutoDrain %p wrap %p destroyed!", self->get(), self);
		delete self;

#// check whether both refs point to the same object
int
same(WrapAutoDrain *self, WrapAutoDrain *other)
	CODE:
		clearErrMsg();
		AutoDrain *a1 = self->get();
		AutoDrain *a2 = other->get();
		RETVAL = (a1 == a2);
	OUTPUT:
		RETVAL

#// Make a new shared drain.
#// @param arg - TrieadOwner object or App object or App name identifying the App to drain
WrapAutoDrain *
makeShared(SV *arg)
	CODE:
		static char funcName[] =  "Triceps::AutoDrain::makeShared";
		static char CLASS[] =  "Triceps::AutoDrain";
		clearErrMsg();
		RETVAL = NULL;
		try { do {
			RETVAL = makeDrainShared(funcName, arg, true);
		} while(0); } TRICEPS_CATCH_CROAK;
	OUTPUT:
		RETVAL

#// Make a new shared drain, request but don't wait.
#// @param arg - TrieadOwner object or App object or App name identifying the App to drain
WrapAutoDrain *
makeSharedNoWait(SV *arg)
	CODE:
		static char funcName[] =  "Triceps::AutoDrain::makeSharedNoWait";
		static char CLASS[] =  "Triceps::AutoDrain";
		clearErrMsg();
		RETVAL = NULL;
		try { do {
			RETVAL = makeDrainShared(funcName, arg, false);
		} while(0); } TRICEPS_CATCH_CROAK;
	OUTPUT:
		RETVAL

#// Make a new Exclusive drain.
#// @param wto - TrieadOwner object to exclude from drain (and it identifies the App too)
WrapAutoDrain *
makeExclusive(WrapTrieadOwner *wto)
	CODE:
		static char funcName[] =  "Triceps::AutoDrain::makeExclusive";
		static char CLASS[] =  "Triceps::AutoDrain";
		clearErrMsg();
		RETVAL = NULL;
		try { do {
			RETVAL = new WrapAutoDrain(new AutoDrainExclusive(wto->get()));
		} while(0); } TRICEPS_CATCH_CROAK;

	OUTPUT:
		RETVAL

#// Make a new Exclusive drain, request but don't wait.
#// @param wto - TrieadOwner object to exclude from drain (and it identifies the App too)
WrapAutoDrain *
makeExclusiveNoWait(WrapTrieadOwner *wto)
	CODE:
		static char funcName[] =  "Triceps::AutoDrain::makeExclusiveNoWait";
		static char CLASS[] =  "Triceps::AutoDrain";
		clearErrMsg();
		RETVAL = NULL;
		try { do {
			RETVAL = new WrapAutoDrain(new AutoDrainExclusive(wto->get(), false));
		} while(0); } TRICEPS_CATCH_CROAK;

	OUTPUT:
		RETVAL

void
wait(WrapAutoDrain *self)
	CODE:
		clearErrMsg();
		try { do {
			self->get()->wait();
		} while(0); } TRICEPS_CATCH_CROAK;
