//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
// The wrapper for Nexus.

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "TricepsPerl.h"
#include "app/Nexus.h"

MODULE = Triceps::Nexus		PACKAGE = Triceps::Nexus
###################################################################################

int
CLONE_SKIP(...)
	CODE:
		RETVAL = 1;
	OUTPUT:
		RETVAL

void
DESTROY(WrapNexus *self)
	CODE:
		// Nexus *nx = self->get();
		// warn("Nexus %s %p wrap %p destroyed!", nx->getName().c_str(), to, self);
		delete self;

#// check whether both refs point to the same object
int
same(WrapNexus *self, WrapNexus *other)
	CODE:
		clearErrMsg();
		Nexus *nx1 = self->get();
		Nexus *nx2 = other->get();
		RETVAL = (nx1 == nx2);
	OUTPUT:
		RETVAL

char *
getName(WrapNexus *self)
	CODE:
		clearErrMsg();
		Nexus *nx = self->get();
		RETVAL = (char *)nx->getName().c_str();
	OUTPUT:
		RETVAL

char *
getTrieadName(WrapNexus *self)
	CODE:
		clearErrMsg();
		Nexus *nx = self->get();
		RETVAL = (char *)nx->getTrieadName().c_str();
	OUTPUT:
		RETVAL

int
isReverse(WrapNexus *self)
	CODE:
		clearErrMsg();
		Nexus *nx = self->get();
		RETVAL = nx->isReverse();
	OUTPUT:
		RETVAL

int
queueLimit(WrapNexus *self)
	CODE:
		clearErrMsg();
		Nexus *nx = self->get();
		RETVAL = nx->queueLimit();
	OUTPUT:
		RETVAL

#// tested in TrieadOwner.t
