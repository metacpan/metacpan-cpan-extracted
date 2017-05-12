// This file is a part of Pthreads Wrapper library.
// See the accompanying COPYRIGHT file for the copyright notice and license.
// Adapted from tpopp-examples-100329.

#ifndef __Triceps_ptwrap_hpp__
#define __Triceps_ptwrap_hpp__

#include <common/Conf.h>

// DEBUG former ex01.cpp
//
// A simple wrapper of the POSIX thread functions in C++,
// since it doesn't provide for the more complex calls,
// it leaves the underlying Pthreads public.

#include <pthread.h>
#include <errno.h>
#include <set>

namespace TRICEPS_NS {

namespace pw // POSIX wrapped
{

// [[ex01aa]]
// DEBUG descr POSIX wrapper mutex class.
class pmutex 
{
public:
	pmutex(const pthread_mutexattr_t *attr = 0)
	{
		pthread_mutex_init(&mutex_, attr);
	}
	~pmutex()
	{
		pthread_mutex_destroy(&mutex_);
	}
	int lock()
	{
		return pthread_mutex_lock(&mutex_);
	}
	int trylock()
	{
		return pthread_mutex_trylock(&mutex_);
	}
	int unlock()
	{
		return pthread_mutex_unlock(&mutex_);
	}

	pthread_mutex_t mutex_;
};
// END

// a simple scoped lock and unlock
// [[ex01ab]]
// DEBUG descr POSIX wrapper scoped lock and unlock classes.
class lockmutex
{
public:
	lockmutex(pmutex &m) :
		mutex_(m)
	{
		mutex_.lock();
	}
	~lockmutex()
	{
		mutex_.unlock();
	}
protected:
	pmutex &mutex_;
};

class unlockmutex
{
public:
	unlockmutex(pmutex &m) :
		mutex_(m)
	{
		mutex_.unlock();
	}
	~unlockmutex()
	{
		mutex_.lock();
	}
protected:
	pmutex &mutex_;
};
// END

// [[ex01ac]]
// DEBUG descr POSIX wrapper mutex chaining class.
class swapmutex
{
public:
	swapmutex(pmutex &mold, pmutex &mnew) :
		mutexold_(mold), mutexnew_(mnew)
	{
		mutexnew_.lock();
		mutexold_.unlock();
	}
	~swapmutex()
	{
		mutexnew_.unlock();
		mutexold_.lock();
	}
protected:
	pmutex &mutexold_, &mutexnew_;
};
// END

// [[ex01ad]]
// DEBUG descr POSIX wrapper condition variable class.
class pcond
{
public:
	pcond(const pthread_condattr_t *attr = 0)
	{
		pthread_cond_init(&cond_, attr);
	}
	~pcond()
	{
		pthread_cond_destroy(&cond_);
	}
	int wait(pmutex *mutex)
	{
		return pthread_cond_wait(&cond_, 
			&mutex->mutex_);
	}
	int timedwait(pmutex *mutex, 
		const struct timespec &abstime)
	{
		return pthread_cond_timedwait(&cond_, 
			&mutex->mutex_, &abstime);
	}
	// expects that the mutex is already locked
	int signal()
	{
		return pthread_cond_signal(&cond_);
	}
	int broadcast()
	{
		return pthread_cond_broadcast(&cond_);
	}

	pthread_cond_t cond_;
};
// END

// a typical combination of a condition variable with a mutex and number of
// sleepers 
// (note that since it inherits from pmutex, the autolock/autounlock
// can be applied to it too!)
// [[ex01ae]]
// DEBUG descr POSIX wrapper condition variable class combined with a mutex.
class pmcond: public pmutex, public pcond
{
public:
	pmcond(const pthread_mutexattr_t *mattr = 0, 
			const pthread_condattr_t *cattr = 0) :
		pmutex(mattr), pcond(cattr),
		sleepers_(0)
	{ }
	// wait with the built-in mutex locked on entry
	// and exit (note that the sleepers counter
	// can't be kept right if using a pcond::wait
	// with a different mutex)
	int wait()
	{
		++sleepers_;
		int res = pcond::wait(this);
		return res;
	}
	int timedwait(const struct timespec &abstime)
	{
		++sleepers_;
		int res = pcond::timedwait(this, abstime);
		// don't decrease sleepers_, since it would 
		// cause a race
		return res;
	}

