//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// A tray for passing the rowops across the nexuses.

#ifndef __Triceps_Xtray_h__
#define __Triceps_Xtray_h__

#include <vector>
#include <common/Common.h>
#include <sched/Rowop.h>
#include <type/RowSetType.h>

namespace TRICEPS_NS {

// It's like a tray but carries the rowops in a special representation
// to the different trays.
// The memory management is a bit weird, with Xtray directly controlling the
// references to all the rows in it (as opposed to the normal Rowop doing
// its own control and normal Tray just collecting the rowops).
//
// The normal lifecycle of an Xtray is to be created on one thread,
// then sent to a Nexus. Then be read from there by the other threads.
// Once the Xtray is populated and sent on, it becomes fixed and
// can not be modified any more. As long as this rule is observed,
// there is no need for synchronization for the data access.
// The only item that needs synchronization is the Mtarget reference count.
class Xtray: public Mtarget
{
public:
	// Value of sequential id of Xtray in the Nexus queue.
	// The id doesn't have to be unique though the life of nexus,
	// just its period has to be longer than the queue length
	// limit.
	typedef int32_t QueId;
	static const QueId QUE_ID_MAX; // max value of the QueId type

	// One rowop equivalent for traveling through the nexus.
	class Op
	{
	public:
		// The constructor silently strips the const-ness of the row.
		Op(int idx, const Row *row, Rowop::Opcode op):
			row_(const_cast<Row *>(row)),
			idx_(idx),
			opcode_(op)
		{ }

		Row *row_; // will be referenced manually when Op is inserted into Xtray
		int idx_; // index of this row's type in the nexus type; -1 has a special meaning:
			// the boundary between multiple transactions clumped into one Xtray,
			// in this case row_ must be NULL
		Rowop::Opcode opcode_;
	};

	// Create an xtray for a nexus.
	// @param rst - type of the nexus
	Xtray(RowSetType *rst);
	~Xtray();

	// Get the number of ops.
	int size() const
	{
		return (int)ops_.size();
	}

	// Check if it's empty.
	bool empty() const
	{
		return ops_.empty();
	}

	// Add a new Op.
	// Assumes that the index of the row type is correct.
	// @param data - a prototype to add
	void push_back(const Op &data);

	// Add a new Op from individual elements.
	// Assumes that the index of the row type is correct.
	// @param idx - index of the row type in the row set
	// @param row - row of this type
	// @param opcode - opcode of the rowop
	void push_back(int idx, const Row *row, Rowop::Opcode opcode)
	{
		push_back(Op(idx, row, opcode));
	}

	// Get an op at the index.
	// @param idx - the index to read at, must be within the size
	// @return - the element reference, that must not be modified
	const Op &at(int idx) const
	{
		return ops_[idx];
	}

	// Get the idx of the first Op in the Xtray.
	// May not be used if the Xtray is empty.
	int frontIdx() const
	{
		return ops_.front().idx_;
	}

	// Get the idx of the last Op in the Xtray.
	// May not be used if the Xtray is empty.
	int backIdx() const
	{
		return ops_.back().idx_;
	}

protected:
	Autoref<RowSetType> type_; // type of the nexus, also row types from it are used
		// to un-reference the Rows and destroy them if needed
	typedef vector<Op> OpVec;
	OpVec ops_; // the data

private:
	Xtray();
	Xtray(const Xtray &);
	void operator=(const Xtray &);
};

}; // TRICEPS_NS

#endif // __Triceps_Xtray_h__
