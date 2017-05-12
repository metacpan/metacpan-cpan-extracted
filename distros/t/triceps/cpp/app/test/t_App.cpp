//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Test of the App building.

#include <assert.h>
#include <unistd.h>
#include <fcntl.h>
#include <utest/Utest.h>
#include "AppTest.h"

UTESTCASE statics(Utest *utest)
{
	make_catchable();

	// construction
	Autoref<App> a1 = App::make("a1");
	Autoref<App> a2 = App::make("a2");

	// successfull find
	Autoref<App> a;
	a = App::find("a1");
	UT_IS(a, a1);
	a = App::find("a2");
	UT_IS(a, a2);

	// list
	App::Map amap;
	App::listApps(amap);
	UT_IS(amap.size(), 2);
	UT_IS(amap["a1"], a1);
	UT_IS(amap["a2"], a2);

	// check that the old map gets cleared on the call
	App::listApps(amap);
	UT_IS(amap.size(), 2);

	// drop
	App::drop(a2);
	App::listApps(amap);
	UT_IS(amap.size(), 1);
	
	// unsuccessfull make
	{
		string msg;
		try {
			a = App::make("a1");
		} catch(Exception e) {
			msg = e.getErrors()->print();
		}
		UT_IS(msg, "Duplicate Triceps application name 'a1' is not allowed.\n");
	}

	// unsuccessfull find
	{
		string msg;
		try {
			a = App::find("a2");
		} catch(Exception e) {
			msg = e.getErrors()->print();
		}
		UT_IS(msg, "Triceps application 'a2' is not found.\n");
	}

	// drop of an unknown app
	App::drop(a2);

	// drop of an old app with the same name has no effect
	Autoref<App> aa2 = App::make("a2"); // new one
	App::listApps(amap);
	UT_IS(amap.size(), 2);
	App::drop(a2); // drop the old one
	App::listApps(amap);
	UT_IS(amap.size(), 2);
	a = App::find("a2");
	UT_IS(a, aa2);

	// clean-up, since the apps catalog is global
	App::drop(a1);
	App::drop(aa2);

	restore_uncatchable();
}

// Test that a newly created app with no threads is considered ready and dead.
UTESTCASE empty_is_ready(Utest *utest)
{
	Autoref<App> a1 = App::make("a1");
	UT_ASSERT(AppGuts::gutsIsReady(a1));
	UT_ASSERT(!a1->isAborted());
	UT_ASSERT(a1->isDead());
	AppGuts::gutsWaitReady(a1);
	a1->waitDead();

	a1->waitNeedHarvest();
	UT_ASSERT(a1->harvestOnce());

	// clean-up, since the apps catalog is global
	a1->harvester(false);
}