	// convenience wrappers that avoid the signaling
	// if there are no sleepers
	int signal()
	{
		int res = 0;
		if (sleepers_ > 0) {
			res = pthread_cond_signal(&cond_);
			--sleepers_;
		}
		return res;
	}
	int broadcast()
	{
		int res = 0;
		if (sleepers_ > 0) {
			res = pthread_cond_broadcast(&cond_);
			sleepers_ = 0;
		}
		return res;
	}
	// convenience wrappers that get the mutex 
	// before signaling
	int signallock()
	{
		lock();
		int res = signal();
		unlock();
		return res;
	}
	int broadcastlock()
	{
		lock();
		int res = broadcast();
		unlock();
		return res;
	}

	int sleepers_;
};
// END

// essentially a copy of pmcond but with an externally supplied mutex
// (that possibly belongs to some pmcond instance), this allows to chain
// multiple conditions off the same mutex
// [[ex01af]]
// DEBUG descr POSIX wrapper condition variable class sharing the mutex of another condition variable.
class pchaincond: public pcond
{
public:
	pchaincond(pmutex &mutex, 
			const pthread_condattr_t *cattr = 0) :
		pcond(cattr),
		mutex_(mutex), sleepers_(0)
	{ }
	int wait()
	{
		++sleepers_;
		int res = pcond::wait(&mutex_);
		return res;
	}
	int timedwait(const struct timespec &abstime)
	{
		++sleepers_;
		int res = pcond::timedwait(&mutex_, abstime);
		return res;
	}

	// convenience wrappers that avoid the signaling
	// if there are no sleepers
	int signal()
	{
		int res = 0;
		if (sleepers_ > 0) {
			res = pthread_cond_signal(&cond_);
			--sleepers_;
		}
		return res;
	}
	int broadcast()
	{
		int res = 0;
		if (sleepers_ > 0) {
			res = pthread_cond_broadcast(&cond_);
			sleepers_ = 0;
		}
		return res;
	}
	// convenience wrappers that get the mutex
	// before signaling
	int signallock()
	{
		mutex_.lock();
		int res = signal();
		mutex_.unlock();
		return res;
	}
	int broadcastlock()
	{
		mutex_.lock();
		int res = broadcast();
		mutex_.unlock();
		return res;
	}

	pmutex &mutex_;
	int sleepers_;
};
// END

// [[ex01ag]]
// DEBUG descr POSIX wrapper read-write lock class.
class prwlock 
{
public:
	prwlock(const pthread_rwlockattr_t *attr = 0)
	{
		pthread_rwlock_init(&rwlock_, attr);
	}
	~prwlock()
	{
		pthread_rwlock_destroy(&rwlock_);
	}
	int wrlock()
	{
		return pthread_rwlock_wrlock(&rwlock_);
	}
	int trywrlock()
	{
		return pthread_rwlock_trywrlock(&rwlock_);
	}
	int timedwrlock(const struct timespec &abstime)
	{
		return pthread_rwlock_timedwrlock(&rwlock_, 
			&abstime);
	}
	int rdlock()
	{
		return pthread_rwlock_rdlock(&rwlock_);
	}
	int tryrdlock()
	{
		return pthread_rwlock_tryrdlock(&rwlock_);
	}
	int timedrdlock(const struct timespec &abstime)
	{
		return pthread_rwlock_timedrdlock(&rwlock_, 
			&abstime);
	}
	int unlock()
	{
		return pthread_rwlock_unlock(&rwlock_);
	}

