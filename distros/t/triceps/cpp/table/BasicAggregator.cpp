//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Aggregator through a basic C-style callback function.

#include <type/BasicAggregatorType.h>
#include <table/BasicAggregator.h>
#include <sched/AggregatorGadget.h>

namespace TRICEPS_NS {

void BasicAggregator::handle(Table *table, AggregatorGadget *gadget, Index *index,
	const IndexType *parentIndexType, GroupHandle *gh, Tray *dest,
	AggOp aggop, Rowop::Opcode opcode, RowHandle *rh)
{
	const BasicAggregatorType *at = static_cast<const BasicAggregatorType *>(gadget->getType());
	at->cb_(table, gadget, index, parentIndexType, gh, dest, aggop, opcode, rh);
}

}; // TRICEPS_NS