// Basic Triead creation, no actual OS-level threads yet.
UTESTCASE basic_trieads(Utest *utest)
{
	make_catchable();

	Autoref<App> a1 = App::make("a1");

	// successful creation
	Autoref<TrieadOwner> ow1 = a1->makeTriead("t1");
	UT_ASSERT(!AppGuts::gutsIsReady(a1));
	UT_ASSERT(!a1->isAborted());
	UT_ASSERT(!a1->isDead());
	UT_IS(ow1->get()->fragment(), "");

	Autoref<TrieadOwner> ow2 = a1->makeTriead("t2");
	UT_ASSERT(!AppGuts::gutsIsReady(a1));
	UT_ASSERT(!a1->isAborted());
	UT_ASSERT(!a1->isDead());

	Autoref<TrieadOwner> ow3 = a1->makeTriead("t3");
	UT_ASSERT(!AppGuts::gutsIsReady(a1));
	UT_ASSERT(!a1->isAborted());
	UT_ASSERT(!a1->isDead());

	// failed creation
	{
		string msg;
		try {
			Autoref<TrieadOwner> ow = a1->makeTriead("");
		} catch(Exception e) {
			msg = e.getErrors()->print();
		}
		UT_IS(msg, "Empty thread name is not allowed, in application 'a1'.\n");
	}
	{
		string msg;
		try {
			Autoref<TrieadOwner> ow = a1->makeTriead("t1");
		} catch(Exception e) {
			msg = e.getErrors()->print();
		}
		UT_IS(msg, "Duplicate thread name 't1' is not allowed, in application 'a1'.\n");
	}

	// TrieadOwner/Triead basic getters
	Autoref<Triead> t1 = ow1->get();
	UT_IS(t1->getName(), "t1");
	UT_ASSERT(!t1->isConstructed());
	UT_ASSERT(!t1->isReady());
	UT_ASSERT(!t1->isDead());

	UT_IS(ow1->unit()->getName(), "t1");
	UT_IS(ow1->app(), a1);

	// signal thread progression, one by one
	ow1->markConstructed();
	UT_ASSERT(t1->isConstructed());
	UT_ASSERT(!t1->isReady());
	UT_ASSERT(!t1->isDead());
	ow1->markReady();
	UT_ASSERT(t1->isConstructed());
	UT_ASSERT(t1->isReady());
	UT_ASSERT(!t1->isDead());
	ow1->markDead();
	UT_ASSERT(t1->isConstructed());
	UT_ASSERT(t1->isReady());
	UT_ASSERT(t1->isDead());
	// with no join defined, the thread will be immediately marked as joined
	UT_ASSERT(AppGuts::gutsIsJoining(a1, "t1"));
	UT_ASSERT(AppGuts::gutsIsJoined(a1, "t1"));

	// signal thread ready, implying constructed
	ow2->markReady();
	UT_ASSERT(ow2->get()->isConstructed());
	UT_ASSERT(ow2->get()->isReady());
	UT_ASSERT(!ow2->get()->isDead());

	UT_ASSERT(!AppGuts::gutsIsReady(a1));
	UT_ASSERT(!a1->isAborted());
	UT_ASSERT(!a1->isDead());

	// signal thread dead, implying constructed and ready
	ow3->markDead();
	UT_ASSERT(ow3->get()->isConstructed());
	UT_ASSERT(ow3->get()->isReady());
	UT_ASSERT(ow3->get()->isDead());

	UT_ASSERT(AppGuts::gutsIsReady(a1)); // all threads are ready now
	UT_ASSERT(!a1->isAborted());
	UT_ASSERT(!a1->isDead());

	// signal the last thread dead
	ow2->markDead();
	UT_ASSERT(ow2->get()->isConstructed());
	UT_ASSERT(ow2->get()->isReady());
	UT_ASSERT(ow2->get()->isDead());

	UT_ASSERT(AppGuts::gutsIsReady(a1)); // all threads are ready now
	UT_ASSERT(!a1->isAborted());
	UT_ASSERT(a1->isDead()); // all threads are dead now

	// repeated declaration of an existing thread is OK
	a1->declareTriead("t1");
	// nothing changes in readiness
	UT_ASSERT(AppGuts::gutsIsReady(a1)); // all threads are ready now
	UT_ASSERT(!a1->isAborted());
	UT_ASSERT(a1->isDead()); // all threads are dead now

	// declare one more thread
	a1->declareTriead("t4");
	// now have the unready and alive threads
	UT_ASSERT(!AppGuts::gutsIsReady(a1));
	UT_ASSERT(!a1->isAborted());
	UT_ASSERT(!a1->isDead());

	a1->declareTriead("t4"); // repeated declaration is OK

	// failed declare
	{
		string msg;
		try {
			a1->declareTriead("");
		} catch(Exception e) {
			msg = e.getErrors()->print();
		}
		UT_IS(msg, "Empty thread name is not allowed, in application 'a1'.\n");
	}

	// make the declared thread
	Autoref<TrieadOwner> ow4 = a1->makeTriead("t4");
	// now have the unready and alive threads
	UT_ASSERT(!AppGuts::gutsIsReady(a1));
	UT_ASSERT(!a1->isAborted());
	UT_ASSERT(!a1->isDead());

	// mark the last thread dead
	ow4->markDead();
	UT_ASSERT(AppGuts::gutsIsReady(a1)); // all threads are ready now
	UT_ASSERT(!a1->isAborted());
	UT_ASSERT(a1->isDead()); // all threads are dead now

	// clean-up, since the apps catalog is global
	a1->harvester(false);

	restore_uncatchable();
}

