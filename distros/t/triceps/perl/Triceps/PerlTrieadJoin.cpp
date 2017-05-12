//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
// Helpers to join the Perl threads from the App.

#include <signal.h>
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "TricepsPerl.h"
#include "PerlTrieadJoin.h"

// ###################################################################################

using namespace TRICEPS_NS;

namespace TRICEPS_NS
{
namespace TricepsPerl 
{

PerlTrieadJoin::PerlTrieadJoin(const string &appname, const string &tname, IV tid, IV handle, bool istest):
	TrieadJoin(tname),
	appname_(appname),
	tid_(tid),
	handle_((pthread_t *)handle),
	testFail_(istest)
{ }

void PerlTrieadJoin::join()
{
	dSP;

	if (testFail_)
		throw Exception::f("PerlTrieadJoin::join test of error catching app '%s' thread '%s'",
			appname_.c_str(), name_.c_str());

	IV id;
	{
		pw::lockmutex lm(mutex_);
		if (tid_ == -1)
			return;
		id = tid_;
		tid_ = -1; // preclude any future attempts to join
	}

	// Can not create cb when creating the object, since that is happening in a
	// different thread, and will cause a deadlock inside Perl when joining.
	Autoref<PerlCallback> cb = new PerlCallback;
	try {
		cb->setCode(get_sv("Triceps::_JOIN_TID", 0), "");
	} catch (Exception e) {
		throw Exception::f("In the application '%s' thread '%s' join: can not find a function reference $Triceps::_JOIN_TID",
			appname_.c_str(), name_.c_str());;
	}

	PerlCallbackStartCall(cb);
	XPUSHs(sv_2mortal(newSViv(id)));
	PerlCallbackDoCall(cb);
	callbackSuccessOrThrow("Detected in the application '%s' thread '%s' join.", appname_.c_str(), name_.c_str());
}

void PerlTrieadJoin::interrupt()
{
	dSP;

	if (testFail_)
		throw Exception::f("PerlTrieadJoin::interrupt test of error catching app '%s' thread '%s'",
			appname_.c_str(), name_.c_str());
	else {
		TrieadJoin::interrupt();

		pw::lockmutex lm(mutex_);
		if (tid_ != -1 && handle_ != NULL) {
			// Unfortunately, the Perl's threads::kill() doesn't actually send a signal
			// but just sets a flag in the interpreter, so it can not be used to interrupt
			// a system call. Instead the signal is sent through the underlying pthread interface.
			pthread_kill(*handle_, SIGUSR2);
		}
	}
}

}; // Triceps::TricepsPerl
}; // Triceps
