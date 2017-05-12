//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// The operations to work on atomic integers (using an external implementation
// or with plain mutexes).

#ifndef __Triceps_Atomic_h__
#define __Triceps_Atomic_h__

#include <pw/ptwrap.h>
#ifdef TRICEPS_NSPR // {
#  include <pratom.h>
#endif // } TRICEPS_NSPR

namespace TRICEPS_NS {

#ifdef TRICEPS_NSPR // {

// the implementation around the NSPR4 atomics
class AtomicInt
{
public:
	AtomicInt(); // value defaults to 0
	AtomicInt(int val);

	// set the value
	void set(int val)
	{
		PR_ATOMIC_SET(&val_, (PRInt32)val);
	}

	// get the value
	int get() const
	{
		return (int)val_;
	}

	// increase the value, return the result
	int inc()
	{
		return (int)PR_ATOMIC_INCREMENT(&val_);
	}

	// derease the value, return the result
	int dec()
	{
		return (int)PR_ATOMIC_DECREMENT(&val_);
	}

protected:
	PRInt32 val_;

private:
	void operator=(const AtomicInt &);
	AtomicInt(const AtomicInt &);
};

#else  // } { TRICEPS_NSPR

// the baseline implementation when nothing better is available
// (it's actually not that bad, I've measured it only about 2.5-3 times slower)
class AtomicInt
{
public:
	AtomicInt(); // value defaults to 0
	AtomicInt(int val);

	// set the value
	void set(int val)
	{
		mt_mutex_.lock(); // for perversive architectures with software cache coherence
		val_ = val;
		mt_mutex_.unlock();
	}

	// get the value
	int get() const
	{
		return val_;
	}

	// increase the value, return the result
	int inc()
	{
		mt_mutex_.lock();
		int v = ++val_;
		mt_mutex_.unlock();
		return v;
	}

	// derease the value, return the result
	int dec()
	{
		mt_mutex_.lock();
		int v = --val_;
		mt_mutex_.unlock();
		return v;
	}

protected:
	pw::pmutex mt_mutex_;
	int val_;

private:
	void operator=(const AtomicInt &);
	AtomicInt(const AtomicInt &);
};

#endif // } TRICEPS_NSPR

}; // TRICEPS_NS

#endif // __Triceps_Atomic_h__
