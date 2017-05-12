//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Handle to store groups in the non-leaf indexes.

#ifndef __Triceps_GroupHandle_h__
#define __Triceps_GroupHandle_h__

#include <table/RowHandle.h>

namespace TRICEPS_NS {

class GroupHandle: public RowHandle
{
public:
	// uses the new() from RowHandle to pass the actual size
	
	GroupHandle(const Row *row) : // Index knows to incref() the row before this
		RowHandle(row)
	{
		flags_ |= F_GROUP;
	}
};

}; // TRICEPS_NS

#endif // __Triceps_GroupHandle_h__