	pthread_rwlock_t rwlock_;
};

// a simple scoped lock and unlock for 
// read and write
class lockwr
{
public:
	lockwr(prwlock &l) :
		rwlock_(l)
	{
		rwlock_.wrlock();
	}
	~lockwr()
	{
		rwlock_.unlock();
	}
protected:
	prwlock &rwlock_;
};
class unlockwr
{
public:
	unlockwr(prwlock &l) :
		rwlock_(l)
	{
		rwlock_.unlock();
	}
	~unlockwr()
	{
		rwlock_.wrlock();
	}
protected:
	prwlock &rwlock_;
};
class lockrd
{
public:
	lockrd(prwlock &l) :
		rwlock_(l)
	{
		rwlock_.rdlock();
	}
	~lockrd()
	{
		rwlock_.unlock();
	}
protected:
	prwlock &rwlock_;
};
class unlockrd
{
public:
	unlockrd(prwlock &l) :
		rwlock_(l)
	{
		rwlock_.unlock();
	}
	~unlockrd()
	{
		rwlock_.rdlock();
	}
protected:
	prwlock &rwlock_;
};
// END

// [[ex01ah]]
// DEBUG descr POSIX wrapper thread class.
class pwthread
{
public:
	pwthread(bool detached = false, 
			pthread_attr_t *attr = 0) :
		detached_(detached), attr_(attr), id_(0)
	{ }
	virtual ~pwthread()
	{ }

	void set_attr(pthread_attr_t *attr)
	{
		attr_ = attr;
	}

	pthread_t get_id()
	{
		return id_;
	}

	virtual void *execute()
	{
		return 0;
	}

	// makes no checks if the thread is already
	// running, the caller must be careful
	void start(); // DEBUG moved to ptwrap.cpp

	// join may be called only once for non-detached
	// threads, and  only after the thread had been
	// started
	void *join()
	{
		void *result;
		pthread_join(id_, &result);
		return result;
	}

protected:
	static void *run_it(void *arg); // DEBUG moved to ptwrap.cpp

	bool detached_;
	pthread_attr_t *attr_;
	pthread_t id_;
	pmutex start_mutex_;
};
// END

}; // pw
// DEBUG endformer

// DEBUG washeader pwext.hpp
// DEBUG former ex03.cpp
// The derived classes for the ptwrap library

namespace pw // POSIX wrapped
{

// [[ex03da]] 
// DEBUG descr The semaphore value returned by the signal method.
class semaphore
{
public:
// DEBUG from
	semaphore(unsigned initval) :
		restcond_(leadcond_), value_(initval), leadn_(0)
	{ }

	int wait(unsigned n = 1);
	int trywait(unsigned n = 1);
	int timedwait(unsigned n, const struct timespec &abstime);
	int signal(unsigned n = 1);

protected:
	// the lead thread waits on it
	pw::pmcond leadcond_; 
	// the rest of the threads wait on this one
	pw::pchaincond restcond_; 
	// current value of the semaphore, always positive
	unsigned value_; 
	// value the lead thread is waiting for, or 0
	unsigned leadn_; 
// DEBUG to
};
// END


// [[ex03ae]]
// DEBUG descr Auto-reset event with both pulse and timed wait.
class autoevent
{
public:
	autoevent(bool signaled = false) :
		signaled_(signaled), evsleepers_(0)
	{ }

