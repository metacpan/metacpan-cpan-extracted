// This file is a part of Pthreads Wrapper library.
// See the accompanying COPYRIGHT file for the copyright notice and license.
// Adapted from tpopp-examples-100329.

#include <stdio.h>
#include <stdlib.h>
#include <pw/ptwrap.h>
#include <pw/ptwrap2.h>

namespace TRICEPS_NS {

namespace pw // POSIX wrapped
{

// pwthread

	void pwthread::start()
	{
		start_mutex_.lock();
		pthread_create(&id_, attr_, run_it, 
			(void *)this);
		if (detached_)
			pthread_detach(id_);
		start_mutex_.unlock();
	}

	void *pwthread::run_it(void *arg)
	{
		pwthread *t = (pwthread *)arg;

		t->start_mutex_.lock();
		t->start_mutex_.unlock();

		void *result = t->execute();
		if (t->detached_) {
			// must delete own object since nobody else
			// can collect it
			delete t;
		}
		return result;
	}

// semaphore

	int semaphore::wait(unsigned n)
	{
		pw::lockmutex lm(leadcond_);
		while(leadn_) 
			restcond_.wait();

		leadn_ = n;
		while(value_ < n)
			leadcond_.wait();
		value_ -= n;
		leadn_ = 0;
		restcond_.signal();
		return 0;
	}
	int semaphore::trywait(unsigned n)
	{
		pw::lockmutex lm(leadcond_);
		if(leadn_ || value_ < n)
			return ETIMEDOUT;
		value_ -= n;
		return 0;
	}
	int semaphore::timedwait(unsigned n, 
			const struct timespec &abstime)
	{
		pw::lockmutex lm(leadcond_);
		while(leadn_) {
			if (restcond_.timedwait(abstime) == ETIMEDOUT)
				return ETIMEDOUT;
		}

		leadn_ = n;
		while(value_ < n) {
			if (leadcond_.timedwait(abstime) == ETIMEDOUT) {
				leadn_ = 0;
				restcond_.signal();
				return ETIMEDOUT;
			}
		}
		value_ -= n;
		leadn_ = 0;
		restcond_.signal();
		return 0;
	}
// DEBUG to
	// ...
	int semaphore::signal(unsigned n)
	{
		pw::lockmutex lm(leadcond_);
		value_ += n;
		if (leadn_ && value_ >= leadn_)
			leadcond_.signal();
		return value_;
	}

// autoevent

	int autoevent::timedwait(const struct timespec &abstime)
	{
		pw::lockmutex lm(cond_);
		++evsleepers_;
		while (!signaled_) {
			if (cond_.timedwait(abstime) == ETIMEDOUT) {
				--evsleepers_;
				if (signaled_) {
					signaled_ = false;
					return 0;
				} else {
					return ETIMEDOUT;
				}
			}
		}
		--evsleepers_;
		signaled_ = false;
		return 0;
	}

// autoevent2

	int autoevent2::timedwaitL(const struct timespec &abstime)
	{
		++evsleepers_;
		while (!signaled_) {
			if (cond_.timedwait(abstime) == ETIMEDOUT) {
				--evsleepers_;
				if (signaled_) {
					signaled_ = false;
					return 0;
				} else {
					return ETIMEDOUT;
				}
			}
		}
		--evsleepers_;
		signaled_ = false;
		return 0;
	}

// splitlock

	bool splitlock::wait_for_worker(const struct timespec &abstime, 
		bool timed)
	{
		int res;

		pw::lockmutex lm(cond_enter_);
		while(true) {
			if (cond_enter_.sleepers_ > 0)
				// worker is already trying to enter
				return true; 

			switch(wi_) {
			case WORKER_WILL_ENTER:
				if (timed) {
					res = cond_worker_.timedwait(abstime);
					if (res == ETIMEDOUT)
						return false;
				} else {
					cond_worker_.wait();
				}
				break;
			case WORKER_WONT_ENTER:
				return false;
			case WORKER_MIGHT_ENTER:
				res = cond_worker_.timedwait(abstime);
				if (res == ETIMEDOUT 
				&& wi_ == WORKER_MIGHT_ENTER)
					return false;
				// else something definite became known,
				// parse this knowledge on the next
				// iteration
				break;
			};
		}
	}

// reftarget

// this pointer will be held in the weak references
reftarget::reftarget(void *owner) : 
	valid_(true), rlist_(0), owner_(owner)
{
}

reftarget::~reftarget()
{
	if (valid_) {
		fprintf(stderr, "~reftarget: not invalidated!\n");
		abort();
	}
}

// create a new weak reference
weakref *reftarget::newweakref() 
{
	weakref *wr;
	wr = new weakref(this);

	pw::lockmutex lm(mutex_);
	if (!valid_) {
		if (wr->invalidate1())
			wr->invalidate2();
	} else { // add to the list
		if (rlist_) {
			rlist_->prevp_ = &wr->next_;
		}
		wr->next_ = rlist_;
		wr->prevp_ = &rlist_;
		rlist_ = wr;
	}
	return wr;
}

// called from the subclass destructor
void reftarget::invalidate() 
{
	pw::lockmutex lm(mutex_);
	valid_ = false;
	while (rlist_) {
		weakref *wr = rlist_;
		rlist_ = rlist_->next_;
		if (rlist_)
			rlist_->prevp_ = &rlist_;
		wr->prevp_ = 0;
		wr->next_ = 0;
		bool code = wr->invalidate1();
		if (code) {
			pw::unlockmutex um(mutex_);
			wr->invalidate2();
		}
	}
	hold_.wait();
}

// notification from a weakref that it gets destroyed
void reftarget::freeweakref(weakref *wr) 
{
	// remove the ref from the list
	pw::lockmutex lm(mutex_);
	if (wr->prevp_) {
		*wr->prevp_ = wr->next_;
		if (wr->next_)
			wr->next_->prevp_ = wr->prevp_;
		wr->prevp_ = 0;
		wr->next_ = 0;
	}
}

// weakref

weakref::~weakref()
{
	int ngrabs = grabs_.get_hold_count();
	for (int i = 0; i < ngrabs; i++)
		grabs_.release();
	reftarget *t;
	{
		pw::lockmutex lm(mutex_);
		t = target_;
		target_ = 0;
		if (t)
			t->hold_.acquire();
	}
	hold_.wait();
	if (t) {
		t->freeweakref(this);
		t->hold_.release();
	}
}

// create a copy of this reference
weakref *weakref::copy() 
{
	weakref *nwr;
	grab();
	// target won't disappear but the reference may be
	// reset to 0, so make a local copy of it
	reftarget *t = target_;
	if (t)
		nwr = t->newweakref();
	else
		nwr = new weakref(0);
	release();
	return nwr;
}

// make the reference strong, return its current value
void *weakref::grab() 
{
	grabs_.acquire();
	void *owner;
	{
		pw::lockmutex lm(mutex_);
		owner = target_? target_->owner_ : 0;
	}
	return owner;
}

// release the reference back to weak
void weakref::release() 
{ 
	grabs_.release();
}

// called from copy() and from reftarget
weakref::weakref(reftarget *target) : 
	next_(0), prevp_(0), target_(target)
{
}

// called from reftarget invalidation
bool weakref::invalidate1() 
{
	pw::lockmutex lm(mutex_);
	reftarget *t = target_;
	target_ = 0;
	if (t)
		hold_.acquire();
	return (t != 0);
}

// called if invalidate1() returned true
void weakref::invalidate2() 
{
	grabs_.wait();
	hold_.release();
}

}; // pw

}; // TRICEPS_NS
