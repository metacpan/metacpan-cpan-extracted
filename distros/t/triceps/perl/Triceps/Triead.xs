//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
// The wrapper for Triead.

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "TricepsPerl.h"
#include "app/Triead.h"

MODULE = Triceps::Triead		PACKAGE = Triceps::Triead
###################################################################################

int
CLONE_SKIP(...)
	CODE:
		RETVAL = 1;
	OUTPUT:
		RETVAL

void
DESTROY(WrapTriead *self)
	CODE:
		// TrieadOwner *to = self->get();
		// warn("TrieadOwner %s %p wrap %p destroyed!", to->get()->getName().c_str(), to, self);
		delete self;

#// The Triead objects don't get constructed from Perl, they can only be
#// extracted from the TrieadOwner or App.

#// check whether both refs point to the same object
int
same(WrapTriead *self, WrapTriead *other)
	CODE:
		clearErrMsg();
		Triead *t1 = self->get();
		Triead *t2 = other->get();
		RETVAL = (t1 == t2);
	OUTPUT:
		RETVAL

char *
getName(WrapTriead *self)
	CODE:
		clearErrMsg();
		Triead *t = self->get();
		RETVAL = (char *)t->getName().c_str();
	OUTPUT:
		RETVAL

char *
fragment(WrapTriead *self)
	CODE:
		clearErrMsg();
		Triead *t = self->get();
		RETVAL = (char *)t->fragment().c_str();
	OUTPUT:
		RETVAL

int
isConstructed(WrapTriead *self)
	CODE:
		clearErrMsg();
		Triead *t = self->get();
		RETVAL = t->isConstructed();
	OUTPUT:
		RETVAL

int
isReady(WrapTriead *self)
	CODE:
		clearErrMsg();
		Triead *t = self->get();
		RETVAL = t->isReady();
	OUTPUT:
		RETVAL

int
isDead(WrapTriead *self)
	CODE:
		clearErrMsg();
		Triead *t = self->get();
		RETVAL = t->isDead();
	OUTPUT:
		RETVAL

int
isInputOnly(WrapTriead *self)
	CODE:
		clearErrMsg();
		Triead *t = self->get();
		RETVAL = t->isInputOnly();
	OUTPUT:
		RETVAL

SV *
exports(WrapTriead *self)
	PPCODE:
		// for casting of return value
		static char CLASS[] = "Triceps::Nexus";
		clearErrMsg();
		Triead *t = self->get();
		Triead::NexusMap m;
		t->exports(m);
		for (Triead::NexusMap::iterator it = m.begin(); it != m.end(); ++it) {
			XPUSHs(sv_2mortal(newSVpvn(it->first.c_str(), it->first.size())));

			SV *sub = newSV(0);
			sv_setref_pv( sub, CLASS, (void*)(new WrapNexus(it->second)) );
			XPUSHs(sv_2mortal(sub));
		}

SV *
imports(WrapTriead *self)
	PPCODE:
		// for casting of return value
		static char CLASS[] = "Triceps::Nexus";
		clearErrMsg();
		Triead *t = self->get();
		Triead::NexusMap m;
		t->imports(m);
		for (Triead::NexusMap::iterator it = m.begin(); it != m.end(); ++it) {
			XPUSHs(sv_2mortal(newSVpvn(it->first.c_str(), it->first.size())));

			SV *sub = newSV(0);
			sv_setref_pv( sub, CLASS, (void*)(new WrapNexus(it->second)) );
			XPUSHs(sv_2mortal(sub));
		}

SV *
readerImports(WrapTriead *self)
	PPCODE:
		// for casting of return value
		static char CLASS[] = "Triceps::Nexus";
		clearErrMsg();
		Triead *t = self->get();
		Triead::NexusMap m;
		t->readerImports(m);
		for (Triead::NexusMap::iterator it = m.begin(); it != m.end(); ++it) {
			XPUSHs(sv_2mortal(newSVpvn(it->first.c_str(), it->first.size())));

			SV *sub = newSV(0);
			sv_setref_pv( sub, CLASS, (void*)(new WrapNexus(it->second)) );
			XPUSHs(sv_2mortal(sub));
		}

SV *
writerImports(WrapTriead *self)
	PPCODE:
		// for casting of return value
		static char CLASS[] = "Triceps::Nexus";
		clearErrMsg();
		Triead *t = self->get();
		Triead::NexusMap m;
		t->writerImports(m);
		for (Triead::NexusMap::iterator it = m.begin(); it != m.end(); ++it) {
			XPUSHs(sv_2mortal(newSVpvn(it->first.c_str(), it->first.size())));

			SV *sub = newSV(0);
			sv_setref_pv( sub, CLASS, (void*)(new WrapNexus(it->second)) );
			XPUSHs(sv_2mortal(sub));
		}