	int wait()
	{
		pw::lockmutex lm(cond_);
		++evsleepers_;
		while (!signaled_)
			cond_.wait();
		--evsleepers_;
		signaled_ = false;
		return 0;
	}
	int trywait()
	{
		pw::lockmutex lm(cond_);
		if (!signaled_)
			return ETIMEDOUT;
		signaled_ = false;
		return 0;
	}
	int timedwait(const struct timespec &abstime);
	int signal()
	{
		pw::lockmutex lm(cond_);
		signaled_ = true;
		cond_.signal();
		return 0;
	}
	int reset()
	{
		pw::lockmutex lm(cond_);
		signaled_ = false;
		return 0;
	}
	int pulse()
	{
		pw::lockmutex lm(cond_);
		if (evsleepers_ > 0) {
			signaled_ = true;
			cond_.signal();
		} else {
			signaled_ = false;
		}
		return 0;
	}

protected:
	// contains both condition variable and a mutex
	pw::pmcond cond_; 
	// semaphore has been signaled
	bool signaled_; 
	// the counter of waiting threads
	int evsleepers_; 
};
// END

// [[ex03af]]
// DEBUG descr A simple-minded manual-reset event (renamed to avoid name conflicts).
class basicevent
{
public:
	basicevent(bool signaled = false) :
		signaled_(signaled)
	{ }

	int wait()
	{
		pw::lockmutex lm(cond_);
		if (signaled_)
			return 0;
		cond_.wait();
		return 0;
	}
	int trywait()
	{
		pw::lockmutex lm(cond_);
		if (signaled_)
			return 0;
		return ETIMEDOUT;
	}
	int timedwait(const struct timespec &abstime)
	{
		pw::lockmutex lm(cond_);
		if (signaled_)
			return 0;
		if (cond_.timedwait(abstime) == ETIMEDOUT)
			return ETIMEDOUT;
		return 0;
	}
	int signal()
	{
		pw::lockmutex lm(cond_);
		signaled_ = true;
		cond_.broadcast();
		return 0;
	}
	int reset()
	{
		pw::lockmutex lm(cond_);
		signaled_ = false;
		return 0;
	}
	int pulse()
	{
		pw::lockmutex lm(cond_);
		signaled_ = false;
		cond_.broadcast();
		return 0;
	}

protected:
	// contains both condition variable and a mutex
	pw::pmcond cond_; 
	// event is in the signaled state
	bool signaled_; 
};
// END

// [[ex03ag]]
// DEBUG descr Manual-reset event.
class event
{
public:
	event(bool signaled = false) :
		signaled_(signaled),
		seq_(0),
		seqpulse_(0)
	{ }

	int wait()
	{
		pw::lockmutex lm(cond_);
		if (signaled_)
			return 0;
		unsigned s = ++seq_;
		do {
			cond_.wait();
			if (seqpulse_ - s >= 0)
				return 0;
		} while (!signaled_);
		return 0;
	}
	int trywait()
	{
		pw::lockmutex lm(cond_);
		// doesn't need the sequence because 
		// doesn't care about pulsing
		if (!signaled_)
			return ETIMEDOUT;
		return 0;
	}
	int timedwait(const struct timespec &abstime)
	{
		pw::lockmutex lm(cond_);
		if (signaled_)
			return 0;
		unsigned s = ++seq_;
		do {
			if (cond_.timedwait(abstime) == ETIMEDOUT)
				return ETIMEDOUT;
			if (seqpulse_ - s >= 0)
				return 0;
		} while (!signaled_);
		return 0;
	}
	int signal()
	{
		pw::lockmutex lm(cond_);
		signaled_ = true;
		cond_.broadcast();
		return 0;
	}
	int reset()
	{
		pw::lockmutex lm(cond_);
		signaled_ = false;
		return 0;
	}
	int pulse()
	{
		pw::lockmutex lm(cond_);
		signaled_ = false;
		seqpulse_ = seq_;
		cond_.broadcast();
		return 0;
	}

protected:
	// contains both condition variable and a mutex
	pw::pmcond cond_; 
	// event is in the signaled state
	bool signaled_; 
	// every wait increases the sequence
	unsigned seq_; 
	// pulse frees all the waits up to this sequence
	unsigned seqpulse_; 
};
// END

// [[ex03ca]]
// DEBUG descr The general hold.
class hold 
{
public:
	hold() : count_(0)
	{ }
	
	void acquire() 
	{
		pw::lockmutex lm(cond_);
		++count_;
	}

