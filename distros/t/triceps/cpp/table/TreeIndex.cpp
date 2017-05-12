//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Implementation of a simple primary key.

#include <table/TreeIndex.h>
#include <type/TreeIndexType.h>
#include <type/RowType.h>

namespace TRICEPS_NS {

//////////////////////////// TreeIndex /////////////////////////

TreeIndex::TreeIndex(const TableType *tabtype, Table *table, const TreeIndexType *mytype, Less *lessop) :
	Index(tabtype, table),
	data_(*lessop),
	type_(mytype),
	less_(lessop)
{ }

TreeIndex::~TreeIndex()
{
	assert(data_.empty());
}

void TreeIndex::clearData()
{
	data_.clear();
}

const IndexType *TreeIndex::getType() const
{
	return type_;
}

RowHandle *TreeIndex::begin() const
{
	Set::iterator it = data_.begin();
	// fprintf(stderr, "DEBUG TreeIndex::begin(this=%p) found %p (of %d)\n", this, (it == data_.end()?NULL:*it), (int)data_.size());
	if (it == data_.end())
		return NULL;
	else
		return *it;
}

RowHandle *TreeIndex::next(const RowHandle *cur) const
{
	// fprintf(stderr, "DEBUG TreeIndex::next(this=%p, cur=%p)\n", this, cur);
	if (cur == NULL || !cur->isInTable())
		return NULL;

	Set::iterator it = type_->getIter(cur);
	++it;
	// fprintf(stderr, "DEBUG TreeIndex::next(this=%p, cur=%p) found %p (of %d)\n", this, cur, (it == data_.end()?NULL:*it), (int)data_.size());
	if (it == data_.end()) {
		// fprintf(stderr, "DEBUG TreeIndex::next(this=%p) return NULL\n", this);
		return NULL;
	} else {
		// fprintf(stderr, "DEBUG TreeIndex::next(this=%p) return %p\n", this, *it);
		return *it;
	}
}

RowHandle *TreeIndex::last() const
{
	if (data_.empty()) {
		return NULL;
	} else {
		Set::iterator it = data_.end();
		--it; // OK because the set has bidirectional iterators
		return *it;
	}
}

const GroupHandle *TreeIndex::nextGroup(const GroupHandle *cur) const
{
	return NULL;
}

const GroupHandle *TreeIndex::beginGroup() const
{
	return NULL;
}

const GroupHandle *TreeIndex::toGroup(const RowHandle *cur) const
{
	return NULL;
}

RowHandle *TreeIndex::find(const RowHandle *what) const
{
	Set::iterator it = data_.find(const_cast<RowHandle *>(what));
	// fprintf(stderr, "DEBUG TreeIndex::find(this=%p, what=%p) found %p (of %d)\n", this, what, (it == data_.end()?NULL:*it), (int)data_.size());
	if (it == data_.end())
		return NULL;
	else
		return (*it);
}

Index *TreeIndex::findNested(const RowHandle *what, int nestPos) const
{
	return NULL;
}

bool TreeIndex::replacementPolicy(RowHandle *rh, RhSet &replaced)
{
	Set::iterator old = data_.find(rh);
	// XXX for now just silently replace the old value with the same key
	if (old != data_.end())
		replaced.insert(*old);
	return true;
}

void TreeIndex::insert(RowHandle *rh)
{
	pair<Set::iterator, bool> res = data_.insert(const_cast<RowHandle *>(rh));
	assert(res.second); // must always succeed
	type_->setIter(rh, res.first);
	// fprintf(stderr, "DEBUG TreeIndex::insert(this=%p, rh=%p, rs=%p)\n", this, rh, type_->getSection(rh));
}

void TreeIndex::remove(RowHandle *rh)
{
	// fprintf(stderr, "DEBUG TreeIndex::remove(this=%p, rh=%p, rs=%p)\n", this, rh, type_->getSection(rh));
	data_.erase(type_->getIter(rh));
}

void TreeIndex::aggregateBefore(Tray *dest, const RhSet &rows, const RhSet &already)
{ 
	// nothing to do
}

void TreeIndex::aggregateAfter(Tray *dest, Aggregator::AggOp aggop, const RhSet &rows, const RhSet &future)
{ 
	// nothing to do
}

bool TreeIndex::collapse(Tray *dest, const RhSet &replaced)
{
	// fprintf(stderr, "DEBUG TreeIndex::collapse(this=%p, rhset size=%d)\n", this, (int)replaced.size());
	return true;
}


}; // TRICEPS_NS