// basic Triead creation with fragments
UTESTCASE basic_frags(Utest *utest)
{
	make_catchable();

	Autoref<App> a1 = App::make("a1");

	// successful creation
	Autoref<TrieadOwner> ow1 = a1->makeTriead("t1", "frag1");
	UT_ASSERT(!AppGuts::gutsIsReady(a1));
	UT_ASSERT(!a1->isAborted());
	UT_ASSERT(!a1->isDead());
	UT_IS(ow1->get()->fragment(), "frag1");

	Autoref<TrieadOwner> ow2 = a1->makeTriead("t2", "frag1");
	UT_ASSERT(!AppGuts::gutsIsReady(a1));
	UT_ASSERT(!a1->isAborted());
	UT_ASSERT(!a1->isDead());
	UT_IS(ow2->get()->fragment(), "frag1");

	Autoref<TrieadOwner> ow3 = a1->makeTriead("t3", "frag2");
	UT_ASSERT(!AppGuts::gutsIsReady(a1));
	UT_ASSERT(!a1->isAborted());
	UT_ASSERT(!a1->isDead());
	UT_IS(ow3->get()->fragment(), "frag2");

	App::TrieadMap tm;
	App::TrieadMap::iterator tmit;

	a1->getTrieads(tm);
	UT_IS(tm.size(), 3);

	tmit = tm.find("t1");
	UT_ASSERT(tmit != tm.end() && tmit->second.get() == ow1->get());
	tmit = tm.find("t2");
	UT_ASSERT(tmit != tm.end() && tmit->second.get() == ow2->get());
	tmit = tm.find("t3");
	UT_ASSERT(tmit != tm.end() && tmit->second.get() == ow3->get());

	ow1->markReady();

	// can not shut down a frag until all the threads in it are ready
	{
		string msg;
		try {
			a1->shutdownFragment("frag1");
		} catch(Exception e) {
			msg = e.getErrors()->print();
		}
		UT_IS(msg, "Can not shut down the application 'a1' fragment 'frag1': its thread 't2' is not ready yet.\n");
	}

	a1->shutdownFragment("frag_unknown"); // a call for unknown frag is OK

	ow2->markReady();
	ow3->markReady();

	ow1->readyReady();

	a1->shutdownFragment("frag1");
	a1->shutdownFragment("frag1"); // a repeated call is OK
	a1->getTrieads(tm);
	UT_IS(tm.size(), 3); // still there

	ow2->readyReady(); // after the frag is shut down

	ow3->readyReady();

	ow1->markDead();
	a1->getTrieads(tm);
	UT_IS(tm.size(), 2); // t1 got disposed of
	tmit = tm.find("t1");
	UT_ASSERT(tmit == tm.end());

	ow2->markDead();
	a1->getTrieads(tm);
	UT_IS(tm.size(), 1); // t2 got disposed of
	tmit = tm.find("t2");
	UT_ASSERT(tmit == tm.end());

	a1->shutdownFragment("frag1"); // a call after all disposed of is OK
	ow1->markDead(); // OK to mark dead even after disposed of

	ow3->markDead();
	a1->getTrieads(tm);
	UT_IS(tm.size(), 1); // t3 is dead but still here

	a1->shutdownFragment("frag2");
	a1->getTrieads(tm);
	UT_IS(tm.size(), 0); // t3 get disposed of right away

	// mark the last thread dead
	UT_ASSERT(a1->isDead()); // all threads are dead now

	// clean-up, since the apps catalog is global
	a1->harvester(false);

	restore_uncatchable();
}

class TestPthreadEmpty : public BasicPthread
{
public:
	TestPthreadEmpty(const string &name):
		BasicPthread(name),
		joined_(false)
	{ }

	virtual void execute(TrieadOwner *to)
	{
		my_to_ = to;
		to->markDead();
	}

	virtual void join()
	{
		BasicPthread::join();
		joined_ = true;
	}

	bool joined_;
	Autoref<TrieadOwner> my_to_;
};

// The minimal construction, starting and joining of BasicPthread.
UTESTCASE basic_pthread_join(Utest *utest)
{
	make_catchable();

	Autoref<App> a1 = App::make("a1");

	Autoref<TestPthreadEmpty> pt1 = new TestPthreadEmpty("t1");
	pt1->start(a1);
	
	// clean-up, since the apps catalog is global
	a1->harvester(false);

	UT_ASSERT(pt1->joined_);
	UT_IS(pt1->fileInterrupt(), pt1->my_to_->fileInterrupt_.get());

	restore_uncatchable();
}

class TestPthreadWait : public BasicPthread
{
public:
	TestPthreadWait(const string &name, const string &wname, bool immed = false):
		BasicPthread(name),
		wname_(wname),
		result_(NULL),
		immed_(immed)
	{ }

	virtual void execute(TrieadOwner *to)
	{
		to_ = to;
		result_ = to->findTriead(wname_, immed_).get();
		to->markDead();
	}

	string wname_;
	Triead *result_;
	bool immed_; // immediate find
	TrieadOwner *to_; // for messing in the tests
};

