//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
// The wrapper for FrameMark.

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "TricepsPerl.h"

MODULE = Triceps::FrameMark		PACKAGE = Triceps::FrameMark
###################################################################################

int
CLONE_SKIP(...)
	CODE:
		RETVAL = 1;
	OUTPUT:
		RETVAL

void
DESTROY(WrapFrameMark *self)
	CODE:
		FrameMark *mark = self->get();
		// warn("FrameMark %s %p wrap %p destroyed!", mark->getName().c_str(), mark, self);
		delete self;


WrapFrameMark *
Triceps::FrameMark::new(char *name)
	CODE:
		clearErrMsg();

		Autoref<FrameMark> mark = new FrameMark(name);
		WrapFrameMark *wm = new WrapFrameMark(mark);
		RETVAL = wm;
	OUTPUT:
		RETVAL

char *
getName(WrapFrameMark *self)
	CODE:
		clearErrMsg();
		FrameMark *mark = self->get();
		RETVAL = (char *)mark->getName().c_str();
	OUTPUT:
		RETVAL

#// check whether both refs point to the same object
int
same(WrapFrameMark *self, WrapFrameMark *other)
	CODE:
		clearErrMsg();
		FrameMark *mark = self->get();
		FrameMark *omark = other->get();
		RETVAL = (mark == omark);
	OUTPUT:
		RETVAL

#// FrameMark is a token object, so there is not much to do with it

