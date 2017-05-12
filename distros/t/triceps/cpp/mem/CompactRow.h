//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// A row format bent on compactness, good for storing in the windows.

#ifndef __Triceps_CompactRow_h__
#define __Triceps_CompactRow_h__

#include <mem/Row.h>

namespace TRICEPS_NS {

class CompactRowType;

class CompactRow : public Row
{
public:
	// The default destructor is adequate.
	// It must be public because otherwise Autoptr won't work.
	
	// Check whether a field is NULL
	// @param nf - field number, starting from 0
	bool isFieldNull(int nf) const
	{
		return (off_[nf] & NULLMASK) != 0;
	}
	bool isFieldNotNull(int nf) const
	{
		return (off_[nf] & NULLMASK) == 0;
	}

	// Get a pointer to field data
	// @param nf - field number, starting from 0
	const char *getFieldPtr(int nf) const
	{
		return ((char *)off_) + (off_[nf] & OFFMASK);
	}
	// Same, except for the writeable return type
	char *getFieldPtrW(int nf) const
	{
		return ((char *)off_) + (off_[nf] & OFFMASK);
	}
	
	// Get a field's length
	// @param nf - field number, starting from 0
	intptr_t getFieldLen(int nf) const
	{
		return (off_[nf+1] - off_[nf]) & OFFMASK;
	}

	// Calculate the payload offset, for the given number of fields
	// @param numf - number of fields in this record
	static intptr_t payloadOffset(int numf)
	{
		return sizeof(off_[0]) * (numf+1);
	}

	// Calculate the pointer to payload, for the given number of fields
	// @param numf - number of fields in this record
	char *payloadPtrW(int numf) const
	{
		return ((char *)off_) + payloadOffset(numf);
	}

	// Calculate the variable length for new()
	// @param numf - number of fields in this record
	// @param paylen - length of the payload
	static intptr_t variableLen(int numf, intptr_t paylen)
	{
		// not numf+1, because off_ already has 1 element
		return sizeof(off_[0]) * numf + paylen;
	}

	// this is mostly for debugging
	const int32_t &getOffset(int n) const
	{
		return off_[n];
	}

	// Check whether the row is all empty, by checking that the total
	// length of the payload is 0. Technically, the fields don't have to be
	// marked as null for the row to be empty.
	// @param numf - number of fields in this record
	bool isRowEmpty(int numf) const
	{
		// the past-the-end offset never has the NULLMASK in it
		return (off_[numf] == payloadOffset(numf));
	}

protected:
	friend class CompactRowType;

protected:
	// internal structure:
	//    off_[0]  - offset of first field
	//    ...
	//    off_[N] - offset of last field
	//    off_[N+1] - offset past the last field
	//    data_bytes
	//
	// The C++ compiler tends to bitch at the offsetof() macro, so the offsets
	// are relative to &off_[0];
	//
	// The offsets are 31-bit, masked by OFFMASK. The high bit (NULLMASK) shows
	// whether the field is null. The low 31 bits of a null field's offset
	// still contain a valid value, pointing to the next non-null field.
	//
	// There is no field count stored, CompactRowType is supposed to know it.
	//
	// At the logical level, a "field" may be an array. But here nobody cares,
	// a field is just a string of bytes. No alignment is provided, the fields
	// are just placed one after the other.
	enum { OFFMASK = 0x7FFFFFFF, NULLMASK = 0x80000000 };
	int32_t off_[1]; // really bigger
};

}; // TRICEPS_NS

#endif // __Triceps_CompactRow_h__