// thread finding by name, successful case
UTESTCASE find_triead_success(Utest *utest)
{
	make_catchable();
	
	Autoref<App> a1 = App::make("a1");
	Autoref<TrieadOwner> ow1 = a1->makeTriead("t1");

	Triead *t;

	// Finding itself doesn't require the thread being constructed.
	t = ow1->findTriead("t1").get();
	UT_IS(t, ow1->get());

	// t7 for immediate find was added later, so its numbering is out of sequence
	Autoref<TestPthreadWait> pt7 = new TestPthreadWait("t7", "t1", true);
	pt7->start(a1);
	// t7 finds an un-constructed thread immediately
	AppGuts::gutsWaitTrieadDead(a1, "t7");
	UT_IS(pt7->result_, ow1->get());

	Autoref<TestPthreadWait> pt2 = new TestPthreadWait("t2", "t1");
	pt2->start(a1);
	Autoref<TestPthreadWait> pt3 = new TestPthreadWait("t3", "t1");
	pt3->start(a1);

	// wait until t2 and t3 actually wait for t1
	AppGuts::gutsWaitTrieadSleepers(a1, "t1", 2);

	// marking t1 as constructed must wake up the sleepers
	ow1->markConstructed();
	AppGuts::gutsWaitTrieadSleepers(a1, "t1", 0);
	AppGuts::gutsWaitTrieadDead(a1, "t2");
	AppGuts::gutsWaitTrieadDead(a1, "t3");

	// now repeat the same with an only-declared thread
	a1->declareTriead("t4");

	Autoref<TestPthreadWait> pt5 = new TestPthreadWait("t5", "t4");
	pt5->start(a1);
	Autoref<TestPthreadWait> pt6 = new TestPthreadWait("t6", "t4");
	pt6->start(a1);

	// wait until t5 and t6 actually wait for t4
	AppGuts::gutsWaitTrieadSleepers(a1, "t4", 2);

	// marking t4 as constructed must wake up the sleepers
	Autoref<TrieadOwner> ow4 = a1->makeTriead("t4");
	ow4->markConstructed();
	AppGuts::gutsWaitTrieadSleepers(a1, "t4", 0);
	AppGuts::gutsWaitTrieadDead(a1, "t5");
	AppGuts::gutsWaitTrieadDead(a1, "t6");

	// clean-up, since the apps catalog is global
	ow1->markDead();
	ow4->markDead();
	a1->harvester(false);

	UT_IS(pt2->result_, ow1->get());
	UT_IS(pt3->result_, ow1->get());
	UT_IS(pt5->result_, ow4->get());
	UT_IS(pt6->result_, ow4->get());

	restore_uncatchable();
}

// the find of an undefined thread fails immediately
UTESTCASE find_triead_immed_fail(Utest *utest)
{
	make_catchable();
	
	Autoref<App> a1 = App::make("a1");
	Autoref<TrieadOwner> ow1 = a1->makeTriead("t1");
	a1->declareTriead("t2");

	{
		string msg;
		try {
			ow1->findTriead("t2", true);
		} catch(Exception e) {
			msg = e.getErrors()->print();
		}
		UT_IS(msg, "In Triceps application 'a1' thread 't1' did an immediate find of a declared but undefined thread 't2'.\n");
	}

	// clean-up, since the apps catalog is global
	Autoref<TrieadOwner> ow2 = a1->makeTriead("t2");
	ow1->markDead();
	ow2->markDead();
	a1->harvester(false);

	restore_uncatchable();
}

