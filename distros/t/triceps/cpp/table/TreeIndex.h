//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Implementation of a simple primary key.

#ifndef __Triceps_TreeIndex_h__
#define __Triceps_TreeIndex_h__

#include <table/Index.h>
#include <type/TreeIndexType.h>

namespace TRICEPS_NS {

class RowType;

class TreeIndex: public Index
{
	friend class TreeIndexType;

public:
	typedef TreeIndexType::Less Less;
	typedef TreeIndexType::Set Set;

	// @param tabtype - type of table where this index belongs
	// @param table - the actual table where this index belongs
	// @param mytype - type that created this index
	// @param lessop - less functor class for the key, this index will keep a reference
	//        (it should be a private copy created from the IndexType's functor and knowing
	//        about the table, if it ever wants to report any errors)
	TreeIndex(const TableType *tabtype, Table *table, const TreeIndexType *mytype, Less *lessop);
	~TreeIndex();

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

protected:
	Set data_; // the data store
	Autoref<const TreeIndexType> type_; // type of this index
	Autoref<Less> less_; // the comparator object, index's own copy
};

}; // TRICEPS_NS

#endif // __Triceps_TreeIndex_h__