	// returns the number of holds left
	int release() 
	{
		pw::lockmutex lm(cond_);
		if (--count_ <= 0)
			cond_.broadcast();
		return count_;
	}

	void wait()
	{
		pw::lockmutex lm(cond_);
		while(count_ != 0) 
			cond_.wait();
	}

	int get_hold_count()
	{
		pw::lockmutex lm(cond_);
		return count_;
	}

protected:
	// signaled when count_ drops to 0
	pw::pmcond cond_; 
	// count of holds
	int count_; 
};
// END

// fragment of ex03ch
class barrier 
{
public:
	barrier(int count) :
		flip_(0), flop_(0), count_(count)
	{ }

	// May be called only by the control thread, to
	// adjust the number of workers
	int add_workers(int add)
	{
		count_ += add; // add may be negative
		return count_;
	}

	// Workers call this method to synchronize on the
	// barrier
	void sync()
	{
		flip_.signal(1);
		flop_.wait(1);
	}

	// Control calls this method to wait for the barrier
	// to be reached by all the workers
	void wait()
	{
		flip_.wait(count_);
	}

	// Control calls this method to release the workers
	// from the barrier
	void signal()
	{
		flop_.signal(count_);
	}

protected:
	// control waits for workers
	pw::semaphore flip_; 
	// workers wait for control
	pw::semaphore flop_; 
	// number of threads synchronized by the barrier
	int count_; 
};
// END

// [[ex03ia]]
// DEBUG descr Split lock single-stepping with keeping track of the worker thread intent.
class splitlock
{
public:
	// Information about whether the worker will enter
	// the critical section
	enum worker_intent {
		WORKER_WILL_ENTER, // it definitely will
		WORKER_WONT_ENTER, // it definitely won't
		WORKER_MIGHT_ENTER // unknown
	};

	// @param safe - flag: if true, place the lock
	// initially into a safe state, so that the worker
	// thread may not enter it until the control thread
	// releases it; 
	// if false, place it into the unsafe state and
	// allow the worker thread to enter it freely
	splitlock(bool safe = false) :
		cond_safe_(cond_enter_),
		cond_worker_(cond_enter_),
		wi_(WORKER_MIGHT_ENTER),
		may_enter_(!safe),
		is_safe_(safe),
		may_step_(false)
	{ }

	// Control thread side of API.

	// ... the rest of control side is unchanged, so it's
	// omitted here ...
	// DEBUG {
	void request_safe()
	{
		pw::lockmutex lm(cond_enter_);
		may_enter_ = false;
	}

	void wait_safe()
	{
		pw::lockmutex lm(cond_enter_);
		while (!is_safe_ || may_step_) {
			cond_safe_.wait();
		}
	}

	// A convenience combination - just in case
	void lock_safe()
	{
		request_safe();
		wait_safe();
	}

	void release_safe()
	{
		pw::lockmutex lm(cond_enter_);
		may_enter_ = true;
		cond_enter_.broadcast();
	}

	// Returns true if a thread was waiting and is now
	// allowed to step, or false if there was no thread
	// waiting.
	bool release_safe_step()
	{
		pw::lockmutex lm(cond_enter_);
		if (cond_enter_.sleepers_) {
			may_step_ = true;
			cond_enter_.broadcast();
			return true;
		} else {
			return false;
		}
	}
	// DEBUG }

	// Wait until worker tries to enter the critical
	// section, or if it's unknown whether it will, then
	// wait no longer than until the specified time.  May
	// be called only when the splitlock is in safe
	// condition.  Returns true if the wait succeeded,
	// false if timed out.
	// @param abstime - time limit 
	// @param timed - if false, the time limit applies
	//   only if it's unknown whether the worker will
	//   enter, if true, the time limit applies even if
	//   it's known that the worker will enter
	bool wait_for_worker(const struct timespec &abstime, 
		bool timed = false);

	worker_intent get_worker_intent()
	{
		pw::lockmutex lm(cond_enter_);
		return wi_;
	}

