//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// The basic underlying row.

#ifndef __Triceps_Row_h__
#define __Triceps_Row_h__

#include <mem/MtBuffer.h>

namespace TRICEPS_NS {

// For now, the basic row is nothing but an opaque buffer.
//
// The current approach is that there aren't any common meta-data carried in the
// row, it just knows how to carry the fields. So there is nothing much in
// common between the row formats.
class Row : public MtBuffer
{ 
protected:
	friend class MtBufferOwner; // may delete the buffers
	~Row() // not virtual, so random classes can't destroy it!
	{ }
};

}; // TRICEPS_NS

#endif // __Triceps_Row_h__
