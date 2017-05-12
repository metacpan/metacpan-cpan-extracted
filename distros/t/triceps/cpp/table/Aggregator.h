//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// The base class for aggregators.

#ifndef __Triceps_Aggregator_h__
#define __Triceps_Aggregator_h__

#include <sched/Rowop.h>
#include <table/RowHandle.h>

namespace TRICEPS_NS {

class Index;
class IndexType;
class GroupHandle;
class AggregatorGadget;
class Tray;

// The Aggregator is always owned by the index group (OK, logically it can be thought
// that it's owned by an index but really by a group), which always works single-threaded.
// So there is not much point in refcounting it, and this saves a few bytes pre instance.
class Aggregator
{
public:
	virtual ~Aggregator();

	// Should there be one virtual functions with an operation selector argument
	// or multiple virtual functions? There are benefits in both solutions, so
	// for now pick the one that should be easier to interface with C and Perl code.
	
	// Operation selector
	enum AggOp {
		AO_BEFORE_MOD, // before modification
		AO_AFTER_DELETE, // after row removal has been performed
		AO_AFTER_INSERT, // after row insertion was performed
		AO_COLLAPSE, // when the group is being collapsed
	};

	// Convert the AggOp to string and back
	static const char *aggOpString(int code, const char *def = "???");
	static int stringAggOp(const char *code);

	// Handle one operation on the group.
	// Updates the internal state of the aggregator and possibly sends (delayed) information
	// about the changes to the Gadget. 
	//
	// @param table - table on which the change happens
	// @param gadget - gadget of this aggregator, where to send the Rowops
	// @param index - index on which this aggregator is defined, contains the row of the group;
	//        to get data from the index use begin(), next().
	// @param parentIndexType - type of the parent index, that can be used for operations
	//        in the group handle
	// @param gh - handle of the group where index belongs; the most important use is to get
	//        the group size as: parentIndexType->groupSize(gh); but also can be used
	//        to get access to other indexes in the same group, all of them will contain
	//        the same set of rows but possibly in different order
	// @param dest - the tray to collect the row for delayed sending (dest of sendDelayed())
	// @param aggop - the reason for this call
	// @param opcode - the Rowop opcode that would be normally used for the records
	//        produced in this operation (INSERT, DELETE, NOP), so that the simpler
	//        aggregators can ignore aggop and just go by opcode. When multiple records
	//        are changed in one table operation, the calls for all but the last records 
	//        will have the opcode NOP. The last one will normally have INSERT.
	//        The sending of old state (AO_BEFORE_MOD or AO_COLLAPSE) generally has
	//        the opcode DELETE.
	// @param rh - row that has been inderted or deleted, if deleted then it will be
	//        already not in table; may be NULL if aggop just requires the sending of
	//        the old state (such as AO_BEFORE_MOD or AO_COLLAPSE).
	virtual void handle(Table *table, AggregatorGadget *gadget, Index *index,
		const IndexType *parentIndexType, GroupHandle *gh, Tray *dest,
		AggOp aggop, Rowop::Opcode opcode, RowHandle *rh) = 0;
};

}; // TRICEPS_NS

#endif // __Triceps_Aggregator_h__
