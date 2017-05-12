//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// A basic OS-level Posix thread implementation for Triceps.

#include <string.h>
#include <signal.h>
#include <app/BasicPthread.h>
#include <app/Sigusr2.h>

namespace TRICEPS_NS {

BasicPthread::BasicPthread(const string &name):
	TrieadJoin(name),
	id_(0)
{ }

void BasicPthread::start(Autoref<App> app)
{
	Sigusr2::setup();
	pw::lockmutex lm(mutex_);
	startL(app, app->makeTriead(name_)); // makeTriead might throw
}

void BasicPthread::start(Autoref<TrieadOwner> to)
{
	Sigusr2::setup();
	pw::lockmutex lm(mutex_);
	startL(to->app(), to);
}

void BasicPthread::startL(Autoref<App> app, Autoref<TrieadOwner> to)
{
	to_ = to;
	to->fileInterrupt_ = fileInterrupt();
	selfref_ = this; // will be reset to NULL in run_it
	int err = pthread_create(&id_, NULL, run_it, (void *)this); // sets id_
	if (err != 0) {
		selfref_ = NULL;
		string s = strprintf("failed to start: err=%d %s",
			err, strerror(err));
		to_->abort(s);
		to_ = NULL;
		throw Exception::fTrace("In Triceps app '%s' failed to start thread '%s': err=%d %s",
			app->getName().c_str(), name_.c_str(), err, strerror(err));
	}
	// There is no race between defineJoin() and shutdown() because the
	// shutdown flag gets checked when the thread calls markReady().
	app->defineJoin(name_, this);
}

void BasicPthread::join()
{
	pthread_t tid;
	{
		pw::lockmutex lm(mutex_);
		tid = id_;
		id_ = 0;
	}
	if (tid != 0)
		pthread_join(tid, NULL);
}

void BasicPthread::interrupt()
{
	TrieadJoin::interrupt();
	{
		pw::lockmutex lm(mutex_);
		if (id_ != 0) {
			pthread_kill(id_, SIGUSR2);
		}
	}
}

void *BasicPthread::run_it(void *arg)
{
	// Keep the self-reference for the duration of the run
	Autoref<BasicPthread> self = (BasicPthread *)arg;
	self->selfref_ = NULL;
	Autoref<TrieadOwner> to = self->to_;
	self->to_ = NULL;

	self->mutex_.lock(); // makes sure that defineJoin() is completed
	self->mutex_.unlock();

	try {
		self->execute(to);
	} catch (Exception e) {
		to->abort(e.getErrors()->print());
	}

	if (!to->get()->isReady()) {
		to->abort("thread execution completed without marking it as ready");
	}

	to->markDead();
	return NULL;
}

}; // TRICEPS_NS
