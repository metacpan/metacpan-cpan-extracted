//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// The pseudo-index for the root of the index tree.

#include <table/RootIndex.h>
#include <type/RowType.h>

namespace TRICEPS_NS {

//////////////////////////// RootIndex /////////////////////////

RootIndex::RootIndex(const TableType *tabtype, Table *table, const RootIndexType *mytype) :
	Index(tabtype, table),
	type_(mytype),
	rootg_(NULL)
{ }

RootIndex::~RootIndex()
{
	// the Table will take care of the records but for now need to free the group
	if (rootg_) {
		if (rootg_->decref() <= 0)
			type_->destroyGroupHandle(rootg_);
	}
}

void RootIndex::clearData()
{ 
	type_->groupClearData(rootg_);
}

const IndexType *RootIndex::getType() const
{
	return type_;
}

RowHandle *RootIndex::begin() const
{
	return type_->beginIteration(rootg_);
}

RowHandle *RootIndex::next(const RowHandle *cur) const
{
	return type_->nextIteration(rootg_, cur);
}

RowHandle *RootIndex::last() const
{
	return type_->last(rootg_);
}

const GroupHandle *RootIndex::nextGroup(const GroupHandle *cur) const
{
	// The root index has only one group, nowhere to go next.
	// (And anyway IndexType::nextGroupHandle() will never call here).
	return NULL;
}

const GroupHandle *RootIndex::beginGroup() const
{
	return rootg_; // only one group, everything must be there
}

const GroupHandle *RootIndex::toGroup(const RowHandle *cur) const
{
	// fprintf(stderr, "DEBUG RootIndex::toGroup(this=%p) return %p\n", this, rootg_);
	return rootg_; // only one group, everything must be there
}

RowHandle *RootIndex::find(const RowHandle *what) const
{
	return NULL; // no records directly here
}

Index *RootIndex::findNested(const RowHandle *what, int nestPos) const
{
	Index *idx = type_->groupToIndex(rootg_, nestPos);
	// fprintf(stderr, "DEBUG RootIndex::findNested(this=%p) return index %p\n", this, idx);
	return idx;
}

bool RootIndex::replacementPolicy(RowHandle *rh, RhSet &replaced)
{
	// fprintf(stderr, "DEBUG RootIndex::replacementPolicy(this=%p, rh=%p)\n", this, rh);
	if (rootg_ == NULL) {
		// create a new group
		rootg_ = type_->makeGroupHandle(rh, table_);
		rootg_->incref();
	}
	return type_->groupReplacementPolicy(rootg_, rh, replaced);
}

void RootIndex::insert(RowHandle *rh)
{
	type_->groupInsert(rootg_, rh);
}

void RootIndex::remove(RowHandle *rh)
{
	type_->groupRemove(rootg_, rh);
}

void RootIndex::aggregateBefore(Tray *dest, const RhSet &rows, const RhSet &already)
{
	type_->groupAggregateBefore(dest, table_, rootg_, rows, already);
}

void RootIndex::aggregateAfter(Tray *dest, Aggregator::AggOp aggop, const RhSet &rows, const RhSet &future)
{
	type_->groupAggregateAfter(dest, aggop, table_, rootg_, rows, future);
}

size_t RootIndex::size() const
{
	return type_->groupSize(rootg_);
}

bool RootIndex::collapse(Tray *dest, const RhSet &replaced)
{
	// fprintf(stderr, "DEBUG RootIndex::collapse(this=%p, rhset size=%d) rootg_=%p\n", this, (int)replaced.size(), rootg_);
	if (rootg_ == NULL)
		return true;
	type_->groupCollapse(dest, rootg_, replaced);
	return false; // the root index never collapses its group
}

}; // TRICEPS_NS
