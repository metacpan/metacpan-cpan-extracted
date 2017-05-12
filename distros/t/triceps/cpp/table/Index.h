//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// The common interface for indexes.

#ifndef __Triceps_Index_h__
#define __Triceps_Index_h__

#include <mem/Mtarget.h>
#include <common/Common.h>
#include <type/IndexType.h>
#include <table/Aggregator.h>
#include <set>
#include <map>

namespace TRICEPS_NS {

class TableType;
class IndexType;
class Table;
class Index;
class Tray;

// Indexes should be accessed only in one thread, so Straget is good enough.
class Index : public Starget
{
	friend class IndexType;
	friend class IndexVec;
	friend class Table;
public:
	virtual ~Index();

	// Get the type of this index: let the subclass sort it out
	virtual const IndexType *getType() const = 0;

	// Get the handle of the first record in this index.
	// @return - the handle, or NULL if the index is empty
	virtual RowHandle *begin() const = 0;

	// Return the next row in this index.
	// The repeated calls would go through all the records in the table.
	// So for the nested indexes this means that it should iterate
	// through any (usually, first) of the sub-indexes as well.
	// @param cur - the current handle
	// @return - the next row's handle, or NULL if the current one was the last one,
	//       or not in the table or NULL
	virtual RowHandle *next(const RowHandle *cur) const = 0;

	// Get the handle of the last record in this index.
	// This is convenient for aggregators. Yes, the last record could be remembered
	// during iteration but this is so much more convenient. Note that there is no
	// prev(), at least yet.
	// @return - the handle, or NULL if the index is empty
	virtual RowHandle *last() const = 0;

	// For the nested indexes, find the next group in them.
	// @param cur - the current group in this index
	// @return - the next group, or NULL if the current group was the last one or was NULL
	virtual const GroupHandle *nextGroup(const GroupHandle *cur) const = 0;

	// For the nested indexes, find the first group in them.
	// @return - the first group, or NULL if the index is empty.
	virtual const GroupHandle *beginGroup() const = 0;

	// For the nested indexes, find the group where the row belongs.
	// The row must be not NULL, known to be in the table, and known 
	// (from parent indexes) to located in this index.
	// @param cur - the current handle
	// @return - group where the row belongs (usually obtained from the iterator in
	//           row handle)
	virtual const GroupHandle *toGroup(const RowHandle *cur) const = 0;

	// Find the matching element.
	// Note that for a RowHandle that has been returned from the table
	// there is no sense in calling find() because it already represents
	// an iterator in the table. This finds a row in the table with the
	// key matching one in a freshly made RowHandle (with Table::makeRowHandle()).
	// @param what - the pattern row
	// @return - the matching (accoriding to this index) row in the table,
	//     or NULL if not found; an index that has multiple matching rows,
	//     may return any of them but preferrably the first one.
	virtual RowHandle *find(const RowHandle *what) const = 0;

	// XXX add lower_bound, upper_bound ?

	// Get the type id of this index
	IndexType::IndexId getIndexId() const
	{
		return getType()->getIndexId();
	}

protected:
	typedef set<RowHandle *> RhSet;

	// always created through subclasses
	Index(const TableType *tabtype, Table *table);
	
	// Clear the data rows of the index. For non-leaf indexes this
	// means the recursive propagation down to the leaves.
	// The contents of the non-leaf indexes does not get deleted,
	// and the groups are not collapsed.
	// The actual RowHandles are guaranteed
	// to be still held by the table, so the cleaning can be fast.
	virtual void clearData() = 0;

	// Prepare for insertion of the new row handle.
	// Recursively check if it can legally inserted and calculate any records that
	// would be deleted by the replacement policy.
	// XXX should it also have an indication of update vs insert?
	//
	// The non-leaf indexes absolutely MUST create their groups if they
	// weren't previously existing. The reason is that without groups created
	// this call can not be propagated to their sub-indexes. In turn, the major reason
	// for that is to let the non-leat indexes in the middle of the tree populate
	// the iterator values in their sections of the row handle.
	// So even if a non-leaf is going to return false, it still must create
	// the group and do the nested call.
	// Because of all this, this method is NOT const.
	//
	// @param rh - new row about to be inserted. If this index is non-leaf,
	//     on return rh will have the group iterator populated in it.
	// @param replaced - set to add the handles of replaced rows
	// @return - true if insertion is allowed, false if not
	virtual bool replacementPolicy(RowHandle *rh, RhSet &replaced) = 0;

	// Insert the row into the index.
	// This is called after the replacement policy has been executed.
	// @param rh - handle to insert
	virtual void insert(RowHandle *rh) = 0;

