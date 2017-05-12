//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// The type building for RowHandles.

#include <type/RowHandleType.h>
#include <table/RowHandle.h>
#include <table/Table.h>

namespace TRICEPS_NS {

////////////////////////////// RowHandleType ///////////////////////

RowHandleType::RowHandleType() :
	Type(false, TT_RH),
	size_(0)
{ }

RowHandleType::RowHandleType(const RowHandleType &orig) :
	Type(false, TT_RH),
	size_(orig.size_)
{ }

intptr_t RowHandleType::allocate(size_t amount)
{
	intptr_t prev = size_; // last size is alreasy aligned
	size_ += amount;
	intptr_t rem = size_ % sizeof(RowHandle::AlignType);
	if (rem != 0) {
		size_ += sizeof(RowHandle::AlignType) - rem;
	}
	return prev;
}

// from Type
Erref RowHandleType::getErrors() const
{
	return NULL;
}

void RowHandleType::printTo(string &res, const string &indent, const string &subindent) const
{
	// this never should get actually printed
	res.append("**rowHandle**");
}

}; // TRICEPS_NS

