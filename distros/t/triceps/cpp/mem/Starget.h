//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// The single-threaded target for a reference with counting.

#ifndef __Triceps_Starget_h__
#define __Triceps_Starget_h__

#include <mem/Autoref.h> // just for convenience

namespace TRICEPS_NS {

// The single-threaded autoreferences are faster but require
// a careful descipline, to keep these objects used in only one
// thread. So overall they're probably not worth the trouble,
// but just in case.
class Starget
{
public:
	Starget() :
		count_(0)
	{ }

	// The copy constructor and assignment must NOT copy the count!
	// Each object has its own count that can't be messed with.
	// Now, directly assigning a multiple-referenced object is
	// generally not a good idea, but it's not this class's problem.
	Starget(const Starget &t) :
		count_(0)
	{ }
	void operator=(const Starget &t)
	{ }

	// the operations on the count
	void incref() const
	{
		++count_;
	}

	int decref() const
	{
		return --count_;
	}

	// this one is mostly for unit tests
	int getref() const
	{
		return count_;
	}

private: // the subclasses really shouldn't mess with it
	mutable int count_;
};

}; // TRICEPS_NS

#endif // __Triceps_Starget_h__
