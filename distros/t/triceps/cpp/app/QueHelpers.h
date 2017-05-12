//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Various bits and pieces for the facet queues.

#ifndef __Triceps_QueHelpers_h__
#define __Triceps_QueHelpers_h__

#include <deque>
#include <common/Common.h>
#include <pw/ptwrap2.h>
#include <mem/Atomic.h>
#include <app/Xtray.h>

namespace TRICEPS_NS {

// These small classes logically belong as fragments to the bigger objects
// but had to be separated to keep the reference counting from creating
// the cycles.

// The state of the App drainage: allows to detect that all the
// App's threads and queues have been drained on request.
class DrainApp: public Mtarget
{
public:
	// Initialize the drain: 
	// Resets the state and temporarily adds 1 (i.e. set to 0 and add 1)
	// to the number of undrained threads, for the time when all the
	// threads are polled for the initial state. Afterwards this 1
	// will be deducted.
	// Whenever each thread is initially polled, it will notify
	// if undrained and stay quiet if drained.
	void init()
	{
		pw::lockmutex lm(ev_.mutex());
		ev_.resetL();
		left_ = 1;
	}

	// Completion of the initialization: after all threads have been
	// polled, subtract the initial holder 1.
	void initDone()
	{
		drainedOne();
	}

	// Notification that one thread has been drained.
	void drainedOne()
	{
		pw::lockmutex lm(ev_.mutex());
		if (--left_ == 0)
			ev_.signalL();
	}

	// Notification that one thread has been undrained.
	void undrainedOne()
	{
		pw::lockmutex lm(ev_.mutex());
		if (left_++ == 0)
			ev_.resetL();
	}

	// Wait for the drain to complete.
	void wait()
	{
		ev_.wait();
	}

	// Check whether currently drained.
	bool isDrained()
	{
		return ev_.read();
	}

	// the mutex from ev_ also protects the rest of the fields
	pw::event2 ev_; // allows to wait for drainage
	int left_; // how many threads are left undrained,
		// when it goes to 0, the event gets signaled
};

// Notification from the Nexuses to the Triead that there is something
// to read. Done as a separate object because the Nexuses will need
// to refrence it, and they can not reference the Tried directly
// because that would cause a reference loop.
// This event covers all the facets connected to the thread.
class QueEvent: public Mtarget
{ 
	friend class Triead;
public:
	// No drain is requested by default, nor signaled either.
	// @param drain - the App drain status, to propagate the state of this
	//        event
	QueEvent(DrainApp *drain);

	// The request from App to start the drain notification.
	// Immediately updates the state of the drain_ based on the
	// current state of the semaphore and keeps it updated
	// until requested to undrain. The initial state of drain_
	// at this time is "drained", so it gets changed to "undrained"
	// if the event is found undrained.
	void requestDrain();

	// The request from App to stop the drain notification.
	// The drain_ will be left in whatever state it happens to be.
	void requestUndrain()
	{
		pw::lockmutex lm(cond_);
		rqDrain_ = false;
		cond_.signal(); // wake up if there is a stuck timed wait
	}

	// Mark this thread as dead.
	// This call propagates by the chain
	//   TrieadOwner->App->Triead->QueEvent
	// This part is for the benefit of the drain state, so that
	// when a thread exits, it won't prevent the drain completion.
	// The reader facets need to be marked as dead separately.
	//
	// In case if this QueEvent is for an input-only thread,
	// this method is also used as a part of the requestDead()
	// sequence. Calling it the second time when the thread is
	// dead doesn't hurt anything.
	void markDead()
	{
		pw::lockmutex lm(cond_);
		dead_ = true;
		if (rqDrain_ && !drained_) {
			drained_ = true; // from now on, drained forever
			drain_->drainedOne();
		}
		rqDrain_ = false; // don't bother with drains any more
		// this is for the case of the input-only thread
		cond_.signal();
	}

	// The logic is a copy-paste of autoevent2 with extensions
	// (basically, because the methods are not virtual and would
	// have to be redefined with the extra logic anyway.
	//
	// The pulse part has been dropped since it's of no use here.
	// The wait supports no more than one sleeper at a time
	// (since the presence of the sleeper is used to indicate that
	// the queue has been drained).
	//
	// The drain condition is set when the thread starts waiting
	// and reset when it gets signaled. This asymmetry makes at least
	// one thread marked undrained while there is data ready in the
	// ReqdereQueue's write queue. I.e. when thread A writes to thread B,
	// first the thread B will be marked undrained when the Xtray is placed
	// onto its input and only then the thread A will be marked drained
	// when it blocks on its own input. This avoids the spurious
	// "all drained" notifications while there still is data to process.
	void wait()
	{
		pw::lockmutex lm(cond_);
		waitL();
	}
	void waitL()
	{
		evsleeper_ = true;
		while (!signaled_) {
			if (rqDrain_ && !drained_) {
				drained_ = true;
				drain_->drainedOne();
			}
			cond_.wait();
		}
		evsleeper_ = false;
		signaled_ = false;
	}
	int trywait()
	{
		pw::lockmutex lm(cond_);
		return trywaitL();
	}
	int trywaitL()
	{
		if (!signaled_)
			return ETIMEDOUT;
		signaled_ = false;
		return 0;
	}

