//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// The dummy handler of SIGUSR2 that Triceps uses to interrupt the file reads.

#include <signal.h>
#include <string.h>
#include <stdlib.h>
#include <app/Sigusr2.h>

namespace TRICEPS_NS {

// for catching SIGUSR2
static void dummyHandler(int sig)
{ }

bool Sigusr2::done_ = false;
pw::pmutex Sigusr2::mutex_;

void Sigusr2::setup()
{
	pw::lockmutex lm(mutex_);
	if (!done_)
		doSetupL();
}

void Sigusr2::markDone()
{
	pw::lockmutex lm(mutex_);
	done_ = true;
}

void Sigusr2::reSetup()
{
	pw::lockmutex lm(mutex_);
	doSetupL();
}

void Sigusr2::doSetupL()
{
	struct sigaction actdummy;
	actdummy.sa_handler = dummyHandler;
	sigemptyset(&actdummy.sa_mask);
	actdummy.sa_flags = 0;

	if (sigaction(SIGUSR2, &actdummy, NULL) < 0)
		throw Exception::f("Triceps::Sigusr2: sigaction() failed: %s", strerror(errno));

	done_ = true;
}

}; // TRICEPS_NS

