//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Aggregator through a basic C-style callback function.

#ifndef __Triceps_BasicAggregatorType_h__
#define __Triceps_BasicAggregatorType_h__

#include <type/AggregatorType.h>
#include <table/Aggregator.h>

namespace TRICEPS_NS {

class BasicAggregator;
class Table;
class Index;
class RowHandle;

// Aggregator that keeps no state, every time recalculates the
// result row from scratch with a basic C-style function.
class BasicAggregatorType : public AggregatorType
{
public:
	// type of callback function, see Aggregator::handle()
	typedef void Callback(Table *table, AggregatorGadget *gadget, Index *index,
		const IndexType *parentIndexType, GroupHandle *gh, Tray *dest,
		Aggregator::AggOp aggop, Rowop::Opcode opcode, RowHandle *rh);

	// @param name - name for aggregators' gadget in the table, will be tablename.name
	// @param rt - type of rows produced by this aggregator, wil be referenced
	// @param cb - pointer to the callback function
	BasicAggregatorType(const string &name, const RowType *rt, Callback *cb);
	// the default copy constructor also works well
	
	// for deep copy
	BasicAggregatorType(const BasicAggregatorType &agg, HoldRowTypes *holder);

	// from Type
	virtual bool equals(const Type *t) const;
	virtual bool match(const Type *t) const;

	// from AggregatorType
	virtual AggregatorType *copy() const;
	virtual AggregatorType *deepCopy(HoldRowTypes *holder) const;
	// creates just the generic AggregatorGadget, nothing special
	virtual AggregatorGadget *makeGadget(Table *table, IndexType *intype) const;
	virtual Aggregator *makeAggregator(Table *table, AggregatorGadget *gadget) const;

protected:
	friend class BasicAggregator;

	Callback *cb_;
};

}; // TRICEPS_NS

#endif // __Triceps_BasicAggregatorType_h__
