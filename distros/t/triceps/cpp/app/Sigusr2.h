//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// The dummy handler of SIGUSR2 that Triceps uses to interrupt the file reads.

#ifndef __Triceps_Sigusr2_h__
#define __Triceps_Sigusr2_h__

#include <common/Common.h>
#include <pw/ptwrap2.h>

namespace TRICEPS_NS {

class Sigusr2
{
public:
	// Set up the dummy handler for SIGUSR2 if it hasn't been done yet.
	static void setup();

	// A way for the user to install his own custom SIGUSR2 handler.
	// If it's being installed at the program initialization time, before
	// any Triceps threads created, just set up your handler and then
	// call markDone(). It it's installed somewhere in the middle of
	// peorgam's work then to avoid the race you need to set up your
	// handler, call markDone(), then set up your handler again.
	//
	// If the sigaction() call fails, will throw an Exception.
	static void markDone();

	// A way for the user to replace a custom SIGUSR2 handler
	// with the Triceps dummy one. Just call reSetup() and it will
	// be replaced.
	//
	// If the sigaction() call fails, will throw an Exception.
	static void reSetup();

protected:
	// actually sets up the handler
	static void doSetupL();

	static pw::pmutex mutex_;
	static bool done_; // flag: the setup is done
};

}; // TRICEPS_NS

#endif // __Triceps_Sigusr2_h__
