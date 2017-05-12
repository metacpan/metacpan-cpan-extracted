//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Implementation of a simple FIFO storage.

#include <table/FifoIndex.h>
#include <type/TableType.h>

namespace TRICEPS_NS {

//////////////////////////// FifoIndex /////////////////////////

FifoIndex::FifoIndex(const TableType *tabtype, Table *table, const FifoIndexType *mytype) :
	Index(tabtype, table),
	type_(mytype),
	first_(NULL),
	last_(NULL),
	size_(0)
{ }

FifoIndex::~FifoIndex()
{
	// the Table will take care of the records
}

void FifoIndex::clearData()
{
	first_ = last_ = NULL;
	size_ = 0;
}

const IndexType *FifoIndex::getType() const
{
	return type_;
}

RowHandle *FifoIndex::begin() const
{
	if (type_->isReverse())
		return last_;
	else
		return first_;
}

RowHandle *FifoIndex::next(const RowHandle *cur) const
{
	if (cur == NULL || !cur->isInTable())
		return NULL;

	RhSection *rs = getSection(cur);
	if (type_->isReverse())
		return rs->prev_;
	else
		return rs->next_;
}

RowHandle *FifoIndex::last() const
{
	if (type_->isReverse())
		return first_;
	else
		return last_;
}

const GroupHandle *FifoIndex::nextGroup(const GroupHandle *cur) const
{
	return NULL;
}

const GroupHandle *FifoIndex::beginGroup() const
{
	return NULL;
}

const GroupHandle *FifoIndex::toGroup(const RowHandle *cur) const
{
	return NULL;
}

RowHandle *FifoIndex::find(const RowHandle *what) const
{
	// Find by sequential comparison of whole rows
	const Row *rwhat = what->getRow();
	RowHandle *curh = first_;
	while(curh != NULL) {
		if (type_->getTabtype()->rowType()->equalRows(rwhat, curh->getRow()))
			return curh;

		RhSection *rs = getSection(curh);
		curh = rs->next_;
	}
	return NULL; // not found
}

Index *FifoIndex::findNested(const RowHandle *what, int nestPos) const
{
	return NULL;
}

bool FifoIndex::replacementPolicy(RowHandle *rh, RhSet &replaced)
{
	size_t limit = type_->getLimit();
	if (limit == 0)
		return true; // no limit, nothing replaced

	// Check if there is any row already marked for replacement and present in this index, 
	// then don't push out another one.
	size_t subtract = 0;
	for (RhSet::iterator it = replaced.begin(); it != replaced.end(); ++it) {
		Index *rind = type_->findInstance(table_, *it);
		if (rind == this)
			++subtract; // it belongs here, so a record will be already pushed out
	}

	if (size_ - subtract >= limit && size_ >= subtract) { // this works well only with one-at-a-time inserts
		if (type_->isJumping()) {
			RowHandle *curh = first_;
			while(curh != NULL) {
				replaced.insert(curh); 

				RhSection *rs = getSection(curh);
				curh = rs->next_;
			}
		} else {
			replaced.insert(first_); 
		}
	}
		
	return true;
}

void FifoIndex::insert(RowHandle *rh)
{
	RhSection *rs = getSection(rh);

	if (first_ == NULL) {
		rs->next_ = NULL;
		rs->prev_ = NULL;
		first_ = last_ = rh;
	} else {
		rs->next_ = NULL;
		rs->prev_ = last_;
		RhSection *lastrs = getSection(last_);
		lastrs->next_ = rh;
		last_ = rh;
	}
	++size_;
}

void FifoIndex::remove(RowHandle *rh)
{
	RhSection *rs = getSection(rh);

	if (first_ == rh) {
		if (last_ == rh) {
			first_ = last_ = NULL; // that was the last row
		} else {
			first_ = rs->next_;
			RhSection *nextrs = getSection(first_);
			nextrs->prev_ = NULL;
		}
	} else if (last_ == rh) {
		last_ = rs->prev_;
		RhSection *prevrs = getSection(last_);
		prevrs->next_ = NULL;
	} else {
		RhSection *nextrs = getSection(rs->next_);
		RhSection *prevrs = getSection(rs->prev_);
		prevrs->next_ = rs->next_;
		nextrs->prev_ = rs->prev_;
	}
	rs->prev_ = rs->next_ = NULL;
	--size_;
}

void FifoIndex::aggregateBefore(Tray *dest, const RhSet &rows, const RhSet &already)
{ 
	// nothing to do
}

void FifoIndex::aggregateAfter(Tray *dest, Aggregator::AggOp aggop, const RhSet &rows, const RhSet &future)
{ 
	// nothing to do
}

bool FifoIndex::collapse(Tray *dest, const RhSet &replaced)
{
	return true;
}

}; // TRICEPS_NS
