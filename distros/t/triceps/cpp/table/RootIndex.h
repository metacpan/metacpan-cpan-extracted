//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// The pseudo-index for the root of the index tree.

#ifndef __Triceps_RootIndex_h__
#define __Triceps_RootIndex_h__

#include <table/Index.h>
#include <type/RootIndexType.h>

namespace TRICEPS_NS {

class RootIndexType;
class RowType;

class RootIndex: public Index
{
	friend class RootIndexType;
public:
	// @param tabtype - type of table where this index belongs
	// @param table - the actual table where this index belongs
	// @param mytype - type that created this index
	RootIndex(const TableType *tabtype, Table *table, const RootIndexType *mytype);
	~RootIndex();

	// from Index
	virtual void clearData();
	virtual const IndexType *getType() const;
	virtual RowHandle *begin() const;
	virtual RowHandle *next(const RowHandle *cur) const;
	virtual RowHandle *last() const;
	virtual const GroupHandle *nextGroup(const GroupHandle *cur) const;
	virtual const GroupHandle *beginGroup() const;
	virtual const GroupHandle *toGroup(const RowHandle *cur) const;
	virtual RowHandle *find(const RowHandle *what) const;
	virtual bool replacementPolicy(RowHandle *rh, RhSet &replaced);
	virtual void insert(RowHandle *rh);
	virtual void remove(RowHandle *rh);
	virtual void aggregateBefore(Tray *dest, const RhSet &rows, const RhSet &already);
	virtual void aggregateAfter(Tray *dest, Aggregator::AggOp aggop, const RhSet &rows, const RhSet &future);
	virtual bool collapse(Tray *dest, const RhSet &replaced);
	virtual Index *findNested(const RowHandle *what, int nestPos) const;

	// Get the number of records in this index
	size_t size() const;

protected:
	Autoref<const RootIndexType> type_; // type of this index
	GroupHandle *rootg_; // the root group
};

}; // TRICEPS_NS

#endif // __Triceps_RootIndex_h__
