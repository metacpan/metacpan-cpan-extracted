//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Test of the QueEvent synchronization.

#include <utest/Utest.h>
#include "AppTest.h"

class QueWaitT: public Mtarget, public pw::pwthread
{
public:
	// will write this xtray to this NexusWriter
	QueWaitT(QueEvent *qev):
		qev_(qev)
	{ }

	virtual void *execute()
	{
		qev_->wait();
		return NULL;
	}

	Autoref<QueEvent> qev_;
};

class QueTimeWaitT: public Mtarget, public pw::pwthread
{
public:
	// will write this xtray to this NexusWriter
	QueTimeWaitT(QueEvent *qev):
		qev_(qev)
	{ }

	virtual void *execute()
	{
		timespec atm;
		atm.tv_sec = 0;
		atm.tv_nsec = 0;
		return (void *)qev_->timedwait(atm); // this normally returns immediately!
	}

	Autoref<QueEvent> qev_;
};

// the reader side of the QueEvent
UTESTCASE drain_reader(Utest *utest)
{
	Autoref<DrainApp> drain = new DrainApp;
	Autoref<QueEvent> qev = new QueEvent(drain);
	timespec atm;
	atm.tv_sec = 0;
	atm.tv_nsec = 0;

	drain->left_ = 0; // initialize
	UT_ASSERT(!drain->ev_.signaled_);

	UT_ASSERT(!QueEventGuts::isSignaled(qev));
	UT_ASSERT(!QueEventGuts::isRqDrain(qev));

	// make sure that the time wait times out normally
	UT_IS(qev->timedwait(atm), ETIMEDOUT);

	// check that by default the wait and signal doesn't
	// touch the drain object
	{
		
		Autoref<QueWaitT> qwt = new QueWaitT(qev);
		qwt->start();

		QueEventGuts::waitSleeping(qev);
		// now the thread is really waiting

		UT_IS(drain->left_, 0);
		qev->signal();

		qwt->join();
		UT_IS(drain->left_, 0);
	}

	drain->init();
	UT_IS(drain->left_, 1);
	UT_ASSERT(!drain->ev_.signaled_);

	qev->requestDrain();
	UT_ASSERT(QueEventGuts::isRqDrain(qev));
	UT_ASSERT(!QueEventGuts::isDrained(qev));
	UT_IS(drain->left_, 2); // since the event is not stuck in waiting
	// check the QueEvent with a pending drain request
	{
		
		Autoref<QueWaitT> qwt = new QueWaitT(qev);
		qwt->start();

		QueEventGuts::waitSleeping(qev);
		// now the thread is really waiting

		UT_ASSERT(QueEventGuts::isDrained(qev));
		UT_IS(drain->left_, 1); // waiting means drained
		{
			pw::lockmutex lm(qev->mutex());
			qev->signalL();
			UT_ASSERT(!QueEventGuts::isDrained(qev));
			UT_IS(drain->left_, 2); // even before the sleeper wakes up!
		}

		qwt->join();
		UT_ASSERT(!QueEventGuts::isDrained(qev));
		UT_IS(drain->left_, 2);
	}
	// check the QueEvent timed wait with a pending drain request
	// until undrained or signaled
	{
		
		Autoref<QueTimeWaitT> qwt = new QueTimeWaitT(qev);
		qwt->start();

		QueEventGuts::waitSleeping(qev);
		// give it a chance to continue, so it's not a fluke
		QueEventGuts::waitSleeping(qev);
		QueEventGuts::waitSleeping(qev);
		QueEventGuts::waitSleeping(qev);
		QueEventGuts::waitSleeping(qev);
		// now the thread is really waiting

		UT_IS(drain->left_, 1); // waiting means drained
		UT_ASSERT(QueEventGuts::isDrained(qev));
		{
			pw::lockmutex lm(qev->mutex());
			qev->signalL();
			UT_ASSERT(!QueEventGuts::isDrained(qev));
			UT_IS(drain->left_, 2); // even before the sleeper wakes up!
		}
		// signaling wakes up the wait, and it's 0 return code

		UT_IS(qwt->join(), (void *)0);
		UT_ASSERT(!QueEventGuts::isDrained(qev));
		UT_IS(drain->left_, 2);
	}

	// mark the drain as having completed the init
	drain->initDone();
	UT_IS(drain->left_, 1);
	UT_ASSERT(!drain->ev_.signaled_);
	
	// check the QueEvent with a pending drain request
	{
		UT_ASSERT(!QueEventGuts::isDrained(qev));
		
		Autoref<QueWaitT> qwt = new QueWaitT(qev);
		qwt->start();

		QueEventGuts::waitSleeping(qev);
		// now the thread is really waiting

		UT_IS(drain->left_, 0); // waiting means drained
		UT_ASSERT(drain->ev_.signaled_);
		UT_ASSERT(QueEventGuts::isDrained(qev));
		{
			pw::lockmutex lm(qev->mutex());
			qev->signalL();
			UT_ASSERT(!QueEventGuts::isDrained(qev));
			UT_IS(drain->left_, 1); // even before the sleeper wakes up!
			UT_ASSERT(!drain->ev_.signaled_);
		}

		qwt->join();
		UT_ASSERT(!QueEventGuts::isDrained(qev));
		UT_IS(drain->left_, 1);
	}
	// check that undraining wakes up the timed wait
	{
		
		Autoref<QueTimeWaitT> qwt = new QueTimeWaitT(qev);
		qwt->start();

		QueEventGuts::waitSleeping(qev);
		// give it a chance to continue, so it's not a fluke
		QueEventGuts::waitSleeping(qev);
		QueEventGuts::waitSleeping(qev);
		QueEventGuts::waitSleeping(qev);
		QueEventGuts::waitSleeping(qev);
		// now the thread is really waiting

		UT_IS(drain->left_, 0); // waiting means drained
		UT_ASSERT(QueEventGuts::isDrained(qev));
		qev->requestUndrain();
		UT_ASSERT(!QueEventGuts::isRqDrain(qev));
		UT_ASSERT(QueEventGuts::isDrained(qev)); // left unchanged because it doesn't matter

		// undraining wakes up the timed wait, and it's ETIMEDOUT return code
		UT_IS(qwt->join(), (void *)ETIMEDOUT);
		UT_IS(drain->left_, 0); // and it doesn't touch the undrained count
	}

	// --------------------------------------------------------------------------

	// now drain again but this time the reader will be already sleeping
	{
		Autoref<QueWaitT> qwt = new QueWaitT(qev);
		qwt->start();

		QueEventGuts::waitSleeping(qev);
		// now the thread is really waiting

		// do the drain in the middle
		drain->init();
		UT_IS(drain->left_, 1);
		UT_ASSERT(!drain->ev_.signaled_);

		qev->requestDrain();
		UT_ASSERT(QueEventGuts::isRqDrain(qev));
		UT_ASSERT(QueEventGuts::isDrained(qev));

		QueEventGuts::waitSleeping(qev); // the reader is still sleeping

		drain->initDone();
		UT_IS(drain->left_, 0);
		UT_ASSERT(drain->ev_.signaled_);

		qev->requestUndrain();
		UT_ASSERT(!QueEventGuts::isRqDrain(qev));
		UT_ASSERT(QueEventGuts::isDrained(qev)); // left unchanged because it doesn't matter

		{
			pw::lockmutex lm(qev->mutex());
			qev->signalL();
			UT_IS(drain->left_, 0); // and it doesn't touch the undrained count
		}

		qwt->join();
		UT_IS(drain->left_, 0);
	}
	
	// --------------------------------------------------------------------------

	// now mark the thread as dead, it should become drained
	{
		// start the drain
		drain->init();
		UT_IS(drain->left_, 1);
		UT_ASSERT(!drain->ev_.signaled_);

		qev->requestDrain();
		UT_IS(drain->left_, 2);
		UT_ASSERT(QueEventGuts::isRqDrain(qev));
		UT_ASSERT(!QueEventGuts::isDrained(qev));

		drain->initDone();
		UT_IS(drain->left_, 1);
		UT_ASSERT(!drain->ev_.signaled_);

		qev->markDead(); // marks drained
		UT_IS(drain->left_, 0);
		UT_ASSERT(drain->ev_.signaled_);

		qev->markDead(); // repetitive use doesn't hurt
		UT_IS(drain->left_, 0);

		qev->requestUndrain();
		UT_ASSERT(!QueEventGuts::isRqDrain(qev));

		// now request drain again, after the thread is dead
		qev->requestDrain();
		UT_IS(drain->left_, 0); // unchanged
		UT_ASSERT(QueEventGuts::isRqDrain(qev));
		UT_ASSERT(QueEventGuts::isDrained(qev));
	}
}

