//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// The base class for aggregation gadgets.

#include <sched/AggregatorGadget.h>
#include <type/AggregatorType.h>
#include <type/RowType.h>
#include <type/TableType.h>
#include <table/Table.h>

namespace TRICEPS_NS {

AggregatorGadget::AggregatorGadget(const AggregatorType *type, Table *table, IndexType *intype) :
	Gadget(table->getUnit(), table->getEnqMode(), table->getName() + "." + type->getName(), type->getRowType()),
	table_(table),
	type_(type),
	indexType_(intype)
{ }

void AggregatorGadget::sendDelayed(Tray *dest, FdataVec &data, Rowop::Opcode opcode) const
{
	if (mode_ != EM_IGNORE) {
		Gadget::sendDelayed(dest, label_->getType()->makeRow(data), opcode);
	}
}

}; // TRICEPS_NS
