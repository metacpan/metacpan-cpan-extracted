//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// The table implementation.

#ifndef __Triceps_Table_h__
#define __Triceps_Table_h__

#include <type/TableType.h>
#include <table/RootIndex.h>
#include <sched/AggregatorGadget.h>
#include <sched/FnReturn.h>

namespace TRICEPS_NS {

class RowType;
class RowHandleType;
class TableType;
class Row;

class Table : public Gadget
{
public:
	~Table();

	// Get the type of this table
	const TableType *getType() const
	{
		return type_;
	}
	// Get the row type of this table
	const RowType *getRowType() const
	{
		return rowType_;
	}
	// Get the row handle type of this table
	const RowHandleType *getRhType() const
	{
		return rhType_;
	}

	// Return the label for sending Rowops into the table
	// (as opposed to getLabel() which is inherited from gadget and
	// returns the output label, on which the rowops are sent from the table).
	Label *getInputLabel() const
	{
		return inputLabel_.get();
	}

	// Return the label that gets called (always called, no other modes)
	// if it has anything else chained on it before modifying each row.
	Label *getPreLabel() const
	{
		return preLabel_.get();
	}

	// Return the label that gets called by the dump methods.
	// This is a way to iterate with the streaming functions: connect your
	// binding to the dump label, and then call one of the dump methods
	// to send a set of rows to it.
	Label *getDumpLabel() const
	{
		return dumpLabel_.get();
	}

	// Return the label of a named aggregator
	// (a label seems more convenient than a gadget).
	// @param agname - aggregator name (names should be unique, if duplicated
	//        then will return whichever random one)
	// @return - label of the aggregator, or NULL if not found
	Label *getAggregatorLabel(const string &agname) const;

	// Get back the table name (overrides the gadget method, because that
	// name has ".out" added to it).
	const string &getName() const
	{
		return name_;
	}

	// Get the size of the table, in rows.
	size_t size() const
	{
		return root_->size();
	}

	// Get the FnReturn for this table. It will get created on the first
	// call, so if not used, it will not add overhead.
	// Its name is "<table_name>.fret".
	// It contains some fixed labels: "out", "pre" and "dump", and a label for every
	// aggregator.
	// The table keeps a reference to the FnReturn, so returning a pointer
	// is always safe.
	// If something goes very wrong (pretty much the only reason for it is if
	// you name an aggregator "pre" or "out" or such), it may throw an Exception.
	FnReturn *fnReturn() const;
	
	/////// operations on rows

	// Create a new row handle for a row.
	// The result should be immediately placed into Rhref.
	// XXX change the interface to make this protected and return Rhrefs to everyone else
	RowHandle *makeRowHandle(const Row *row) const;

	// Insert a row.
	// May throw an Exception.
	// @param row - the row to insert
	// @return - true on success, false on failure (if the index policies don't allow it)
	bool insertRow(const Row *row);
	// Insert a pre-initialized row handle.
	// May throw an Exception.
	// If the handle is already in table, does nothing and returns false.
	// @param rh - the row handle to insert (must be held in a Rowref or such at the moment)
	// @return - true on success, false on failure (if the index policies don't allow it)
	bool insert(RowHandle *rh);

	// XXX also add a version working on RhSet, for better efficiency?
	// Remove a row handle from the table. If the row is already not in table, do nothing.
	// May throw an Exception.
	// @param rh - row handle to remove
	void remove(RowHandle *rh);

	// Find the matching row in the table (by the default index),
	// and if found, remove it.
	// May throw an Exception.
	// @param row - the row to find matching and remove
	// @return - true if found and removed, false if not found
	bool deleteRow(const Row *row);

	// Get the handle of the first record in this table.
	// A random index will be used for iteration. Usually this will be
	// the first index, but the table may decide to pick a more efficient one
	// if it can.
	// May throw an Exception if the table has a sticky error.
	// @return - the handle, or NULL if the table is empty
	RowHandle *begin() const;

	// Get the handle of the first record in this table, according to a specific index.
	// May throw an Exception if the table has a sticky error.
	// @param ixt - index type from this table's type (if not leaf then will mean
	//        the same as it's first nested leaf)
	// @return - the handle, or NULL if the table is empty
	RowHandle *beginIdx(IndexType *ixt) const;