	// Worker thread side of API.

	void enter()
	{
		pw::lockmutex lm(cond_enter_);
		while (!may_enter_ && !may_step_) {
			cond_worker_.broadcast();
			cond_enter_.wait();
		}
		is_safe_ = false;
		may_step_ = false;
		wi_ = WORKER_MIGHT_ENTER;
	}

	void leave()
	{
		pw::lockmutex lm(cond_enter_);
		is_safe_ = true;
		cond_safe_.broadcast();
	}

	// Try to enter the critical section.
	// Never blocks.
	// Returns true on success, false if the splitlock
	// is already safe.
	bool try_enter()
	{
		pw::lockmutex lm(cond_enter_);
		if (!may_enter_ && !may_step_)
			return false; 
		is_safe_ = false;
		may_step_ = false;
		wi_ = WORKER_MIGHT_ENTER;
		return true;
	}

	// After an enter attempt has failed and the
	// caller has freed all the sensitive resources,
	// block until the control thread releases the
	// lock and another attempt to enter may be made.
	void continue_enter()
	{
		pw::lockmutex lm(cond_enter_);
		while (!may_enter_ && !may_step_) {
			cond_worker_.broadcast();
			cond_enter_.wait();
		}
	}

	void set_worker_intent(worker_intent wi)
	{
		pw::lockmutex lm(cond_enter_);
		wi_ = wi;
		cond_worker_.broadcast();
	}

protected:
	// signaled when the worker thread is allowed to
	// enter
	pw::pmcond cond_enter_; 
	// signaled when the control thread becomes safe
	pw::pchaincond cond_safe_; 
	// signaled when wi_ changes or the worker sleeps
	// on enter
	pw::pchaincond cond_worker_; 
	worker_intent wi_;
	// flag: the worker thread may enter
	bool may_enter_; 
	// flag: the control thread is safe (working
	// thread has not entered)
	bool is_safe_; 
	// flag: the worker thread may enter once
	bool may_step_; 
};
// END

}; // pw
// DEBUG endformer

namespace pw // POSIX wrapped
{

// DEBUG former ex03j.cpp (fragment)

// [[ex03ja]]
// DEBUG descr The set of split locks with a common control API.
template <class worker>
class splitlock_set
{
public:
	typedef std::set<worker *> worker_set;

	// Methods that potentially may be called by any
	// thread

	// implicitly locks the worker set if it wasn't
	// locked
	void request_safe()
	{
		pw::lockmutex lm(cond_);
		lset_ = true;
		rsafe_ = true;
		typename worker_set::iterator it;
		for (it = workers_.begin(); 
				it != workers_.end(); ++ it)
			(*it)->split_.request_safe();
		for (it = new_workers_.begin(); 
				it != new_workers_.end(); ++ it)
			(*it)->split_.request_safe();
	}

	void add_thread(worker *w)
	{
		w->split_.lock_safe(); // outside the mutex

		pw::lockmutex lm(cond_);
		if (lset_) {
			new_workers_.insert(w);
		} else {
			workers_.insert(w);
		}
		if (!rsafe_)
			w->split_.release_safe();
	}

	// Methods that potentially may be called by any
	// thread except the control

	// must not be called by control thread
	void rm_thread(worker *w) 
	{
		typename worker_set::iterator it;

		pw::lockmutex lm(cond_);

		it = new_workers_.find(w);
		if (it != new_workers_.end()) {
			// threads may be removed from the new subset
			// at any time
			new_workers_.erase(it);
			return;
		}

		while (lset_) 
			cond_.wait();

		it = workers_.find(w);
		if (it != workers_.end()) {
			workers_.erase(it);
		} else {
			// check again, just in case
			it = new_workers_.find(w);
			if (it != new_workers_.end()) {
				new_workers_.erase(it);
			}
		}
	}

	// Methods that may be called only by the control
	// thread

	splitlock_set() :
		lset_(false), rsafe_(false)
	{ }