// the abort of a thread
UTESTCASE basic_abort(Utest *utest)
{
	make_catchable();

	Autoref<App> a1 = App::make("a1");

	// successful creation
	Autoref<TrieadOwner> ow1 = a1->makeTriead("t1");
	UT_ASSERT(!AppGuts::gutsIsReady(a1));
	UT_ASSERT(!a1->isAborted());
	UT_ASSERT(!a1->isDead());

	Autoref<TestPthreadWait> pt2 = new TestPthreadWait("t2", "t1");
	pt2->start(a1);
	// wait until t2 actually waits for t1
	AppGuts::gutsWaitTrieadSleepers(a1, "t1", 1);

	// now abort! this will wake up the background thread too
	// (and throw an exception in it, which will be caught and
	// converted to another abort, which will be ignored)
	ow1->abort("test error");
	UT_ASSERT(AppGuts::gutsIsReady(a1));
	UT_ASSERT(a1->isAborted());

	AppGuts::gutsWaitTrieadDead(a1, "t2");
	UT_ASSERT(a1->isDead());

	UT_IS(a1->getAbortedBy(), "t1");
	UT_IS(a1->getAbortedMsg(), "test error");

	// creating another thread doesn't reset the abort or readiness
	Autoref<TrieadOwner> ow3 = a1->makeTriead("t3");
	Autoref<TrieadOwner> ow4 = a1->makeTriead("t4");
	UT_ASSERT(AppGuts::gutsIsReady(a1));
	UT_ASSERT(a1->isAborted());
	UT_ASSERT(!a1->isDead()); // but now it's definitely not dead

	ow4->markReady();

	// a wait for any thread after abort throws an immediate exception,
	// even if the target thread is ready or even the same thread
	{
		string msg;
		try {
			ow3->findTriead("t4"); // t4 is ready and not aborted itself
		} catch(Exception e) {
			msg = e.getErrors()->print();
		}
		UT_IS(msg, "App 'a1' has been aborted by thread 't1': test error\n");
	}
	{
		string msg;
		try {
			ow3->findTriead("t3"); // t4 is not aborted itself
		} catch(Exception e) {
			msg = e.getErrors()->print();
		}
		UT_IS(msg, "App 'a1' has been aborted by thread 't1': test error\n");
	}

	// one more abort gets ignored
	ow3->abort("another msg");
	UT_IS(a1->getAbortedBy(), "t1");
	UT_IS(a1->getAbortedMsg(), "test error");

	// clean-up, since the apps catalog is global
	ow4->markDead();
	// the error propagates through the harvester
	{
		string msg;
		try {
			a1->harvester();
		} catch(Exception e) {
			msg = e.getErrors()->print();
		}
		UT_IS(msg, "App 'a1' has been aborted by thread 't1': test error\n");
	}

	restore_uncatchable();
}

UTESTCASE timeout_find(Utest *utest)
{
	make_catchable();

	// successfully change the time as relative seconds
	{
		Autoref<App> a1 = App::make("a1");

		a1->setTimeout(0); // for immediate failure

		Autoref<TrieadOwner> ow1 = a1->makeTriead("t1");
		Autoref<TrieadOwner> ow2 = a1->makeTriead("t2");
		a1->declareTriead("t3");

		// check the timeout for construction
		{
			string msg;
			try {
				ow1->findTriead("t2");
			} catch(Exception e) {
				msg = e.getErrors()->print();
			}
			UT_IS(msg, "Thread 't2' in application 'a1' did not initialize within the deadline.\n");
		}

		// also check the timeout for the readiness wait
		{
			string msg;
			try {
				ow1->readyReady();
			} catch(Exception e) {
				msg = e.getErrors()->print();
			}
			UT_IS(msg, 
				"Application 'a1' did not initialize within the deadline.\n"
				"The lagging threads are:\n"
				"  t2: not constructed\n"
				"  t3: not defined\n");
		}

		// still have to mark them dead to harvest
		Autoref<TrieadOwner> ow3 = a1->makeTriead("t3");
		ow1->markDead();
		ow2->markDead();
		ow3->markDead();
		a1->harvester(false);
	}

	// successfully change the time as relative seconds, with separate for frags
	{
		Autoref<App> a1 = App::make("a1");

		a1->setTimeout(100, 0); // for immediate failure

		Autoref<TrieadOwner> ow1 = a1->makeTriead("t1");
		ow1->markReady(); // resets the deadline to 0

		a1->refreshDeadline(); // uses the frag value, still 0

		Autoref<TrieadOwner> ow2 = a1->makeTriead("t2");
		a1->declareTriead("t3");

		// check the timeout for construction
		{
			string msg;
			try {
				ow1->findTriead("t2");
			} catch(Exception e) {
				msg = e.getErrors()->print();
			}
			UT_IS(msg, "Thread 't2' in application 'a1' did not initialize within the deadline.\n");
		}

		// also check the timeout for the readiness wait
		{
			string msg;
			try {
				ow1->readyReady();
			} catch(Exception e) {
				msg = e.getErrors()->print();
			}
			UT_IS(msg, 
				"Application 'a1' did not initialize within the deadline.\n"
				"The lagging threads are:\n"
				"  t2: not constructed\n"
				"  t3: not defined\n");
		}

		// still have to mark them dead to harvest
		Autoref<TrieadOwner> ow3 = a1->makeTriead("t3");
		ow1->markDead();
		ow2->markDead();
		ow3->markDead();
		a1->harvester(false);
	}
	// successfully change the time as absolute point
	{
		Autoref<App> a1 = App::make("a1");

		timespec tm;
		clock_gettime(CLOCK_REALTIME, &tm);
		a1->setTimeout(100, 0); // so that the refresh won't delay the deadline
		a1->setDeadline(tm); // for immediate failure

		Autoref<TrieadOwner> ow1 = a1->makeTriead("t1");
		Autoref<TrieadOwner> ow2 = a1->makeTriead("t2");
		a1->declareTriead("t3");

		// check the timeout for construction of a declared thread
		{
			string msg;
			try {
				ow1->findTriead("t3");
			} catch(Exception e) {
				msg = e.getErrors()->print();
			}
			UT_IS(msg, "Thread 't3' in application 'a1' did not initialize within the deadline.\n");
		}

		// still have to mark them dead to harvest
		Autoref<TrieadOwner> ow3 = a1->makeTriead("t3");
		ow1->markDead();
		ow2->markDead();
		ow3->markDead();
		a1->harvester(false);
	}

	// can't change after the first thread was created
	{
		Autoref<App> a1 = App::make("a1");
		Autoref<TrieadOwner> ow1 = a1->makeTriead("t1");

		{
			string msg;
			try {
				a1->setTimeout(0);
			} catch(Exception e) {
				msg = e.getErrors()->print();
			}
			UT_IS(msg, "Triceps application 'a1' deadline can not be changed after the thread creation.\n");
		}
		{
			string msg;
			try {
				timespec tm;
				clock_gettime(CLOCK_REALTIME, &tm);
				a1->setDeadline(tm);
			} catch(Exception e) {
				msg = e.getErrors()->print();
			}
			UT_IS(msg, "Triceps application 'a1' deadline can not be changed after the thread creation.\n");
		}

		ow1->markDead();
		a1->harvester(false);
	}

	restore_uncatchable();
}