	// If the thread is requested to drain, the timeout will
	// be ignored and the call will be stuck until undrained or
	// new data becomes available.
	int timedwait(const struct timespec &abstime)
	{
		pw::lockmutex lm(cond_);
		return timedwaitL(abstime);
	}
	int timedwaitL(const struct timespec &abstime);
	void signal()
	{
		pw::lockmutex lm(cond_);
		signalL();
	}
	void signalL()
	{
		signaled_ = true;
		if (rqDrain_ && drained_) {
			drained_ = false;
			drain_->undrainedOne();
		}
		cond_.signal();
	}
	void reset()
	{
		pw::lockmutex lm(cond_);
		resetL();
	}
	void resetL()
	{
		signaled_ = false;
	}
	bool read()
	{
		return signaled_;
	}
	pw::pmutex &mutex()
	{
		return cond_;
	}

	// The QueEvent gets used in two ways:
	// 1. Like a normal event
	// 2. For communicating the drain state from the write-only threads
	// The part above was (1). Here goes the (2).
	//
	// How did I come up with this logic? Well, first I wrote is as a
	// separate class and then I've noticed that the requestDrain/Undrain
	// logic is the same if I use some read flags to mark the write
	// conditions too.

	// Mark this object that it's an input-only thread, and so
	// the drain synchronization will be with the write requests.
	void setWriteMode(bool on = true)
	{
		// fudges the flags sufficiently to let the requestDrain/Undrain
		// logic work unchanged from the normal (read) mode
		evsleeper_ = on;
	}
	// The thread must call this before it writes to any facet.
	// It will sleep if the drain is requested, until the end of
	// drain. When/if the drain is not active, it will mark the
	// thread as undrained for the future drains.
	//
	// When returns false, the caller MUST NOT WRITE ANY DATA ANY MORE,
	// don't even call afterWrite().
	//
	// @return - true if cleared to write, false if the thread
	//         was requested to die
	bool beforeWrite()
	{
		pw::lockmutex lm(cond_);
		if (dead_)
			return false;
		while (rqDrain_) {
			cond_.wait();
			if (dead_)
				return false;
		}
		signaled_ = true; // marks as undrained for requestDrain()
		// drained_ does not matter here
		return true;
	}
	// The thread must call this after it writes to any facet.
	// If a drain was requested in the meantime, this will mark
	// the thread as drained.
	void afterWrite()
	{
		pw::lockmutex lm(cond_);
		signaled_ = false; // mark as drained for requestDrain()
		// drained_ does not matter here
		if (rqDrain_)
			drain_->drainedOne();
	}

	// Check if a drain is currently requested.
	// It allows the thread code to stop generating the data
	// out of nowhere when the drain is requested.
	bool isRqDrain()
	{
		return rqDrain_;
	}

protected:
	// The thread is considered drained when it sits and waits
	// for more input on the QueEvent. If it gets more input, it
	// becomes undrained untill all that input is processed.
	// The drainage notifications are done only when the
	// app is interested in it and requested them.
	Autoref<DrainApp> drain_; // where to notify the App of drainage
	bool rqDrain_; // flag: the drain notifications have been requested
	bool drained_; // flag: the queue has been drained
	bool dead_; // flag: this thread is dead, and as such always drained

	// the part cloned from autoevent2
	pw::pmcond cond_; // contains both condition variable and a mutex
	bool signaled_; // flag: semaphore has been signaled
	bool evsleeper_; // flag: there is a sleep in progress
};

// The queue of one reader facet.
class ReaderQueue: public Mtarget
{
	friend class Nexus;
public:
	typedef deque<Autoref<Xtray> > Xdeque;

	// @param qev - the thread's notification event
	// @param limit - high watermark limit for the queue
	ReaderQueue(QueEvent *qev, Xtray::QueId limit);

	// Write an Xtray to the first reader in the vector.
	// This generates the sequential id for the Xtray.
	// May sleep if the write queue is full.
	//
	// @param gen - generation of the vector used by the writer
	// @param xt - Xtray being written
	// @param trayId - place to return the generated id of the tray
	// @return - true if the generations matched and the write went through
	//        and generated the id; false if the generations were mismatched
	//        or if this reader is marked as dead, and nothing was done
	bool writeFirst(int gen, Xtray *xt, Xtray::QueId &trayId);

	// Write an Xtray with a specific sequence to a reader that is
	// not first in the vector. Does nothing if the queue is dead.
	// May sleep if the write queue is full.
	//
	// @param xt - Xtray being written
	// @param trayId - the sequential id of the tray
	void write(Xtray *xt, Xtray::QueId trayId);

	// Refill the read side of the queue from the write side.
	// @return - whether the data became available in the reader queue
	bool refill();

	// Pop a value from the front of the read queue. 
	// MUST NOT BE CALLED WITH AN EMPTY QUEUE.
	// Set it to NULL before popping, to make sure that a reference
	// won't be stuck in the queue for a long time.
	void popread()
	{
		Xdeque &q = readq();
		// q.front() = NULL; // not really needed, deque destroys it right
		q.pop_front();
	}