	// Return the next row in this table.
	// May throw an Exception if the table has a sticky error.
	// @param cur - the current handle
	// @return - the next row's handle, or NULL if the current one was the last one,
	//       or not in the table or NULL
	RowHandle *next(const RowHandle *cur) const;

	// Return the next row in this table, according to a specific index.
	// May throw an Exception if the table has a sticky error.
	// @param ixt - index type from this table's type (if not leaf then will mean
	//        the same as it's first nested leaf)
	// @param cur - the current handle
	// @return - the next row's handle, or NULL if the current one was the last one,
	//       or not in the table or NULL
	RowHandle *nextIdx(IndexType *ixt, const RowHandle *cur) const;

	// Return the first row in the same group (according to this index)
	// as the current row.
	// May throw an Exception if the table has a sticky error.
	// @param ixt - index type from this table's type (may be not leaf)
	// @param cur - the current handle
	// @return - handle of the first row in the same group (if the current group
	//        is not in table or NULL, returns NULL)
	RowHandle *firstOfGroupIdx(IndexType *ixt, const RowHandle *cur) const;

	// Return the last row in the same group (according to this index)
	// as the current row.
	// May throw an Exception if the table has a sticky error.
	// @param ixt - index type from this table's type (may be not leaf)
	// @param cur - the current handle
	// @return - handle of the last row in the same group (if the current group
	//        is not in table or NULL, returns NULL)
	RowHandle *lastOfGroupIdx(IndexType *ixt, const RowHandle *cur) const;

	// Return the first row of the next group (according to this index).
	// For the nested indexes, a way to skip over all the
	// remaining records in the current group.
	// May throw an Exception if the table has a sticky error.
	// @param ixt - index type from this table's type (may be not leaf)
	// @param cur - the current handle
	// @return - handle of the first row in the next group, or NULL if the 
	//       current group was the last one, or row not in the table or NULL
	RowHandle *nextGroupIdx(IndexType *ixt, const RowHandle *cur) const;

	// Find the matching element.
	// Note that for a RowHandle that has been returned from the table
	// there is no sense in calling find() because it already represents
	// an iterator in the table. This finds a row in the table with the
	// key matching one in a freshly made RowHandle (with Table::makeRowHandle()).
	//
	// May throw an Exception.
	//
	// If the index is leaf, finds the matching row. If the index is non-leaf,
	// finds the first row in the matching group (first according to the first
	// leaf sub-index of that group). 
	//
	// @param ixt - index type from this table's type
	// @param what - the pattern row
	// @return - the matching (according to this index) row in the table,
	//     or NULL if not found; a leaf index that has multiple matching rows, 
	//     may return any of them but preferrably the first one; a non-leaf 
	//     index returns the first row of the matching group.
	RowHandle *findIdx(IndexType *ixt, const RowHandle *what) const;

	// Find the matching element using the default (first leaf) index.
	// May throw an Exception.
	RowHandle *find(const RowHandle *what) const
	{
		return findIdx(firstLeaf_, what);
	}

	// The same but creates RowHandle from a Row internally.
	// May throw an Exception.
	RowHandle *findRowIdx(IndexType *ixt, const Row *what) const;
	RowHandle *findRow(const Row *what) const
	{
		return findRowIdx(firstLeaf_, what);
	}

	// Get the size of the group where the row belongs
	// (similarly to what can be done in an aggregator).
	// The group measured is a group under the specified index type
	// (the same approach as in findIdx()).
	//
	// This means that the index type must be non-leaf for a meaningful result.
	// For a leaf index, always returns 0.
	//
	// The row may be or not be in the table. If it's not in the table, a
	// findIdx() would first be performed internally to find the group.
	// If it's in the table, the group will be found directly from it.
	// If the group is not found, returns 0.
	//
	// May throw an Exception if the table has a sticky error.
	//
	// @param ixt - index type from this table's type
	// @param what - the pattern row handle
	// @return - the size of the group; would be 0 if ixt is a leaf
	//     index type, or if the group was not found
	size_t groupSizeIdx(IndexType *ixt, const RowHandle *what) const;

	// The same but creates RowHandle from a Row internally before
	// finding the group.
	size_t groupSizeRowIdx(IndexType *ixt, const Row *what) const;

