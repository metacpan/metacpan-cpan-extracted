//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Implementation of a simple primary key with further nesting.

#include <table/TreeNestedIndex.h>
#include <type/TreeIndexType.h>
#include <type/RowType.h>

namespace TRICEPS_NS {

//////////////////////////// TreeNestedIndex /////////////////////////

TreeNestedIndex::TreeNestedIndex(const TableType *tabtype, Table *table, const TreeIndexType *mytype, Less *lessop) :
	Index(tabtype, table),
	data_(*lessop),
	type_(mytype),
	less_(lessop)
{ }

TreeNestedIndex::~TreeNestedIndex()
{
	vector<GroupHandle *> groups;
	groups.reserve(data_.size());
	for (Set::iterator it = data_.begin(); it != data_.end(); ++it) {
		groups.push_back(static_cast<GroupHandle *>(*it));
	}
	data_.clear();
	size_t n = groups.size();
	for (size_t i = 0; i < n; i++) {
		GroupHandle *gh = groups[i];
		if (gh->decref() <= 0)
			type_->destroyGroupHandle(gh);
	}
}

void TreeNestedIndex::clearData()
{
	// pass recursively into the groups
	for (Set::iterator it = data_.begin(); it != data_.end(); ++it) {
		type_->groupClearData(static_cast<GroupHandle *>(*it));
	}
}

const IndexType *TreeNestedIndex::getType() const
{
	return type_;
}

RowHandle *TreeNestedIndex::begin() const
{
	Set::iterator it = data_.begin();
	if (it == data_.end())
		return NULL;
	else {
		RowHandle *rh = type_->beginIteration(static_cast<GroupHandle *>(*it));
		if (rh == NULL) {
			// the first group may be empty while there is another non-empty group:
			// could happen when a new group is already created but not yet
			// populated during aggregation
			while (rh == NULL && ++it != data_.end()) {
				rh = type_->beginIteration(static_cast<GroupHandle *>(*it));
			}
		}
		return rh;
	}
}

RowHandle *TreeNestedIndex::next(const RowHandle *cur) const
{
	// fprintf(stderr, "DEBUG TreeNestedIndex::next(this=%p, cur=%p)\n", this, cur);
	if (cur == NULL || !cur->isInTable())
		return NULL;

	Set::iterator it = type_->getIter(cur); // row is known to be in the table

	if (it == data_.end())
		return NULL; // should never happen

	RowHandle *res = type_->nextIteration(static_cast<GroupHandle *>(*it), cur);
	// fprintf(stderr, "DEBUG TreeNestedIndex::next(this=%p) nextIteration local return=%p\n", this, res);
	if (res != NULL)
		return res;

	// otherwise try the next groups until find a non-empty one
	for (++it; it != data_.end(); ++it) {
		RowHandle *res = type_->beginIteration(static_cast<GroupHandle *>(*it));
		// fprintf(stderr, "DEBUG TreeNestedIndex::next(this=%p) beginIteration return=%p\n", this, res);
		if (res != NULL)
			return res;
	}
	// fprintf(stderr, "DEBUG TreeNestedIndex::next(this=%p) return NULL\n", this);

	return NULL;
}

RowHandle *TreeNestedIndex::last() const
{
	if (data_.empty()) {
		return NULL;
	} else {
		Set::iterator it = data_.end();
		// decrease is OK because the set has bidirectional iterators
		RowHandle *rh = type_->last(static_cast<GroupHandle *>(*--it));
		if (rh == NULL) {
			// the last group may be empty while there is another non-empty group:
			// could happen when a new group is already created but not yet
			// populated during aggregation
			Set::iterator first = data_.begin();
			while (rh == NULL && it != first) {
				rh = type_->last(static_cast<GroupHandle *>(*--it));
			}
		}
		return rh;
	}
}

const GroupHandle *TreeNestedIndex::nextGroup(const GroupHandle *cur) const
{
	// fprintf(stderr, "DEBUG TreeNestedIndex::nextGroup(this=%p, cur=%p)\n", this, cur);
	if (cur == NULL)
		return NULL;
	Set::iterator it = type_->getIter(cur);
	++it;
	if (it == data_.end())
		return NULL; 
	// fprintf(stderr, "DEBUG TreeNestedIndex::nextGroup(this=%p, cur=%p) return %p\n", this, cur, *it);
	return static_cast<const GroupHandle *>(*it);
}

const GroupHandle *TreeNestedIndex::beginGroup() const
{
	if (data_.empty())
		return NULL;
	else
		return static_cast<const GroupHandle *>(*data_.begin());
}

const GroupHandle *TreeNestedIndex::toGroup(const RowHandle *cur) const
{
	Set::iterator it = type_->getIter(cur); // row is known to be in the table
	return static_cast<const GroupHandle *>(*it);
}

RowHandle *TreeNestedIndex::find(const RowHandle *what) const
{
	return NULL; // no records directly here
}

Index *TreeNestedIndex::findNested(const RowHandle *what, int nestPos) const
{
	// fprintf(stderr, "DEBUG TreeNestedIndex::findNested(this=%p, what=%p, nestPos=%d)\n", this, what, nestPos);
	if (what == NULL) {
		if (data_.empty())
			return NULL;
		Set::iterator it = data_.begin();
		Index *idx = type_->groupToIndex(static_cast<GroupHandle *>(*it), nestPos);
		// fprintf(stderr, "DEBUG TreeNestedIndex::findNested(this=%p) return index %p\n", this, idx);
		return idx;
	} else {
		Set::iterator it = data_.find(const_cast<RowHandle *>(what));
		if (it == data_.end()) {
			// fprintf(stderr, "DEBUG TreeNestedIndex::findNested(this=%p) return NULL\n", this);
			return NULL;
		} else {
			Index *idx = type_->groupToIndex(static_cast<GroupHandle *>(*it), nestPos);
			// fprintf(stderr, "DEBUG TreeNestedIndex::findNested(this=%p) return index %p\n", this, idx);
			return idx;
		}
	}
}

bool TreeNestedIndex::replacementPolicy(RowHandle *rh, RhSet &replaced)
{
	Set::iterator it = data_.find(rh);
	// the result of find() has to be stored now in rh, to avoid look-up on insert
	type_->setIter(rh, it);
	GroupHandle *gh;
	// fprintf(stderr, "DEBUG TreeNestedIndex::replacementPolicy(this=%p, rh=%p) put iterValid=%d\n", this, rh, it != data_.end());

	if (it == data_.end()) {
		gh = type_->makeGroupHandle(rh, table_);
		gh->incref();
		pair<Set::iterator, bool> res = data_.insert(gh);
		type_->setIter(rh, res.first);
		type_->setIter(gh, res.first);
	} else {
		gh = static_cast<GroupHandle *>(*it);
	}
	return type_->groupReplacementPolicy(gh, rh, replaced);
}

void TreeNestedIndex::insert(RowHandle *rh)
{
	Set::iterator it = type_->getIter(rh); // has been initialized in replacementPolicy()
	// fprintf(stderr, "DEBUG TreeNestedIndex::insert(this=%p, rh=%p) put iterValid=%d\n", this, rh, it != data_.end());

	type_->groupInsert(static_cast<GroupHandle *>(*it), rh);
}

void TreeNestedIndex::remove(RowHandle *rh)
{
	Set::iterator it = type_->getIter(rh); // row is known to be in the table
	type_->groupRemove(static_cast<GroupHandle *>(*it), rh);
}

void TreeNestedIndex::splitRhSet(const RhSet &rows, SplitMap &dest)
{
	for(RhSet::iterator rsi = rows.begin(); rsi != rows.end(); ++rsi) {
		RowHandle *rh = *rsi;
		Set::iterator si = type_->getIter(rh); // row is known to still be in the set
		dest[static_cast<GroupHandle *>(*si)].insert(rh);
	}
}

void TreeNestedIndex::aggregateBefore(Tray *dest, const RhSet &rows, const RhSet &already)
{
	SplitMap splitRows, splitAlready;
	splitRhSet(rows, splitRows);
	if (!already.empty())
		splitRhSet(already, splitAlready);

	for(SplitMap::iterator smi = splitRows.begin(); smi != splitRows.end(); ++smi) {
		GroupHandle *gh = smi->first;
		if (already.empty()) { // a little optimization
			type_->groupAggregateBefore(dest, table_, gh, smi->second, already);
		} else {
			// this automatically creates a new entry in splitAlready if it was missing
			type_->groupAggregateBefore(dest, table_, gh, smi->second, splitAlready[gh]);
		}
	}
}

void TreeNestedIndex::aggregateAfter(Tray *dest, Aggregator::AggOp aggop, const RhSet &rows, const RhSet &future)
{
	SplitMap splitRows, splitFuture;
	splitRhSet(rows, splitRows);
	if (!future.empty())
		splitRhSet(future, splitFuture);

	for(SplitMap::iterator smi = splitRows.begin(); smi != splitRows.end(); ++smi) {
		GroupHandle *gh = smi->first;
		if (future.empty()) { // a little optimization
			type_->groupAggregateAfter(dest, aggop, table_, gh, smi->second, future);
		} else {
			// this automatically creates a new entry in splitFuture if it was missing
			type_->groupAggregateAfter(dest, aggop, table_, gh, smi->second, splitFuture[gh]);
		}
	}
}

bool TreeNestedIndex::collapse(Tray *dest, const RhSet &replaced)
{
	// fprintf(stderr, "DEBUG TreeNestedIndex::collapse(this=%p, rhset size=%d)\n", this, (int)replaced.size());
	
	// split the set into subsets by iterator
	SplitMap split;
	splitRhSet(replaced, split);

	bool res = true;

	// handle each subset's group
	for(SplitMap::iterator smi = split.begin(); smi != split.end(); ++smi) {
		GroupHandle *gh = smi->first;
		// fprintf(stderr, "DEBUG TreeNestedIndex::collapse(this=%p) gh=%p\n", this, gh);
		if (type_->groupCollapse(dest, gh, smi->second)) {
			// fprintf(stderr, "DEBUG TreeNestedIndex::collapse(this=%p) gh=%p destroying\n", this, gh);
			// call the aggregators to process collapse
			if (!type_->groupAggs_.empty()) {
				type_->aggregateCollapse(dest, table_, gh);
			}
			// destroy the group
			data_.erase(type_->getIter(gh)); // after this the iterator in gh is not valid any more
			if (gh->decref() <= 0)
				type_->destroyGroupHandle(gh);
		} else {
			// fprintf(stderr, "DEBUG TreeNestedIndex::collapse(this=%p) gh=%p not collapsing\n", this, gh);
			// a group objects to being collapsed
			res = false;
		}
	}

	return res;
}


}; // TRICEPS_NS
