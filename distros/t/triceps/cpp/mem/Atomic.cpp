//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// The operations to work on atomic integers (using an external implementation
// or with plain mutexes).

#include <mem/Atomic.h>

namespace TRICEPS_NS {

// these are the same, with or without NSPR!

AtomicInt::AtomicInt() :
	val_(0)
{ }

AtomicInt::AtomicInt(int val) :
	val_(val)
{ }

}; // TRICEPS_NS