class QueBeforeWriteT: public Mtarget, public pw::pwthread
{
public:
	// will write this xtray to this NexusWriter
	QueBeforeWriteT(QueEvent *qev):
		qev_(qev),
		started_(false)
	{ }

	virtual void *execute()
	{
		started_ = true;
		return (void *)qev_->beforeWrite();
	}

	Autoref<QueEvent> qev_;
	bool started_;
};

// the writer side of the QueEvent
UTESTCASE drain_writer(Utest *utest)
{
	Autoref<DrainApp> drain = new DrainApp;
	Autoref<QueEvent> qev = new QueEvent(drain);

	qev->setWriteMode(); // a prerequisite
	UT_ASSERT(QueEventGuts::isSleeping(qev));

	// with no drains, the write proceeds unimpeded
	UT_ASSERT(qev->beforeWrite());
	UT_ASSERT(QueEventGuts::isSignaled(qev));
	qev->afterWrite();
	UT_ASSERT(!QueEventGuts::isSignaled(qev));

	// --------------------------------------------------------------------------

	// start a drain, then try to write
	drain->init();
	UT_IS(drain->left_, 1);
	UT_ASSERT(!drain->ev_.signaled_);

	qev->requestDrain();
	UT_ASSERT(QueEventGuts::isRqDrain(qev));
	UT_ASSERT(QueEventGuts::isDrained(qev));
	UT_IS(drain->left_, 1); // nobody sleeps, no increase

	drain->initDone();
	UT_IS(drain->left_, 0);
	UT_ASSERT(drain->ev_.signaled_);

	{
		Autoref<QueBeforeWriteT> qwt = new QueBeforeWriteT(qev);
		qwt->start();

		while (!qwt->started_)
			sched_yield();

		// no way to tell that it actually is sleeping, so do the
		// next best
		sched_yield();
		sched_yield();
		sched_yield();
		UT_ASSERT(!QueEventGuts::isSignaled(qev));
		qev->reset(); // this locks/unlocks the mutex
		sched_yield();
		sched_yield();
		sched_yield();

		// undraining wakes up the sleeper
		qev->requestUndrain();
		UT_ASSERT(qwt->join());
		UT_ASSERT(QueEventGuts::isSignaled(qev));

		qev->afterWrite();
		UT_ASSERT(!QueEventGuts::isSignaled(qev));
		UT_IS(drain->left_, 0); // left unchanged
	}
	
	// --------------------------------------------------------------------------

	// start a write then request a drain
	UT_ASSERT(qev->beforeWrite());
	UT_ASSERT(QueEventGuts::isSignaled(qev));

	// start the drain
	drain->init();
	UT_IS(drain->left_, 1);
	UT_ASSERT(!drain->ev_.signaled_);

	qev->requestDrain();
	UT_ASSERT(QueEventGuts::isRqDrain(qev));
	UT_IS(drain->left_, 2);

	drain->initDone();
	UT_IS(drain->left_, 1);
	UT_ASSERT(!drain->ev_.signaled_);

	qev->afterWrite();
	UT_ASSERT(!QueEventGuts::isSignaled(qev));
	UT_IS(drain->left_, 0); // now the drain is completed
	UT_ASSERT(drain->ev_.signaled_);

	// undraining pretty much does nothing
	qev->requestUndrain();
	UT_ASSERT(!QueEventGuts::isRqDrain(qev));
	
	// --------------------------------------------------------------------------

	// request a drain, then start a write, then mark as dead (since it's invoked 
	// on requestDead() for the input-only threads)
	{
		// start the drain
		drain->init();
		UT_IS(drain->left_, 1);
		UT_ASSERT(!drain->ev_.signaled_);

		qev->requestDrain();
		UT_ASSERT(QueEventGuts::isRqDrain(qev));
		UT_IS(drain->left_, 1);

		drain->initDone();
		UT_IS(drain->left_, 0);
		UT_ASSERT(drain->ev_.signaled_);

		Autoref<QueBeforeWriteT> qwt = new QueBeforeWriteT(qev);
		qwt->start();

		while (!qwt->started_)
			sched_yield();

		// no way to tell that it actually is sleeping, so do the
		// next best
		sched_yield();
		sched_yield();
		sched_yield();
		UT_ASSERT(!QueEventGuts::isSignaled(qev));
		qev->reset(); // this locks/unlocks the mutex
		sched_yield();
		sched_yield();
		sched_yield();

		// marking as dead wakes up the sleeper and keeps the event drained
		qev->markDead();
		UT_ASSERT(!qwt->join());
		UT_ASSERT(!QueEventGuts::isSignaled(qev)); // unchanged

		UT_IS(drain->left_, 0);
		UT_ASSERT(drain->ev_.signaled_);

		// any future attempts to do a write return false
		UT_ASSERT(!qev->beforeWrite());
	}
}