	// Get the value from the front of the read queue.
	// The value is returned as a pointer, to reduce the number of
	// reference changes. Like STL front(), the value is not popped,
	// so it's safe to use the pointer until popread() is called.
	//
	// @return - the next item from the front of the read queue, or
	//           NULL if none is available any more (the write queue
	//           may still have data)
	Xtray *frontread() const
	{
		const Xdeque &q = q_[rq_]; // readq(), only preserve the constness
		if (q.empty())
			return NULL;
		return q.front().get();
	}

	// Check if the reader is disconnected and dead.
	bool isDead() const
	{
		return dead_;
	}

protected:

	Xdeque &writeq()
	{
		return q_[rq_ ^ 1];
	}
	Xdeque &readq()
	{
		return q_[rq_];
	}
	pw::pmutex &mutex()
	{
		return condfull_;
	}

	// Update the generation of the reader vector.
	// The caller should lock the mutex_ or otherwise have
	// this reader not accessible to writers yet.
	void setGenL(int gen)
	{
		gen_ = gen;
	}

	// Update the lastId_, so that it's consistent across all the readers.
	// Done when a reader is deleted, to allow the use of any of them as the
	// new first reader.
	// Stretches the queue as needed.
	// The caller should lock the mutex_ or otherwise have
	// this reader not accessible to writers yet.
	void setLastIdL(Xtray::QueId id);

	// Insert an Xtray into the write queue at the specified index
	// relative to the start of the queue.
	// Extends the queue as needed. Never blocks.
	// @param xt - Xtray to insert
	// @param idx - index to insert at
	void insertQueL(Xtray *xt, Xtray::QueId idx);

	// Mark this reader as dead and disconnected from the nexus.
	// This clears the queue.
	// All the future writes to it will be no-ops.
	void markDeadL();

	// part that is set once and never changed
	
	Autoref<QueEvent> qev_; // where to signal when have data

	// XXX set very high for the "never block" reverse nexuses
	Xtray::QueId sizeLimit_; // the high water mark for writing

	// part that is either protected by the mutex or used only by the
	// facet-owning thread
	// XXX should bother to separate better the part used by the facet-owning thread?

	Xdeque q_[2]; // the queues of trays; they alternate with double buffering;
		// the one currently used for reading can be accessed without a lock
	int rq_; // index of the queue that is currently used for reading
		// changed only by the reader thread, with mutex locked,
		// so that thread 

	// the Xtray ids may roll over
	Xtray::QueId prevId_; // id of the last Xtray preceding the start of the queue
	Xtray::QueId lastId_; // id of the last Xtray at the end of the queue
		// (if prevId_ and lastId_ are the same, the queue is empty)

	int gen_; // the generation of the nexus's reader vector

	bool wrhole_; // the write queue had a hole in it, so it can't be simply swapped with read queue
	bool dead_; // this queue has been disconnected from the nexus

	bool wrReady_; // there is new data in the writer queue
	pw::pmcond condfull_; // wait when the queue is full, also contains the mutex

private:
	ReaderQueue();
	ReaderQueue(const ReaderQueue &);
	void operator=(const ReaderQueue &);
};

// Collection of the reader facets in a Nexus. The writers will
// be sending data to all of them. Done as a separate object, so that
// all the writers can refer to it.
//
// As the readers are added and deleted from a nexus, the new ReaderVec
// objects are created, each with an increased generation number.
// The addition and deletion are infrequent operations and can afford
// to be expensive.
//
// Like other shared objects, it's all-writes-before-sharing.
class ReaderVec: public Mtarget
{
	friend class Nexus;
public:
	typedef vector<Autoref<ReaderQueue> > Vec;

	// @param g - the generation
	ReaderVec(int g):
		gen_(g)
	{ }
		
	// read the vector
	const Vec &v() const
	{
		return v_;
	}

	// read the generation
	int gen() const
	{
		return gen_;
	}

protected:
	Vec v_; // the Nexus will add directly to it on construction
	int gen_; // the generation of the vector

private:
	ReaderVec();
	ReaderVec(const ReaderVec &);
	void operator=(const ReaderVec &);
};

class NexusWriter: public Mtarget
{
public:
	NexusWriter()
	{ }

	// Update the new reader vector (readersNew_).
	// @param rv - the new vector (the caller must hold a reference to it
	//        through the call). The writer will discover it on the next
	//        attempt to write.
	void setReaderVec(ReaderVec *rv);

	// Write the Xtray.
	// Called only from the thread that owns this facet.
	//
	// @param xt - the data (the caller must hold a reference to it
	//        through the call, the caller must not change the Xtray contents
	//        afterwards).
	void write(Xtray *xt);

protected:
	Autoref<ReaderVec> readers_; // the current active reader vector

	pw::pmutex mutexNew_; // protects the readersNew_
	Autoref<ReaderVec> readersNew_; // the new reader vector

private:
	NexusWriter(const NexusWriter &);
	void operator=(const NexusWriter &);
};

}; // TRICEPS_NS

#endif // __Triceps_QueHelpers_h__
