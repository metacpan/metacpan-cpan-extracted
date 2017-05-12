//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
// Representation of the Perl values that can be passed to the other threads.
//
// The XS part is really here for testing, though it might have some uses in the future.

// ###################################################################################

#include <typeinfo>
#include <map>
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "TricepsPerl.h"
#include "TrackedFile.h"

using namespace TRICEPS_NS;

namespace TRICEPS_NS
{
namespace TricepsPerl 
{

WrapMagic magicWrapTrackedFile = { "TrkFile" };

WrapTrackedFile::WrapTrackedFile(TrieadOwner *owner, SV *svfile, int afd) :
	magic_(magicWrapTrackedFile),
	owner_(owner),
	svfile_(svfile),
	fd_(afd)
{ 
	if (svfile_)
		SvREFCNT_inc(svfile_);
}

WrapTrackedFile::~WrapTrackedFile()
{
	if (svfile_ != NULL) {
		owner_->fileInterrupt_->forgetFd(fd_);
		SvREFCNT_dec(svfile_);
	}
}

void WrapTrackedFile::close()
{
	dSP;

	if (svfile_ == NULL)
		return; // nothing to do

	owner_->fileInterrupt_->forgetFd(fd_);
	owner_ = NULL;  // no more use for it
	fd_ = -1;

	ENTER; SAVETMPS; 

	PUSHMARK(SP);
	XPUSHs(svfile_);
	PUTBACK; 

	call_pv("Triceps::_close", G_SCALAR|G_EVAL);

	// don't care about the result
	SPAGAIN;
	PUTBACK; 

	FREETMPS; LEAVE;

	SvREFCNT_dec(svfile_);
	svfile_ = NULL;

	if (SvTRUE(ERRSV)) {
		throw Exception::f("TrackedFile: file close error: %s", SvPV_nolen(ERRSV));
	}
}

}; // Triceps::TricepsPerl
}; // Triceps

MODULE = Triceps::TrackedFile		PACKAGE = Triceps::TrackedFile
###################################################################################

int
CLONE_SKIP(...)
	CODE:
		RETVAL = 1;
	OUTPUT:
		RETVAL

#// This only der
void
DESTROY(WrapTrackedFile *self)
	CODE:
		// warn("WrapTrackedFile %p destroyed!", self);
		delete self;

#// get back the file descriptor
int
fd(WrapTrackedFile *self)
	CODE:
		clearErrMsg();
		RETVAL = 0;
		try { do {
			if (self->sv() == NULL)
				throw Exception::f("Triceps::TrackedFile::fd: the file is already closed");
			RETVAL = self->fd();
		} while(0); } TRICEPS_CATCH_CROAK;
	OUTPUT:
		RETVAL

#// get the file handle object
SV *
get(WrapTrackedFile *self)
	CODE:
		clearErrMsg();
		RETVAL = self->sv();
		try { do {
			if (RETVAL == NULL)
				throw Exception::f("Triceps::TrackedFile::get: the file is already closed");
			SvREFCNT_inc(RETVAL); // XS will make it mortal on return
		} while(0); } TRICEPS_CATCH_CROAK;
	OUTPUT:
		RETVAL

#// forget the handle, close and dereference the file handle object;
#// any errors cause a confession
void
close(WrapTrackedFile *self)
	CODE:
		clearErrMsg();
		try { do {
			self->close();
		} while(0); } TRICEPS_CATCH_CROAK;

#// Constructed through TrieadOwner