// detection of deadlocks in the find; 
// also used to test the catch of Exception in BasicPthread
UTESTCASE find_deadlock_catch_pthread(Utest *utest)
{
	make_catchable();
	
	Autoref<App> a1 = App::make("a1");

	a1->declareTriead("t1");

	Autoref<TestPthreadWait> pt2 = new TestPthreadWait("t2", "t1");
	pt2->start(a1);
	Autoref<TestPthreadWait> pt3 = new TestPthreadWait("t3", "t1");
	pt3->start(a1);
	Autoref<TestPthreadWait> pt4 = new TestPthreadWait("t4", "t2");
	pt4->start(a1);

	// wait until the sleepers settle down
	AppGuts::gutsWaitTrieadSleepers(a1, "t1", 2);
	AppGuts::gutsWaitTrieadSleepers(a1, "t2", 1);

	// now that the thread that will deadlock
	Autoref<TestPthreadWait> pt1 = new TestPthreadWait("t1", "t4");
	pt1->start(a1);

	AppGuts::gutsWaitTrieadDead(a1, "t1");

	// and it will throw an exception that will be caught and abort the app
	UT_ASSERT(a1->isAborted());
	UT_IS(a1->getAbortedBy(), "t1");
	UT_IS(a1->getAbortedMsg(), 
		"In Triceps application 'a1' thread 't1' waiting for thread 't4' would cause a deadlock:\n"
		"  t4 waits for t2\n"
		"  t2 waits for t1\n"
	);

	// clean-up, since the apps catalog is global
	a1->harvester(false);

	restore_uncatchable();
}

class TestPthreadNothing : public BasicPthread
{
public:
	TestPthreadNothing(const string &name):
		BasicPthread(name)
	{ }

	virtual void execute(TrieadOwner *to)
	{
		// do nothing
	}

	virtual void join()
	{
		BasicPthread::join();
	}
};

// check on BasicPthread exit that the thread was marked ready
UTESTCASE basic_pthread_assert(Utest *utest)
{
	make_catchable();
	
	Autoref<App> a1 = App::make("a1");

	Autoref<TestPthreadNothing> pt1 = new TestPthreadNothing("t1");
	pt1->start(a1);

	AppGuts::gutsWaitTrieadDead(a1, "t1");

	// and it will mark itself aborted
	UT_ASSERT(a1->isAborted());
	UT_IS(a1->getAbortedBy(), "t1");
	UT_IS(a1->getAbortedMsg(), "thread execution completed without marking it as ready");

	// clean-up, since the apps catalog is global
	a1->harvester(false);

	restore_uncatchable();
}

