//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// A reference-counted byte buffer

#ifndef __Triceps_EasyBuffer_h__
#define __Triceps_EasyBuffer_h__

#include <common/Common.h>
#include <mem/Starget.h>

namespace TRICEPS_NS {

// There is a frequent case of temporary variable-sized byte buffers
// used for construction of rows and such. This takes care of them.
class EasyBuffer : public Starget
{
public:
	
	// @param basic - provided by C++ compiler, size of the basic structure
	// @param variable - actual size for data_[]
	static void *operator new(size_t basic, intptr_t variable)
	{
		return malloc((intptr_t)basic + variable - 1); // -1 accounts for the existing one byte
	}
	static void operator delete(void *ptr)
	{
		free(ptr);
	}

	int size_; // the size of the buffer can be remembered here if desired.
	char data_[1];
};

}; // TRICEPS_NS

#endif // __Triceps_EasyBuffer_h__
