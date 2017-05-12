//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// The Application class that manages the threads. There may be multiple
// Apps in one program, each with a different name.

#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <app/App.h>
#include <app/TrieadOwner.h>
#include <app/Nexus.h>

namespace TRICEPS_NS {

// -------------------- App::TrieadUpd -----------------------------------

void App::TrieadUpd::broadcastL(const string &appname)
{
	int err = cond_.broadcast();
	if (err != 0)
		throw Exception::fTrace("Internal error: condvar broadcast failed in application '%s', errno=%d: %s.", 
			appname.c_str(), err, strerror(err));
}

void App::TrieadUpd::waitL(const string &appname, const string &tname, const timespec &abstime)
{
	while (true) {
		// abstime is a reference to the App::dealine_, so if it changes, the
		// new value will be seen at the reference
		timespec limit = abstime;
		int err = cond_.timedwait(limit);
		if (err != 0) {
			if (err == ETIMEDOUT) {
				if (memcmp(&abstime, &limit, sizeof(timespec)))
					continue; // the deadline has been updated
				throw Exception::fTrace("Thread '%s' in application '%s' did not initialize within the deadline.", 
					tname.c_str(), appname.c_str());
			} else 
				throw Exception::fTrace("Internal error: condvar wait for thread '%s' in application '%s' failed, errno=%d: %s.", 
					tname.c_str(), appname.c_str(), err, strerror(err));
		}
		break;
	}
}

Erref App::TrieadUpd::interruptL()
{
	Erref err;

	if (interrupted_)
		return err;

	if (j_) { // interrupt in case if it's sleeping on input
		try {
			j_->interrupt();
		} catch (Exception e) {
			err = e.getErrors();
		}
	}

	interrupted_ = true;
	return err;
}

int App::TrieadUpd::_countSleepersL()
{
	return cond_.sleepers_;
}

// -------------------- App ----------------------------------------------

App::Map App::apps_;
pw::pmutex App::apps_mutex_;

Onceref<App> App::make(const string &name)
{
	pw::lockmutex lm(apps_mutex_);

	Map::iterator it = apps_.find(name);
	if (it != apps_.end())
		throw Exception::fTrace("Duplicate Triceps application name '%s' is not allowed.", name.c_str());

	App *a = new App(name);
	apps_[name] = a;
	return a;
}

Onceref<App> App::find(const string &name)
{
	pw::lockmutex lm(apps_mutex_);

	Map::iterator it = apps_.find(name);
	if (it == apps_.end())
		throw Exception::fTrace("Triceps application '%s' is not found.", name.c_str());

	return it->second;
}

void App::listApps(Map &ret)
{
	pw::lockmutex lm(apps_mutex_);

	if (!ret.empty())
		ret.clear();

	// copy a snapshot of the apps map to the return value
	for (Map::iterator it = apps_.begin(); it != apps_.end(); ++it)
		ret.insert(*it);
}

void App::drop(Onceref<App> app)
{
	pw::lockmutex lm(apps_mutex_);

	Map::iterator it = apps_.find(app->name_);
	if (it == apps_.end())
		return;
	if (it->second != app)
		return;
	apps_.erase(it);
}

App::App(const string &name) :
	name_(name),
	ready_(true), // since no threads are unready
	dead_(true), // since no threads are alive
	needHarvest_(true), // "dead" also implies being ready to harvest
	timeout_(DEFAULT_TIMEOUT),
	unreadyCnt_(0),
	aliveCnt_(0),
	shutdown_(false),
	drain_(new DrainApp),
	drainExcept_(NULL),
	drainCnt_(0)
{
	computeDeadlineL(timeout_);
}

App::~App()
{
	// avoid leaking the descriptors on App failures
	for (FdMap::iterator it = fdMap_.begin(); it != fdMap_.end(); ++it)
		close(it->second.fd_);
}

void App::setTimeout(int sec, int fragsec)
{
	pw::lockmutex lm(mutex_);
	if (!threads_.empty()) // XXX this might be not the best idea with frags
		throw Exception::fTrace("Triceps application '%s' deadline can not be changed after the thread creation.", name_.c_str());
	computeDeadlineL(sec);
	timeout_ = fragsec < 0? sec : fragsec;
}

void App::setDeadline(const timespec &dl)
{
	pw::lockmutex lm(mutex_);
	if (!threads_.empty()) // XXX this might be not the best idea with frags
		throw Exception::fTrace("Triceps application '%s' deadline can not be changed after the thread creation.", name_.c_str());
	deadline_ = dl;
}

void App::refreshDeadline()
{
	pw::lockmutex lm(mutex_); // needed for the thread count check
	refreshDeadlineL(timeout_);
}

void App::computeDeadlineL(int sec)
{
	int err = clock_gettime(CLOCK_REALTIME, &deadline_); // the current time
	if (err != 0) {
		throw Exception::fTrace("Triceps internal error: clock_gettime() failed: err=%d %s.", 
			err, strerror(err));
	}
	deadline_.tv_sec += sec;
}

void App::refreshDeadlineL(int sec)
{
	timespec newdl;

	int err = clock_gettime(CLOCK_REALTIME, &newdl); // the current time
	if (err != 0) {
		throw Exception::fTrace("Triceps internal error: clock_gettime() failed: err=%d %s.", 
			err, strerror(err));
	}
	newdl.tv_sec += sec;
	if (newdl.tv_sec > deadline_.tv_sec
	|| (newdl.tv_sec == deadline_.tv_sec && newdl.tv_nsec > deadline_.tv_nsec))
		deadline_ = newdl;
}

bool App::isAborted() const
{
	pw::lockmutex lm(mutex_);
	return isAbortedL();
}

string App::getAbortedBy() const
{
	pw::lockmutex lm(mutex_);
	string s = abortedBy_;
	return s;
}

string App::getAbortedMsg() const
{
	pw::lockmutex lm(mutex_);
	string s = abortedMsg_;
	return s;
}

bool App::isDead()
{
	return (dead_.trywait() == 0);
}

void App::waitDead()
{
	dead_.wait();
}

void App::shutdown()
{
	pw::lockmutex lm(mutex_);
	shutdownL();
}

void App::shutdownL()
{
	Erref err;
	if (!shutdown_) {
		shutdown_ = true;
		for (TrieadUpdMap::iterator it = threads_.begin(); it != threads_.end(); ++it) {
			Triead *t = it->second->t_;
			if (t->isReady()) {
				t->requestDead();
				err.fAppend(it->second->interruptL(), 
					"Failed to interrupt the thread '%s' of application '%s':",
					it->first.c_str(), name_.c_str());
			}
		}
	}
	if (!err.isNull())
		throw Exception(err, false);
}

void App::shutdownFragment(const string &fragname)
{
	pw::lockmutex lm(mutex_);
	shutdownFragmentL(fragname);
}

void App::shutdownFragmentL(const string &fragname)
{
	Erref err;
	// first check that all the threads in the fragment are ready, or a real bad
	// race would result with possibly other threads waiting on these threads...
	for (TrieadUpdMap::iterator it = threads_.begin(); it != threads_.end(); ++it) {
		Triead *t = it->second->t_;
		if (t->fragment() == fragname && !t->isReady())
			throw Exception::fTrace("Can not shut down the application '%s' fragment '%s': its thread '%s' is not ready yet.",
				name_.c_str(), fragname.c_str(), it->first.c_str());
	}
	TrieadUpdMap::iterator itnext;
	for (TrieadUpdMap::iterator it = threads_.begin(); it != threads_.end(); it = itnext) {
		Triead *t = it->second->t_;
		itnext = it;
		++itnext; // because the entry at iterator might get disposed of
		if (t->fragment() == fragname) {
			it->second->dispose_ = true;
			t->requestDead();
			err.fAppend(it->second->interruptL(), 
				"Failed to interrupt the thread '%s' of application '%s':",
				it->first.c_str(), name_.c_str());
			if (it->second->joined_) // already marked dead and joined
				disposeL(t->getName());
		}
	}
	if (!err.isNull())
		throw Exception(err, false);
}

void App::disposeL(const string &tname)
{
	TrieadUpdMap::iterator it = threads_.find(tname);
	if (it == threads_.end())
		return;
	if (!it->second->dispose_)
		return; // another thread created with the same name?
	threads_.erase(it); // dispose of it
}

bool App::isShutdown()
{
	pw::lockmutex lm(mutex_);
	return shutdown_;
}

Onceref<TrieadOwner> App::makeTriead(const string &tname, const string &fragname)
{
	if (tname.empty())
		throw Exception::fTrace("Empty thread name is not allowed, in application '%s'.", name_.c_str());

	pw::lockmutex lm(mutex_);

	TrieadUpdMap::iterator it = threads_.find(tname);
	TrieadUpd *upd;
	if (it == threads_.end()) {
		upd = new TrieadUpd(mutex_);
		threads_[tname] = upd;
		if (++unreadyCnt_ == 1 && !isAbortedL())
			ready_.reset();
		if (++aliveCnt_ == 1)
			dead_.reset();
	} else {
		upd = it->second;
		if(!upd->t_.isNull())
			throw Exception::fTrace("Duplicate thread name '%s' is not allowed, in application '%s'.", 
				tname.c_str(), name_.c_str());
	}

	Triead *th = new Triead(tname, fragname, drain_);
	TrieadOwner *ow = new TrieadOwner(this, th);
	upd->t_ = th;

	refreshDeadlineL(timeout_);

	return ow; // the only owner API for the thread!
}

void App::declareTriead(const string &tname)
{
	if (tname.empty())
		throw Exception::fTrace("Empty thread name is not allowed, in application '%s'.", name_.c_str());

	pw::lockmutex lm(mutex_);
	TrieadUpdMap::iterator it = threads_.find(tname);
	if (it == threads_.end()) {
		threads_[tname] = new TrieadUpd(mutex_);
		if (++unreadyCnt_ == 1 && !isAbortedL())
			ready_.reset();
		if (++aliveCnt_ == 1)
			dead_.reset();

		refreshDeadlineL(timeout_);
	} // else just do nothing
}

void App::defineJoin(const string &tname, Onceref<TrieadJoin> j)
{
	pw::lockmutex lm(mutex_);

	TrieadUpdMap::iterator it = threads_.find(tname);
	if (it == threads_.end()) {
		throw Exception::fTrace("In Triceps application '%s' can not define a join for an unknown thread '%s'.", 
			name_.c_str(), tname.c_str());
	}
	TrieadUpd *upd = it->second.get();
	if (upd->joining_ || upd->joined_) {
		throw Exception::fTrace("In Triceps application '%s' can not define a join for thread '%s' after it has been already joined.", 
			name_.c_str(), tname.c_str());
	}
	upd->j_ = j;
}

void App::getTrieads(TrieadMap &ret) const
{
	if (!ret.empty())
		ret.clear();

	pw::lockmutex lm(mutex_);

	for (TrieadUpdMap::const_iterator it = threads_.begin(); it != threads_.end(); ++it) {
		ret[it->first] = it->second->t_;
	}
}

void App::assertNotAbortedL() const
{
	if (!abortedBy_.empty())
		throw Exception::fTrace("App '%s' has been aborted by thread '%s': %s",
			name_.c_str(), abortedBy_.c_str(), abortedMsg_.c_str());
}

App::TrieadUpd *App::assertTrieadL(Triead *th) const
{
	TrieadUpdMap::const_iterator it = threads_.find(th->getName());
	if (it == threads_.end()) {
		throw Exception::fTrace("Thread '%s' does not belong to the application '%s'.",
			th->getName().c_str(), name_.c_str());
	}
	if (it->second->t_.get() != th) {
		throw Exception::fTrace("Thread '%s' does not belong to the application '%s', it's same-names but from another app.",
			th->getName().c_str(), name_.c_str());
	}
	return it->second;
}

void App::abortBy(const string &tname, const string &msg)
{
	pw::lockmutex lm(mutex_);

	abortByL(tname, msg);
}

void App::abortByL(const string &tname, const string &msg)
{
	// mark the thread as dead
	TrieadUpdMap::iterator it = threads_.find(tname);
	if (it != threads_.end()) {
		markTrieadDeadL(it->second, it->second->t_);
	}

	if (isAbortedL()) // already aborted, nothing more to do
		return;

	abortedBy_ = tname; // mark as aborted
	abortedMsg_ = msg;

	shutdownL(); // in case if some threads are already running, shut all of them down

	// now wake up all the sleepers
	ready_.signal();
	needHarvest_.signal();
	for (TrieadUpdMap::iterator it = threads_.begin(); it != threads_.end(); ++it) {
		it->second->broadcastL(name_);
	}
}

App::TrieadUpd *App::assertTrieadOwnerL(TrieadOwner *to) const
{
	return assertTrieadL(to->get());
}

Onceref<Triead> App::findTriead(TrieadOwner *to, const string &tname, bool immed)
{
	pw::lockmutex lm(mutex_);

	assertNotAbortedL();
	// reference guarantees that it won't disappear when sleeping
	Autoref<TrieadUpd> selfupd = assertTrieadOwnerL(to);

	// A special short-circuit for the self-reference, a thread can
	// find itself even if it's not fully constructed.
	if (to->get()->getName() == tname)
		return to->get();

	if (selfupd->waitFor_ != NULL)
		throw Exception::fTrace("In Triceps application '%s' thread '%s' owner object must not be used from 2 OS threads.",
			name_.c_str(), to->get()->getName().c_str());

	TrieadUpdMap::iterator it = threads_.find(tname);
	if (it == threads_.end())
		throw Exception::fTrace("In Triceps application '%s' thread '%s' is referring to a non-existing thread '%s'.",
			name_.c_str(), to->get()->getName().c_str(), tname.c_str());

	Autoref <TrieadUpd> upd = it->second;

	if (upd->dispose_) // disposed is the same as non-existing
		throw Exception::fTrace("In Triceps application '%s' thread '%s' is referring to a non-existing thread '%s'.",
			name_.c_str(), to->get()->getName().c_str(), tname.c_str());

	Triead *t = upd->t_;
	if (t != NULL && (immed || t->isConstructed()))
		return t;

	if (immed)
		throw Exception::fTrace("In Triceps application '%s' thread '%s' did an immediate find of a declared but undefined thread '%s'.",
			name_.c_str(), to->get()->getName().c_str(), tname.c_str());

	// Make sure that won't deadlock: go through the dependency
	// chain and ensure that it doesn't return back to our thread.
	// Doing it once up front is enough, because afterwards the responsibility
	// of the deadlock detection will be on the new sleepers.
	for (TrieadUpd *p = upd; p != NULL; p = p->waitFor_) {
		if (p == selfupd.get()) {
			// print the list of dependencies, it repeats the same loop
			Erref deps;
			for (TrieadUpd *pp = upd; pp != selfupd.get(); pp = pp->waitFor_)
				deps.f("%s waits for %s", pp->t_->getName().c_str(), pp->waitFor_->t_->getName().c_str());
			throw Exception::fTrace(deps,
				"In Triceps application '%s' thread '%s' waiting for thread '%s' would cause a deadlock:",
							name_.c_str(), to->get()->getName().c_str(), tname.c_str());
		}
	}

	selfupd->waitFor_ = upd;
	try {
		do {
			upd->waitL(name_, tname, deadline_); // will throw on timeout
			t = upd->t_;
		} while (!isAbortedL() && (t == NULL || !t->isConstructed()));
		selfupd->waitFor_ = NULL;
	} catch (...) {
		selfupd->waitFor_ = NULL;
		throw;
	}

	assertNotAbortedL();
	return t;
}

Onceref<Nexus> App::findNexus(TrieadOwner *to, const string &tname, const string &nexname, bool immed)
{
	// No App mutex! findTriead() takes care of that.
	Autoref<Triead> t = findTriead(to, tname, immed); // uses App mutex
	return t->findNexus(to->get()->getName(), name_, nexname); // uses Triead mutex
}

void App::markTrieadConstructed(TrieadOwner *to)
{
	pw::lockmutex lm(mutex_);

	Triead *t = to->get();
	TrieadUpd *upd = assertTrieadL(t);

	markTrieadConstructedL(upd, t);
}

void App::markTrieadConstructedL(TrieadUpd *upd, Triead *t)
{
	if (!t->isConstructed()) {
		t->markConstructed();
		upd->broadcastL(name_);
	}
}

void App::markTrieadReady(TrieadOwner *to)
{
	pw::lockmutex lm(mutex_);

	Triead *t = to->get();
	TrieadUpd *upd = assertTrieadL(t);

	markTrieadConstructedL(upd, t);
	markTrieadReadyL(upd, t);
}

void App::markTrieadReadyL(TrieadUpd *upd, Triead *t)
{
	if (!t->isReady()) {
		t->markReady();
		if (drainCnt_ && t != drainExcept_)
			t->drain();

		--unreadyCnt_;

		if (shutdown_) {
			t->requestDead(); // this thread was too late to the party

			Erref err;
			err.fAppend(upd->interruptL(), 
				"Failed to interrupt the thread '%s' of application '%s':",
				t->getName().c_str(), name_.c_str());
			if (err->hasError())
				throw Exception(err, false);
		}

		if (unreadyCnt_ == 0) {
			ready_.signal();
			// XXX if the error is in a fragment, this would still abort the whole app
			checkLoopsL(t->getName());
			// since the initialization is completed, drop the deadline timeout to 0
			computeDeadlineL(0);
		}
	}
}

void App::markTrieadDead(TrieadOwner *to)
{
	pw::lockmutex lm(mutex_);

	Triead *t = to->get();

	TrieadUpdMap::const_iterator it = threads_.find(t->getName());
	if (it == threads_.end())
		return; // silently ignore because might be already disposed of
	TrieadUpd *upd = it->second;
	if (upd->t_.get() != t)
		return; // silently ignore because might be already disposed of

	markTrieadConstructedL(upd, t);
	try {
		// XXX if aborting on exception, the catch won't help
		markTrieadReadyL(upd, t);
	} catch (Exception e) {
		// Just ignore, marking the App aborted is good enough.
		// After all, the current thread is about to exit anyway
		// and might even be calling this from its destructor,
		// so there is no need to make its life more difficult.
	}
	markTrieadDeadL(upd, t);
}

void App::markTrieadDeadL(TrieadUpd *upd, Triead *t)
{
	if (!t->isDead()) {
		t->markDead();
		if (--aliveCnt_ == 0) {
			dead_.signal();
			needHarvest_.signal();
		}

		if (upd->j_) {
			zombies_.push_back(upd);
			needHarvest_.signal();
		} else {
			upd->joined_ = upd->joining_ = true;
			if (upd->dispose_)
				disposeL(upd->t_->getName());
		}
	}
}

bool App::harvestOnce()
{
	while(true) {
		Autoref<TrieadUpd> upd;
		Autoref<TrieadJoin> j;
		{
			pw::lockmutex lm(mutex_);
			if (zombies_.empty()) {
				bool dead = isDead();
				if (!dead)
					needHarvest_.reset();
				return dead;
			}
			upd = zombies_.front();
			j = upd->j_;

			if (j.isNull() || upd->joining_) // j should never be NULL but just in case
				continue; // a duplicate, ignore it

			upd->joining_ = true;
			zombies_.pop_front();
		}

		// this part must happen outside mutex
		Erref err;
		try {
			j->join();
		} catch (Exception e) {
			err = e.getErrors();
		}

		{
			pw::lockmutex lm(mutex_);
			upd->joined_ = true;
			upd->j_ = NULL; // drop the reference
			if (upd->dispose_)
				disposeL(upd->t_->getName());
		}
		
		if (err->hasError())
			// j still keeps a reference, so it's OK to refer by it
			throw Exception::f(err, "Failed to join the thread '%s' of application '%s':",
						j->getName().c_str(), name_.c_str());
	}
}

void App::waitNeedHarvest()
{
	needHarvest_.wait();
}

void App::harvester(bool throwAbort)
{
	string appName, abThread, abMsg;
	Erref err;

	bool dead = false;
	while (!dead) {
		waitNeedHarvest();
		try {
			dead = harvestOnce();
		} catch (Exception e) {
			if (err.isNull())
				err = new Errors;
			err->absorb(e.getErrors());
		}
	}
	appName = name_;
	abThread = abortedBy_;
	abMsg = abortedMsg_;
	drop(this);

	if (throwAbort && !abThread.empty())
		err.f("App '%s' has been aborted by thread '%s': %s",
			appName.c_str(), abThread.c_str(), abMsg.c_str());

	if (err->hasError())
		throw Exception(err, false);
}

bool App::isReady()
{
	return (ready_.trywait() == 0);
}

void App::waitReady()
{
	{
		pw::lockmutex lm(mutex_);
		assertNotAbortedL();
	}

	while (true) {
		timespec limit = deadline_;
		int err = ready_.timedwait(limit);
		if (err != 0) {
			if (err == ETIMEDOUT) {
				if (memcmp(&deadline_, &limit, sizeof(timespec)))
					continue; // the deadline has changed, try again
				Erref lags;
				{
					pw::lockmutex lm(mutex_); // reading the list must be protected
					for (TrieadUpdMap::iterator it = threads_.begin(); it != threads_.end(); ++it) {
						Triead *t = it->second->t_;
						if (t == NULL) {
							lags.f("%s: not defined", it->first.c_str());
						} else if (!t->isConstructed()) {
							lags.f("%s: not constructed", it->first.c_str());
						} else if (!t->isReady()) {
							lags.f("%s: not ready", it->first.c_str());
						}
					}
				}
				throw Exception::fTrace(lags,
					"Application '%s' did not initialize within the deadline.\nThe lagging threads are:", name_.c_str());
			} else  {
				throw Exception::fTrace("Internal error: condvar wait for all-ready in application '%s' failed, errno=%d: %s.", 
					name_.c_str(), err, strerror(err));
			}
		}
		break;
	}

	{
		pw::lockmutex lm(mutex_);
		assertNotAbortedL();
	}
}

void App::requestDrain()
{
	drainRw_.rdlock();
	requestDrainCommon(NULL);
}

void App::requestDrainExclusive(TrieadOwner *to)
{
	drainRw_.wrlock();
	requestDrainCommon(to->get());
}

void App::requestDrainCommon(Triead *exct)
{
	pw::lockmutex lm(mutex_);

	drainExcept_ = exct;

	if (++drainCnt_ == 1) {
		drain_->init();
		for (TrieadUpdMap::iterator it = threads_.begin(); it != threads_.end(); ++it) {
			Triead *t = it->second->t_;
			if (t != NULL && t != drainExcept_ && t->isReady())
				t->drain();
		}
		drain_->initDone();
	}
}

void App::waitDrain()
{
	// no app mutex!

	drain_->wait();
}

bool App::isDrained()
{
	return drain_->isDrained();
}

void App::undrain()
{
	{
		pw::lockmutex lm(mutex_);

		if (--drainCnt_ == 0) {
			for (TrieadUpdMap::iterator it = threads_.begin(); it != threads_.end(); ++it) {
				Triead *t = it->second->t_;
				if (t != NULL && t != drainExcept_ && t->isReady())
					t->undrain();
			}
		}
	}
	drainRw_.unlock();
}

void App::storeFd(const string &name, int fd)
{
	pw::lockmutex lm(mutex_);
	
	FdMap::iterator it = fdMap_.find(name);
	if (it != fdMap_.end())
		throw Exception::f("store of duplicate descriptor '%s', new fd=%d, existing fd=%d", 
			name.c_str(), fd, it->second.fd_);
	fdMap_[name] = FdInfo(fd);
}

void App::storeFd(const string &name, int fd, const string &className)
{
	pw::lockmutex lm(mutex_);
	
	FdMap::iterator it = fdMap_.find(name);
	if (it != fdMap_.end())
		throw Exception::f("store of duplicate descriptor '%s', new fd=%d, existing fd=%d", 
			name.c_str(), fd, it->second.fd_);
	fdMap_[name] = FdInfo(fd, className);
}

int App::loadFd(const string &name, string *className) const
{
	pw::lockmutex lm(mutex_);
	FdMap::const_iterator it = fdMap_.find(name);
	if (it != fdMap_.end()) {
		if (className != NULL)
			*className = it->second.class_;
		return it->second.fd_;
	} else
		return -1;
}

bool App::forgetFd(const string &name)
{
	pw::lockmutex lm(mutex_);
	FdMap::iterator it = fdMap_.find(name);
	if (it != fdMap_.end()) {
		fdMap_.erase(it);
		return true;
	} else 
		return false;
}

bool App::closeFd(const string &name)
{
	pw::lockmutex lm(mutex_);
	FdMap::iterator it = fdMap_.find(name);
	if (it != fdMap_.end()) {
		errno = 0;
		close(it->second.fd_);
		fdMap_.erase(it);
		return true;
	} else 
		return false;
}

void App::checkLoopsL(const string &tname)
{
	Graph gdown, gup; // separate graphs for direct and reverse nexuses
	Triead::FacetMap nmap;
	NxTr *tnode, *nnode;

	// first build the graphs, separately for the downwards and upwards links
	for (TrieadUpdMap::const_iterator it = threads_.begin(); it != threads_.end(); ++it) {
		Triead *t = it->second->t_;

		t->facets(nmap);
		for (Triead::FacetMap::iterator jt = nmap.begin(); jt != nmap.end(); ++jt) {
			Facet *fa = jt->second;
			if (fa->isReverse()) {
				tnode = gup.addTriead(t);
				nnode = gup.addNexus(fa->nexus());
			} else {
				tnode = gdown.addTriead(t); 
				nnode = gdown.addNexus(fa->nexus());
			}
			// create graphs in opposite direction, because the logic later will
			// require reversing the graph, and the printout of the loops will 
			// go from the reversed graph
			if (fa->isWriter()) {
				nnode->addLink(tnode);
			} else {
				tnode->addLink(nnode);
			}
		}
	}
	try {
		reduceCheckGraphL(gdown, "direct");
		reduceCheckGraphL(gup, "reverse");
	} catch (Exception e) {
		abortByL(tname, e.getErrors()->print());
		throw;
	}
}

void App::reduceCheckGraphL(Graph &g, const char *direction) const
{
	reduceGraphL(g);

	// Now whatever links left represent the loops and any twigs coming from them.
	// To get rid of the twigs, the graph has to be traversed backwards
	// but there are no backwards links.
	// So create a backwards copy of the graph (skipping the nodes that
	// have become disconnected) and then reduce it.
	Graph backg;
	for (Graph::List::iterator it = g.l_.begin(); it != g.l_.end(); ++it) {
		NxTr *node = *it;
		if (node->links_.empty())
			continue;
		NxTr *ncopy = backg.addCopy(node);
		for (NxTr::List::iterator jt = node->links_.begin(); jt != node->links_.end(); ++jt) {
			backg.addCopy(*jt)->addLink(ncopy);
		}
	}

	reduceGraphL(backg);
	checkGraphL(backg, direction);
}


void App::checkGraphL(Graph &g, const char *direction) const
{
	// Whatever is left now will contain the loops in it.  So just print one
	// loop by always following the first link and always starting from a
	// thread.  It might be better to print all the loops but not terribly
	// important.
	for (Graph::List::iterator it = g.l_.begin(); it != g.l_.end(); ++it) {
		NxTr *node = *it;
		if (node->ninc_ != 0) {
			// printf("DEBUG ---\n");
			// Found a loop, walk it. However the simple walk might never
			// return back to the starting point, so first walk and mark,
			// and then after found a return to a marked point, print from there.
			for (; !node->mark_; node = node->links_.front()) {
				// printf("DEBUG marking %s\n", node->print().c_str());
				node->mark_ = true;
			}
			// printf("DEBUG looped at %s\n", node->print().c_str());

			// for printing, start with the thread, not nexus
			if (node->tr_ == NULL) {
				// printf("DEBUG stepped to %s\n", node->print().c_str());
				node = node->links_.front();
			}

			// print it from this point
			Erref eloop = new Errors;
			eloop->appendMsg(true, node->print());
			for (NxTr *cur = node->links_.front(); cur != node; cur = cur->links_.front())
				eloop->appendMsg(true, cur->print());
			eloop->appendMsg(true, node->print()); // repeat the initial node to emphasise the loop
			throw Exception::fTrace(eloop, "In application '%s' detected an illegal %s loop:",
				name_.c_str(), direction);
		}
	}
}

void App::reduceGraphL(Graph &g)
{
	typedef list<NxTr *> Nlist;
	Nlist todo; // list of starting-point nodes

	// The graph is a general tree, so there may be many starting points.
	// As we traverse the graph, more untraversed starting points will appear.
	// We traverse until we run out of starting points.
	// The starting points are found by the condition ninc_==0.
	// As the links are traversed, they get deleted and more starting points
	// may appear, which again get included into the traversal.
	// If after traversing from all the starting points there still are
	// untraversed links, it means that the loops are present.

	// Find the initial set of starting points.
	for (Graph::List::iterator it = g.l_.begin(); it != g.l_.end(); ++it) {
		NxTr *node = *it;
		// printf("DEBUG inspect %s in %d out %d\n", node->print().c_str(), node->ninc_, (int)node->links_.size());
		if (!node->links_.empty() && node->ninc_ == 0) {
			// printf("DEBUG push initial todo %s\n", node->print().c_str());
			todo.push_back(node);
		}
	}

	// now traverse
	while (!todo.empty()) {
		NxTr *cur = todo.front();
		// printf("DEBUG processing todo %s\n", cur->print().c_str());
		NxTr *next = cur->links_.front();
		cur->links_.pop_front();
		if (cur->links_.empty()) {
			// printf("DEBUG pop todo %s\n", cur->print().c_str());
			todo.pop_front(); // that was the last link from it, don't return there
		}
		
		// A minor optimization: instead of pushing and popping the nodes in
		// a sequece on the todo list, just follow it through until
		// the path comes to a Y-join.
		while (1) {
			cur = next;
			// printf("DEBUG following %s\n", cur->print().c_str());
			// decrement because an incoming connection has just been consumed
			if (--cur->ninc_ != 0) {
				// printf("DEBUG stop at join %s\n", cur->print().c_str());
				break; // found a join
			}
			if (cur->links_.empty()) {
				// printf("DEBUG leaf at %s\n", cur->print().c_str());
				break; // found an endpoint
			}

			next = cur->links_.front();
			cur->links_.pop_front();
			if (!cur->links_.empty()) {
				// printf("DEBUG push todo %s\n", cur->print().c_str());
				todo.push_back(cur); // more links from it, come back to it later
			}
		}
	}
}

//---------------------------- App::NxTr -------------------------------------

App::NxTr::NxTr(Triead *tr):
	tr_(tr),
	nx_(NULL),
	ninc_(0),
	mark_(false)
{ }

App::NxTr::NxTr(Nexus *nx):
	tr_(NULL),
	nx_(nx),
	ninc_(0),
	mark_(false)
{ }

App::NxTr::NxTr(const NxTr &nxtr):
	tr_(nxtr.tr_),
	nx_(nxtr.nx_),
	ninc_(0), // a fresh copied node has no links
	mark_(false)
{ }

void App::NxTr::addLink(NxTr *target)
{
	links_.push_back(target);
	target->ninc_++;
}

string App::NxTr::print() const
{
	if (nx_ != NULL)
		return strprintf("nexus '%s/%s'", nx_->getTrieadName().c_str(), nx_->getName().c_str());
	else
		return strprintf("thread '%s'", tr_->getName().c_str());
}

//---------------------------- App::Graph ------------------------------------

App::NxTr *App::Graph::addTriead(Triead *tr)
{
	Map::iterator it = m_.find(tr);
	if (it == m_.end()) {
		NxTr *node = new NxTr(tr);
		m_[tr] = node;
		l_.push_back(node);
		return node;
	} else
		return it->second;
}
App::NxTr *App::Graph::addNexus(Nexus *nx)
{
	Map::iterator it = m_.find(nx);
	if (it == m_.end()) {
		NxTr *node = new NxTr(nx);
		m_[nx] = node;
		l_.push_back(node);
		return node;
	} else
		return it->second;
}

App::NxTr *App::Graph::addCopy(NxTr *nxtr)
{
	Map::iterator it = m_.find(nxtr);
	if (it == m_.end()) {
		NxTr *node = new NxTr(*nxtr);
		m_[nxtr] = node;
		l_.push_back(node);
		return node;
	} else
		return it->second;
}

}; // TRICEPS_NS