// can call abort even with an undeclared thread name
UTESTCASE any_abort(Utest *utest)
{
	make_catchable();
	
	Autoref<App> a1 = App::make("a1");
	Autoref<TrieadOwner> ow1 = a1->makeTriead("t1");

	a1->abortBy("t2", "test error"); // t2 is not even declared
	UT_ASSERT(a1->isAborted());
	UT_IS(a1->getAbortedBy(), "t2");
	UT_IS(a1->getAbortedMsg(), "test error");

	// clean-up, since the apps catalog is global
	ow1->markDead();
	a1->harvester(false);

	restore_uncatchable();
}

class TrieadJoinEmpty : public TrieadJoin
{
public:
	TrieadJoinEmpty(const string &name):
		TrieadJoin(name),
		s_("abcd")
	{ }

	virtual void join()
	{ } // do nothing

	string s_; // to test the virtual destruction
};

// test all varieties of defineJoin()
UTESTCASE define_join(Utest *utest)
{
	make_catchable();
	
	Autoref<App> a1 = App::make("a1");
	Autoref<TrieadOwner> ow1 = a1->makeTriead("t1");
	Autoref<TrieadJoin> j1 = new TrieadJoinEmpty("t1");

	{
		string msg;
		try {
			a1->defineJoin("t2", j1);
		} catch(Exception e) {
			msg = e.getErrors()->print();
		}
		UT_IS(msg, "In Triceps application 'a1' can not define a join for an unknown thread 't2'.\n");
	}

	a1->defineJoin("t1", j1);
	a1->defineJoin("t1", NULL);
	UT_IS(AppGuts::gutsJoin(a1, "t1"), NULL);
	a1->defineJoin("t1", j1);
	UT_IS(AppGuts::gutsJoin(a1, "t1"), j1.get());

	ow1->markDead();
	// after harvest the thread will be marked as joined
	a1->harvestOnce();
	UT_ASSERT(AppGuts::gutsIsJoining(a1, "t1"));
	UT_ASSERT(AppGuts::gutsIsJoined(a1, "t1"));
	UT_IS(AppGuts::gutsJoin(a1, "t1"), NULL);

	{
		string msg;
		try {
			a1->defineJoin("t1", j1);
		} catch(Exception e) {
			msg = e.getErrors()->print();
		}
		UT_IS(msg, "In Triceps application 'a1' can not define a join for thread 't1' after it has been already joined.\n");
	}

	// clean-up, since the apps catalog is global
	a1->harvester(false);

	restore_uncatchable();
}

// one that throws on a join attempt
class TrieadJoinThrow : public TrieadJoin
{
public:
	TrieadJoinThrow(const string &name, const string &msg):
		TrieadJoin(name),
		msg_(msg)
	{ }

	virtual void join()
	{
		throw Exception::f("test exception: %s", msg_.c_str());
	}

	string msg_;
};

// test the exception handling in the joins
UTESTCASE join_throw(Utest *utest)
{
	make_catchable();
	
	App::TrieadMap tm;
	App::TrieadMap::iterator tmit;

	Autoref<App> a1 = App::make("a1");
	Autoref<TrieadOwner> ow1 = a1->makeTriead("t1");
	Autoref<TrieadJoin> j1 = new TrieadJoinThrow("t1", "one");
	Autoref<TrieadOwner> ow2 = a1->makeTriead("t2", "frag2");
	Autoref<TrieadJoin> j2 = new TrieadJoinThrow("t2", "two");

	// t3 doesn't throw in join
	Autoref<TrieadOwner> ow3 = a1->makeTriead("t3");
	Autoref<TrieadJoin> j3 = new TrieadJoinEmpty("t3");

	a1->defineJoin("t1", j1);
	UT_IS(AppGuts::gutsJoin(a1, "t1"), j1.get());
	a1->defineJoin("t2", j2);
	UT_IS(AppGuts::gutsJoin(a1, "t2"), j2.get());
	a1->defineJoin("t3", j3);
	UT_IS(AppGuts::gutsJoin(a1, "t3"), j3.get());

	ow1->markDead();
	ow2->markDead();
	ow3->markDead();

	// exception on joining the t1
	{
		string msg;
		try {
			a1->harvestOnce();
		} catch(Exception e) {
			msg = e.getErrors()->print();
		}
		UT_IS(msg, "Failed to join the thread 't1' of application 'a1':\n  test exception: one\n");
	}

	// after harvest the join will be dropped
	UT_IS(AppGuts::gutsJoin(a1, "t1"), NULL);

	// t1 is not in a fragment, so it will be still present
	a1->getTrieads(tm);
	UT_IS(tm.size(), 3);
	tmit = tm.find("t1");
	UT_ASSERT(tmit != tm.end() && tmit->second.get() == ow1->get());

	// shut down the fragment, making t2 disposable
	a1->shutdownFragment("frag2");
	UT_ASSERT(AppGuts::gutsIsInterrupted(a1, "t2"));

	// exception on joining the t2, all the way through harvester
	{
		string msg;
		try {
			a1->harvester(false);
		} catch(Exception e) {
			msg = e.getErrors()->print();
		}
		UT_IS(msg, "Failed to join the thread 't2' of application 'a1':\n  test exception: two\n");
	}

	// t2 is in a fragment, so a join will dispose of it
	a1->getTrieads(tm);
	UT_IS(tm.size(), 2);
	tmit = tm.find("t2");
	UT_ASSERT(tmit == tm.end());

	// clean up t3, being able to continue after an exception
	a1->harvester(false);

	restore_uncatchable();
}