	// before destruction, its up to the control
	// thread to decide, what to do with the workers:
	// make sure that they've exited, or somehow tell
	// them that they're not in the set any more (if
	// they care)
	~splitlock_set()
	{ }

	// implicitly locks the worker set if it wasn't
	// locked
	void wait_safe()
	{
		lock_set();

		// must leave the mutex unlocked, the lock on
		// the set is enough!
		typename worker_set::iterator it;
		for (it = workers_.begin(); 
				it != workers_.end(); ++ it)
			(*it)->split_.wait_safe();
	}

	// A convenience combination
	void lock_safe()
	{
		request_safe();
		wait_safe();
	}

	// implicitly unlocks the worker set
	void release_safe()
	{
		// outside of the mutex, avoid the deadlock
		unlock_set(); 

		pw::lockmutex lm(cond_);
		rsafe_ = false;
		typename worker_set::iterator it;
		for (it = workers_.begin(); 
				it != workers_.end(); ++ it)
			(*it)->split_.release_safe();
	}

	// for added threads, don't require safety
	void set_add_unsafe()
	{
		pw::lockmutex lm(cond_);
		rsafe_ = false;
		typename worker_set::iterator it;
		for (it = new_workers_.begin(); 
				it != new_workers_.end(); ++ it)
			(*it)->split_.release_safe();
	}

	// for added threads, require safety
	void set_add_safe()
	{
		pw::lockmutex lm(cond_);
		rsafe_ = true;
		typename worker_set::iterator it;
		for (it = new_workers_.begin(); 
				it != new_workers_.end(); ++ it)
			(*it)->split_.request_safe();
		// the safety of the new workers is requested
		// but not achieved yet
	}

	void lock_set()
	{
		pw::lockmutex lm(cond_);
		lset_ = true;
	}

	void unlock_set()
	{
		pw::lockmutex lm(cond_);
		lset_ = false;
		// collect the threads from the new subset
		typename worker_set::iterator it;
		for (it = new_workers_.begin(); 
				it != new_workers_.end(); ++ it) {
			workers_.insert(*it);
			if (!rsafe_)
				(*it)->split_.release_safe();
		}
		new_workers_.clear();
		cond_.broadcast();
	}

	// To be called by the control thread only,
	// bypasses the set lock.
	void control_rm_thread(worker *w)
	{
		typename worker_set::iterator it;

		pw::lockmutex lm(cond_);

		it = workers_.find(w);
		if (it != workers_.end()) {
			workers_.erase(it);
		} else {
			it = new_workers_.find(w);
			if (it != new_workers_.end()) {
				new_workers_.erase(it);
			}
		}
	}

	// Wait until all workers try to enter the
	// critical section, or if it's unknown whether
	// some of them will, then wait no longer than
	// until the specified time.
	// May be called only when the set is in safe
	// condition, and locked.  Returns true if the
	// wait succeeded, false if timed out (i.e. if
	// there are any workers that are left not in the
	// critical section)
	// @param abstime - time limit 
	// @param timed - if false, the time limit applies
	//   only if it's unknown whether the worker will
	//   enter, if true, the time limit applies even if
	//   it's known that the worker will enter
	bool wait_for_workers(const struct timespec &abstime, 
		bool timed = false)
	{
		bool res = true;

		typename worker_set::iterator it;
		for (it = workers_.begin(); 
				it != workers_.end(); ++ it)
			res = (res && (*it)->split_.
				wait_for_worker(abstime, timed));

		return res;
	}

	// Lets the control thread iterate and search on
	// the set.  The set must be locked, for safe
	// handling.
	const worker_set &get_set()
	{
		return workers_;
	}

protected:

