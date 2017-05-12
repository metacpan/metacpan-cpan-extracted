//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// The base class for aggregation gadgets.

#ifndef __Triceps_AggregatorGadget_h__
#define __Triceps_AggregatorGadget_h__

#include <sched/Gadget.h>

namespace TRICEPS_NS {

class Table;
class AggregatorType;
class IndexType;

// It's a common gadget, only it picks the front part
// of the name, row type and queueing mode automatically from the table.
//
// Fundamentally there is no reason to have the same common
// enqueueing mode for all the gadgets in the table. 
// But there is no easy way to specify the separate modes for all the
// aggregators at the table creation time. So initially set the modes
// all the same and then let the user change them if desired.
class AggregatorGadget : public Gadget
{
public:
	// @param type - type that created this gadget, will be referenced, provides the row type
	//        and name part after dot
	// @param table - table where this gadget belongs, provides the part of name before dot,
	//        unit and enqueueing mode
	// @param intype - type of the index on which this aggregation happens
	//        (the set of rows in an index instance are the rows for aggregation)
	AggregatorGadget(const AggregatorType *type, Table *table, IndexType *intype);

	// Get the table where this gadget belongs
	Table *getTable() const
	{
		return table_;
	}

	// Get back the aggregation type
	const AggregatorType *getType() const
	{
		return type_;
	}
	// version with embedded type-casting
	template<class C>
	const C *typeAs() const
	{
		return static_cast<const C*>(type_.get());
	}

	// Get back the index type
	const IndexType *getIndexType() const
	{
		return indexType_;
	}

	// export the sendDelayed() interface
	void sendDelayed(Tray *dest, const Row *row, Rowop::Opcode opcode) const
	{
		Gadget::sendDelayed(dest, row, opcode);
	}

	// a convenience version of sendDelayed() that constructs the
	// row from fields and sends it
	void sendDelayed(Tray *dest, FdataVec &data, Rowop::Opcode opcode) const;

protected:
	Table *table_;
	const_Autoref<AggregatorType> type_;
	const_Autoref<IndexType> indexType_;

private:
	// prevent the accidental use of send(), it must not be used with aggregators
	void send(const Row *row, Rowop::Opcode opcode) const;
};

}; // TRICEPS_NS

#endif // __Triceps_AggregatorGadget_h__