// the other error conditions in findTriead()
UTESTCASE find_errors(Utest *utest)
{
	make_catchable();
	
	Autoref<App> a1 = App::make("a1");
	Autoref<TrieadOwner> ow1 = a1->makeTriead("t1");
	Autoref<TestPthreadWait> pt2 = new TestPthreadWait("t2", "t1");
	pt2->start(a1);

	// one find comes from the other thread
	AppGuts::gutsWaitTrieadSleepers(a1, "t1", 1);

	// try calling find from 2 separate OS threads on the same owner
	{
		string msg;
		try {
			pt2->to_->findTriead("t1");
		} catch(Exception e) {
			msg = e.getErrors()->print();
		}
		UT_IS(msg, "In Triceps application 'a1' thread 't2' owner object must not be used from 2 OS threads.\n");
	}

	// try to find an undeclared thread
	{
		string msg;
		try {
			ow1->findTriead("t3");
		} catch(Exception e) {
			msg = e.getErrors()->print();
		}
		UT_IS(msg, "In Triceps application 'a1' thread 't1' is referring to a non-existing thread 't3'.\n");
	}

	// clean-up, since the apps catalog is global
	ow1->markDead();
	a1->harvester(false);

	restore_uncatchable();
}

UTESTCASE store_fd(Utest *utest)
{
	// the bigger-scale testing is done in Perl
	string rcl;
	int rfd;

	make_catchable();

	int fd = open("/dev/null", O_RDONLY);
	UT_ASSERT(fd >= 0);

	Autoref<App> a1 = App::make("a1");
	a1->storeFd("f1", fd);
	rfd = a1->loadFd("f1");
	UT_IS(rfd, fd);

	rcl = "XXX";
	rfd = a1->loadFd("f1", &rcl);
	UT_IS(rfd, fd);
	UT_IS(rcl, "");

	a1->storeFd("f2", fd, "CLASS");
	rfd = a1->loadFd("f2");
	UT_IS(rfd, fd);

	rcl = "XXX";
	rfd = a1->loadFd("f2", &rcl);
	UT_IS(rfd, fd);
	UT_IS(rcl, "CLASS");

	a1->storeFd("ff", 98);
	{
		string msg;
		try {
			a1->storeFd("ff", 99);
		} catch(Exception e) {
			msg = e.getErrors()->print();
		}
		UT_IS(msg, "store of duplicate descriptor 'ff', new fd=99, existing fd=98\n");
	}

	{
		string msg;
		try {
			a1->storeFd("ff", 99, "CLASS");
		} catch(Exception e) {
			msg = e.getErrors()->print();
		}
		UT_IS(msg, "store of duplicate descriptor 'ff', new fd=99, existing fd=98\n");
	}

	UT_IS(a1->loadFd("zz"), -1);

	UT_IS(a1->forgetFd("ff"), true);
	UT_IS(a1->forgetFd("ff"), false);

	UT_IS(a1->forgetFd("f1"), true);
	UT_IS(a1->closeFd("f2"), true);
	UT_IS(a1->closeFd("f2"), false);

	rfd = open("/dev/null", O_RDONLY);
	UT_IS(rfd, fd); // if fd cor closed, rfd will get the same id
	close(rfd);

	restore_uncatchable();
}
