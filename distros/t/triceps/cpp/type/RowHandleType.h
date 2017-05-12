//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// The type building for RowHandles.

#ifndef __Triceps_RowHandleType_h__
#define __Triceps_RowHandleType_h__

#include <type/Type.h>
#include <table/RowHandle.h>
#include <mem/Row.h>

namespace TRICEPS_NS {

// This is metadata used for building a RowHandle out of sections
class RowHandleType : public Type
{
public:
	RowHandleType();
	RowHandleType(const RowHandleType &orig);

	// Get the payload size in this handle
	intptr_t getSize() const
	{
		return size_;
	}

	// Allocates an aligned area and returns its offset
	// @param amount - amount of data to allocate
	// @return - offset that can be used in RowHandle::get()
	intptr_t allocate(size_t amount);

	// from Type
	virtual Erref getErrors() const;
	virtual void printTo(string &res, const string &indent = "", const string &subindent = "  ") const;

	// Factory for the new handles.
	// @param r - the row to refer, the caller must have it already incref-ed.
	RowHandle *makeHandle(const Row *r) const
	{
		return new(size_) RowHandle(r);
	}

protected:
	intptr_t size_; // total size of payload accumulated
};

}; // TRICEPS_NS

#endif // __Triceps_RowHandleType_h__
