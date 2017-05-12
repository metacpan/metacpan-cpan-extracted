//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// A reference-counted byte buffer

#ifndef __Triceps_RowHandle_h__
#define __Triceps_RowHandle_h__

#include <common/Common.h>
#include <mem/Starget.h>
#include <mem/Row.h>

namespace TRICEPS_NS {

class Table;

// The RowHandles are owned by the Table, and as such must be accessed
// from one thread only. This allows to use the cheaper Starget base.
class RowHandle : public Starget
{
public:
	// The properly public part of the interface.
	
	const Row *getRow() const
	{
		return row_;
	}

	bool isInTable() const
	{
		return (flags_ & F_INTABLE);
	}

public:
	// This part of the API is for the internals of the tables.
	
	// flags describing the state of handle
	enum Flags {
		F_INTABLE = 0x01, // the handle is currently stored in the table and can be used as an interator in it
		F_GROUP = 0x02, // this is a group handle
		F_GROUP_AGGREGATED = 0x04, // for a group handle, an aggregator op was called on this group at least once
	};

	// the longest type used for the alignment 
	typedef double AlignType;

	// Allocation initializes the memory to 0.
	// @param basic - provided by C++ compiler, size of the basic structure
	// @param variable - actual size in bytes for data_[]
	static void *operator new(size_t basic, intptr_t variable)
	{
		// GCC 4.1 doesn't like sizeof(data_) here
		return calloc(1, (intptr_t)basic + variable - sizeof(AlignType)); 
	}
	static void operator delete(void *ptr)
	{
		free(ptr);
	}

	// here offsets are relative to &data_!
	char *at(intptr_t offset) const
	{
		return ((char *)&data_) + offset;
	}

	// With casting, for convenience
	template <typename T>
	T *get(intptr_t offset) const
	{
		return (T *)at(offset);
	}

protected:
	friend class Table;
	friend class IndexType;
	friend class RowHandleType;

	RowHandle(const Row *row) : // Table or IndexType knows to incref() the row before this
		flags_(0),
		row_(row)
	{ }
	
	~RowHandle() // only Table or IndexType knows how to destroy the contents properly
	{ }

protected:
	int32_t flags_; // together with Starget ref counter, this should result in 64-bit alignment
	const Row *row_; // the row owned by this handle
	AlignType data_; // used to focre the initial alignment

private:
	RowHandle();
	RowHandle(const RowHandle &);
	void operator=(const RowHandle &);
};

}; // TRICEPS_NS

#endif // __Triceps_RowHandle_h__
