//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Type for the tables.

#ifndef __Triceps_TableType_h__
#define __Triceps_TableType_h__

#include <type/IndexType.h>
#include <type/RowType.h>
#include <type/RowHandleType.h>
#include <sched/Gadget.h>

namespace TRICEPS_NS {

class Table;
class RootIndexType;
class AggregatorType;
class HoldRowTypes;

class TableType : public Type
{
	friend class Table;
public:
	// Constructors duplicated as make() for syntactically better usage.
	// @param rt - type of rows in this table
	TableType(Onceref<RowType> rt);
	static TableType *make(Onceref<RowType> rt)
	{
		return new TableType(rt);
	}
	~TableType();

	// Copy this type, copying the contents but sharing the row types.
	// The copy is also uninitialized. The errors will not be copied.
	TableType *copy() const;

	// Create a copy of the type, also copying all the contents including the row types.
	// The copy is also uninitialized. The errors will not be copied.
	//
	// Here there is no use in the holder having the default of NULL
	// because it would produce something seriously undesirable.
	// Just use copy() instead if you don't need the deepness.
	//
	// @param holder - helper object that makes sure that multiple
	//        references to the same row type stay multiple references
	//        to the same copied row type, not multiple row types
	//        (unless it's NULL, which reverts to plain copying).
	//        The caller has to keep a reference to the holder for
	//        the duration.
	TableType *deepCopy(HoldRowTypes *holder) const;

	// from Type
	virtual Erref getErrors() const; 
	virtual bool equals(const Type *t) const;
	virtual bool match(const Type *t) const;
	virtual void printTo(string &res, const string &indent = "", const string &subindent = "  ") const;

	// The idea of the configuration methods is that they return back "this",
	// making possible to chain them together with "->".

	// Add a top-level index.
	//
	// May be used only until initialized. Afterwards will throw an Exception.
	// If an Exception is thrown, tries to free the unreferenced (this).
	//
	// The index remembered is actually a copy of original, so all the settings
	// need to be done before calling here. This also means that to access indexes
	// in a table, their types need to be obtained from TableType after it is initialized,
	// using findSubIndex.
	//
	// @param name - name of the index
	// @param index - the index
	// @return - this
	TableType *addSubIndex(const string &name, IndexType *index);

	// Check the whole table definition and derive the internal
	// structures. The result gets returned by getErrors().
	void initialize();

	// Whether it was already initialized
	bool isInitialized() const
	{
		return initialized_;
	}

	// Get the row type
	const RowType *rowType() const
	{
		return rowType_;
	}

	// Get the row handle type (this one is not constant)
	RowHandleType *rhType() const
	{
		return rhType_;
	}

	// Create an instance table of this type.
	// @param unit - unit where the table belongs
	// @param name - name of the table,  the input label will be named name.in, the output label name.out,
	//               and the aggregation labels will also be prefixed with the table name and a dot
	// @return - new instance or NULL if not initialized or has an error
	Onceref<Table> makeTable(Unit *unit, const string &name) const;

	// Find an index type by name.
	// Works only after initialization.
	// @param name - name of the index
	// @return - index, or NULL if not found
	IndexType *findSubIndex(const string &name) const;

	// Find the first index type of given IndexId
	// Works only after initialization.
	// @param it - type enum of the nested index
	// @return - pointer to the nested index or NULL if none matches
	IndexType *findSubIndexById(IndexType::IndexId it) const;

	// Return the vector of nested indexes, for iteration
	const IndexTypeVec &getSubIndexes() const;

	// Return the first leaf index type.
	// If no indexes defined, returns NULL.
	IndexType *getFirstLeaf() const;

protected:
	Autoref<RootIndexType> root_; // the root of index tree
	Autoref<RowType> rowType_; // row for this table
	Erref errors_;
	Autoref<RowHandleType> rhType_; // for building the row handles
	IndexAggTypeVec aggs_; // all the aggregators, collected during initialization
	bool initialized_; // flag: has already been initialized, no more changes allowed

private:
	TableType();
	TableType(const TableType &); // this actually need to be defined later for cloning
	void operator=(const TableType &);
};

}; // TRICEPS_NS

#endif // __Triceps_TableType_h__