	// Remove the row from the index.
	// @param rh - handle to remove
	virtual void remove(RowHandle *rh) = 0;

	// Call aggregator AO_BEFORE_MOD before the rows get deleted or inserted.
	// The call is done one for each group, if it was not already done (as indicated
	// by the "already" argument).
	//
	// @param dest - destination to send the delayed aggregation changes
	// @param rows - set of rows that will be modified
	// @param future - set of rows for which aggregateBefore has already been called.
	virtual void aggregateBefore(Tray *dest, const RhSet &rows, const RhSet &already) = 0;

	// Call aggregator AO_AFTER_DELETE or AO_AFTER_INSERT (as indicated by aggop) 
	// after the rows have been removed or inserted.
	// The call is done for each row. The Rowop::opcode varies: all the calls for
	// a particular group are NOP and only the last one is INSERT. If the
	// future set for the group is not empty, then all opcodes are NOP (because then 
	// the future set will be processed later and have the last call as INSERT).
	//
	// Why INSERT after removal: because the groups haven't been
	// deleted, they've been modified. So remove() called AO_BEFORE_MOD with OP_DELETE
	// to delete the old state, and now the new state gets sent with 
	// AO_AFTER_DELETE and INSERT.
	//
	// Why all but the last are NOPs: because all the modifications get combined
	// into one update, and only one INSERT needs to be sent per group. The
	// intermediate calls with NOPs are needed to give the additive aggregations
	// a chance to update their state.
	//
	// @param dest - destination to send the delayed aggregation changes
	// @param aggop - operation argument to pass through, AO_AFTER_DELETE or AO_AFTER_INSERT
	// @param rows - set of rows that have been removed or inserted
	// @param future - set of rows for which the aggregation notifications will
	//        be called separtely in the future (usually the sets are separated into
	//        "remove" and "insert", and the notifications for inserts are done after remove)
	virtual void aggregateAfter(Tray *dest, Aggregator::AggOp aggop, const RhSet &rows, const RhSet &future) = 0;

	// Collapse the groups identified by this RowHandle set recursively
	// if they are found to be empty. "Collapsing" of a group means that the group
	// that became empty gets removed from its parent index and deleted.
	//
	// The handle would normally be removed from the table just a momemnt ago, so
	// its leaf iterators will be invalid, and the leaf indexes must
	// do nothing othen than return the result. However the non-leaf iterators 
	// would still point to the valid groups.
	// 
	// A tricky part is that multiple handles in the set may point to the
	// same group. Collapsing the group on the first matching row found will make
	// the iterators in the following rows belonging to the same group invalid.
	// So the index must first split the set into subsets by iterators
	// and then collapse only once.
	//
	// A group may be collapsed only if all its sub-indexes agree so. The reason
	// for non-collapsing may be the desire to avoid re-creating the group if
	// it gets inserted in the future. For example, the RootIndex never collapses
	// its only group. But this should not be a concern for the row replacement:
	// before the collapse is called, the new record would be already inserted,
	// making the group non-empty, and consequently non-collapsible.
	// 
	// @param dest - destination to send the delayed aggregation changes
	// @param replaced - set of rows that have been replaced, identifying the
	//     groups that may need collapsing.
	// @return - true if the index doesn't mind its parent group being collapsed
	//     (and did its part by collapsing all the sub-groups owned by it),
	//     false otherwise. For the leaf indexes it's safe to always return
	//     true, their parents will never collapse the non-empty groups.
	virtual bool collapse(Tray *dest, const RhSet &replaced) = 0;

	// If this is a non-leaf index, find the nested index
	// in the group where this row belongs.
	// @param what - row used to find the group (or NULL, requesting to return
	//     the index form the first group, used in Table::beginIdx())
	// @param nestPos - position of wanted index type in its parent
	// @return - the index, or NULL if it can not be found
	//        (if this is a leaf index, it always returns NULL)
	virtual Index *findNested(const RowHandle *what, int nestPos) const = 0;

protected:
	// Interface for subtypes
	
	// Find the index instance of a given type for the given handle.
	// The index instances can use it to check whether some row belongs
	// to themselves or not.
	Index *getIndexOf(IndexType *type, const RowHandle *rh) const;

protected:
	// Common type used to split the row sets by groups
	typedef map<GroupHandle *, RhSet> SplitMap;

	// no reference to the type because they're better in subclasses
	Autoref<const TableType> tabType_; // type of the table where it belongs
	Table *table_; // not Autoref, to avoid circular references

private:
	Index();
	Index(const Index &);
	void operator=(const Index &);
};

}; // TRICEPS_NS

#endif // __Triceps_Index_h__
