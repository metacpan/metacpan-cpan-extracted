//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// The multi-threaded target for a reference with counting.

#ifndef __Triceps_Mtarget_h__
#define __Triceps_Mtarget_h__

#include <pw/ptwrap.h>
#include <mem/Autoref.h> // just for convenience
#include <mem/Atomic.h>

namespace TRICEPS_NS {

// The multithreaded references could certainly benefit from
// atomic operations on the counter. But for now let's just do it
// in a portable way.
class Mtarget
{
public:
	Mtarget() :
		count_(0)
	{ }

	// The copy constructor and assignment must NOT copy the count!
	// Each object has its own count that can't be messed with.
	// Now, directly assigning a multiple-referenced object is
	// generally not a good idea, but it's not this class's problem.
	Mtarget(const Mtarget &t) :
		count_(0)
	{ }
	void operator=(const Mtarget &t)
	{ }

	// the operations on the count
	void incref() const
	{
		count_.inc();
	}

	int decref() const
	{
		return count_.dec();
	}

	// this one is mostly for unit tests
	int getref() const
	{
		return count_.get();
	}

private: // the subclasses really shouldn't mess with it
	mutable AtomicInt count_;
};

}; // TRICEPS_NS

#endif // __Triceps_Mtarget_h__