	// Clear the table. The deleted rowops will be send out of the "pre" and
	// "out" labels as usual. The rows are sent in the order of the
	// first leaf index.
	// In the future it might be optimized, the initial implementation
	// works in a simple way.
	// May throw an Exception.
	// @param limit - maximal number of the rows to delete. 0 means
	//        "delete all".
	void clear(size_t limit = 0);

	// { The dump interface.
	
	// Send the whole contents of the table to the dump label.
	// The first leaf index is used to determine the order of the rows sent.
	// May throw an Exception.
	// @param op - Opcode to use for sending (INSERT by default).
	void dumpAll(Rowop::Opcode op = Rowop::OP_INSERT) const;

	// Send the whole contents of the table to the dump label, in a specific order.
	// May throw an Exception.
	// @param ixt - Index type that determines the ordering of the rows.
	//        If NULL then the default first leaf index is used.
	//        The index type must belong to this table's type.
	// @param op - Opcode to use for sending (INSERT by default).
	void dumpAllIdx(IndexType *ixt, Rowop::Opcode op = Rowop::OP_INSERT) const;

	// } The dump interface.

	// { The index interface.

	// Set the sticky error from a location where an exception can not
	// be thrown, such as from the comparators in the indexes.
	// Only the first error sticks, all the others are ignored since
	// (a) the table will be dead and throwing this error in exceptions
	// from this poin on anyway and (b) the comparator is likely to
	// report the same erro repeatedly and there is no point in seeing
	// multiple copies.
	//
	// @param err - error to stick
	void setStickyError(Erref err);
	// }

	// Normally there is no point in calling this, since the table
	// will throw an Exception on any operations anyway, but just
	// in case.
	Errors *getStickyError() const
	{
		return stickyErr_.get();
	}

	// Throw an Exception if a sticky error has been set.
	void checkStickyError() const;
	
protected:
	// A check at the end of Table operations: if a sticky
	// error has been set, throw it as an Exception without
	// the wrapper message.
	void checkStickyErrorAfter() const;
	
	friend class TableType;
	// A Table is normally created by a TableType as a factory.
	//
	// @param unit - unit where the table belongs
	// @param name - name of the table (name and a dot will prefix all the labels, the
	//        input label will be name.in, output label name.out)
	// @param tt - table type
	// @param rowt - type of rows in the table
	// @param handt - type of row handles, created inside the table type
	Table(Unit *unit, const string &name, 
		const TableType *tt, const RowType *rowt, const RowHandleType *handt);

protected:
	friend class Rhref;

	// called by Rhref when the last reference to a row handle is removed
	void destroyRowHandle(RowHandle *rh) const;

protected:
	friend class IndexType;

	RootIndex *getRoot() const
	{
		return root_;
	}

	// For creation of Aggregators, gives them a gadget instance
	AggregatorGadget *getAggregatorGadget(int i)
	{
		return aggs_[i];
	}

protected:
	class InputLabel: public Label
	{
		friend class Table;
	public:
		InputLabel(Unit *unit, const_Onceref<RowType> rtype, const string &name, Table *table);

	protected:
		// from Label
		// Throws an Exception of the table is already destroyed.
		virtual void execute(Rowop *arg) const;

		// when the table gets destroyed, it resets this back-link
		void resetTable()
		{
			table_ = NULL;
		}

		Table *table_;
	};

protected:
	typedef vector< Autoref<AggregatorGadget> > AggGadgetVec;

	Autoref<const TableType> type_; // type where this table belongs
	Autoref<const RowType> rowType_; // type of rows stored here
	Autoref<const RowHandleType> rhType_;
	Autoref<RootIndex> root_; // root of the index tree
	Autoref<InputLabel> inputLabel_;
	Autoref<IndexType> firstLeaf_; // the first leaf index type, used for default find
	Autoref<DummyLabel> preLabel_; // called before modifying a row, if has anything chained
	Autoref<DummyLabel> dumpLabel_; // the iteration data
	mutable Autoref<FnReturn> fnReturn_; // the FnReturn object for table results
	AggGadgetVec aggs_; // gadgets for all aggregators, matching the order in TableType
	string name_; // base name of the table
	Erref stickyErr_; // errors from the indexes, that make the table dead
	bool busy_; // flag: an operation is in progress on the table

private:
	Table(const Table &t);
	void operator=(const Table &t);
};

}; // TRICEPS_NS

#endif // __Triceps_Table_h__
