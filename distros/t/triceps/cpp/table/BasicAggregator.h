//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Aggregator through a basic C-style callback function.

#ifndef __Triceps_BasicAggregator_h__
#define __Triceps_BasicAggregator_h__

#include <table/Aggregator.h>

namespace TRICEPS_NS {

class AggregatorGadget;
class Table;

class BasicAggregator : public Aggregator
{
public:
	// from Aggregator
	virtual void handle(Table *table, AggregatorGadget *gadget, Index *index,
		const IndexType *parentIndexType, GroupHandle *gh, Tray *dest,
		AggOp aggop, Rowop::Opcode opcode, RowHandle *rh);
};

}; // TRICEPS_NS

#endif // __Triceps_BasicAggregator_h__
