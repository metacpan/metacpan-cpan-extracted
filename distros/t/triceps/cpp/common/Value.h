//
// (C) Copyright 2011-2018 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Helper functions for working with values.

#ifndef __Triceps_Value_h__
#define __Triceps_Value_h__

namespace TRICEPS_NS {

// Get a value of a simple type from a potentially unaligned pointer.
// The size of the type is expected to be a power of 2.
// This doesn't handle optimally the cases where the alignment
// required by the CPU is less than the "natural" alignment of the type.
template <typename T>
T getUnaligned(const T *ptr)
{
	if ((intptr_t)ptr & (sizeof(T)-1)) {
		T value;
		memcpy(&value, ptr, sizeof(T));
		return value;
	} else {
		return *ptr;
	}
}

// Compare two values at potentially unaligned pointers.
// Returns -1, 0 or 1.
template <typename T>
int cmpUnaligned(const T *left, size_t szleft, const T *right, size_t szright)
{
	T lv = getUnaligned<T>(left);
	T rv = getUnaligned<T>(right);
	if (lv < rv)
		return -1;
	else if (lv == rv)
		return 0;
	else
		return 1;
}

// The same comparison as above but accept any pointers.
template <typename T>
int cmpUnalignedVptr(const void *left, size_t szleft, const void *right, size_t szright)
{
	return cmpUnaligned<T>((const T *)left, szleft, (const T *)right, szright);
}

}; // TRICEPS_NS

#endif // __Triceps_Value_h__