	worker_set workers_;
	// where the workers are added when the set is
	// locked
	worker_set new_workers_; 
	// signaled on unlocking of the set
	pw::pmcond cond_; 
	// flag: safety of all workers requested, and set
	// has been locked
	bool lset_; 
	// flag: safety of all workers requested
	bool rsafe_; 
};
// END
// DEBUG endformer

// DEBUG former ex05fc.cpp (fragment)
// not compiled by itself, included into other files

// [[ex05fc]]
// DEBUG descr The weak reference implementation using the holds to prevent deadlocking.
class weakref;

class reftarget {
	friend class weakref;
public:
	// this pointer will be held in the weak
	// references
	reftarget(void *owner); 
	~reftarget();

	// create a new weak reference to this target
	weakref *newweakref(); 

	// called from the subclass or wrapper class
	// destructor
	void invalidate(); 

protected:
	// notification from a weakref that it gets
	// destroyed
	void freeweakref(weakref *wr); 

	pw::pmutex mutex_; // controls all access
	pw::hold hold_;
	bool valid_; // gets reset on invalidation
	weakref *rlist_; // head of the list of references
	void *owner_; // value to pass to the weak refs

private: 
	// prevent the default and copy constructors and
	// assignments
	reftarget();
	reftarget(const reftarget&);
	void operator=(const reftarget&);
};

class weakref {
	friend class reftarget;
public:
	~weakref();

	// create a copy of this reference
	weakref *copy(); 

	// make the reference strong, return its current value
	void *grab(); 
	// release the reference back to weak
	void release(); 
	
protected:
	// called from copy() and from reftarget
	weakref(reftarget *target); 

	// called from reftarget invalidation
	bool invalidate1(); 
	// called if invalidate1() returned true
	void invalidate2(); 

	// a sort-of-double-linked list, access controlled
	// by target's mutex
	weakref *next_;
	weakref **prevp_;

	pw::pmutex mutex_; // controls all access
	pw::hold hold_; // keeps track of holds from reftarget
	pw::hold grabs_; // keep track of the grabs
	reftarget *target_; // reset to 0 on invalidation

private: 
	// prevent the default and copy constructors and
	// assignments (they may be added but the code is
	// simpler without them)
	weakref();
	weakref(const weakref&);
	void operator=(const weakref&);
};
// END
// DEBUG endformer

// DEBUG former ex05ff.cpp (fragment)
// [[ex05ff]]
// DEBUG descr The temporary release and re-grabbing of the weak references.
template <typename target>
class scopegrab
{
public:
	scopegrab(weakref *ref, target *&result) : 
		ref_(ref)
	{
		result = (target *)ref->grab();
		grabbed_ = true;
	}
	~scopegrab()
	{
		if (grabbed_)
			ref_->release();
	}
	void release()
	{
		if (grabbed_)
			ref_->release();
		grabbed_ = false;
	}
	target *regrab()
	{
		if (grabbed_)
			ref_->release();
		grabbed_ = true;
		return (target *)ref_->grab();
	}
protected:
	weakref *ref_;
	bool grabbed_;
private: 
	// prevent the default and copy constructors and
	// assignments
	scopegrab();
	scopegrab(const scopegrab &);
	void operator=(const scopegrab &);
};
// END
// DEBUG endformer

// DEBUG former ex05fg.cpp (fragment)
// [[ex05fg]]
// DEBUG descr The scoped object for temporary release and re-grabbing of the weak references.
template <typename target>
class scopeungrab
{
public:
	scopeungrab(scopegrab<target> &grab, 
			target *&result) : 
		grab_(grab), result_(result)
	{
		grab_.release();
		result_ = 0;
	}
	~scopeungrab()
	{
		result_ = grab_.regrab();
	}
protected:
	scopegrab<target> &grab_;
	target *&result_;
private: 
	// prevent the default and copy constructors and
	// assignments
	scopeungrab();
	scopeungrab(const scopeungrab &);
	void operator=(const scopeungrab &);
};
// END
// DEBUG endformer

}; // pw

}; // TRICEPS_NS

// the queues are not brought in yet, beceuse there is no need for them yet...

#endif // __Triceps_ptwrap_hpp__
