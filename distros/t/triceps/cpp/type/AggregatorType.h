//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// The base class of user-defined factory of user-defined aggregators.

#ifndef __Triceps_AggregatorType_h__
#define __Triceps_AggregatorType_h__

#include <type/Type.h>
#include <sched/Gadget.h>

namespace TRICEPS_NS {

class TableType;
class IndexType;
class Table;
class AggregatorGadget;
class Aggregator;
class HoldRowTypes;

// The AggregatorType subclasses serve as a factory for both the AggregatorGadget
// (one per table) and Aggregator (one per index/group) subclasses.
class AggregatorType : public Type
{
public:
	// @param name - name for aggregators' gadget in the table, will be tablename.name
	// @param rt - type of rows produced by this aggregator, will be referenced;
	//        may be NULL if the subclass will set it later during initialization
	AggregatorType(const string &name, const RowType *rt);
	// for copying
	AggregatorType(const AggregatorType &agg);
	// for deep copying
	AggregatorType(const AggregatorType &agg, HoldRowTypes *holder);
	~AggregatorType();

	// Get back the name
	const string &getName() const
	{
		return name_;
	}

	// Get back the row type
	const RowType *getRowType() const
	{
		return rowType_;
	}

	// Initialize and validate.
	// If already initialized, must return right away.
	// does not include initialization of pos_ and must not make assumptions
	// whether pos_ has been initialized.
	// Called after the index has been initialized.
	//
	// The errors are returned through getErrors().
	//
	// By default just sets the initialization flag.
	//
	// @param tabtype - type of the table where this aggregator belongs
	// @param intype - type of the index on which this aggregation happens
	//        (the set of rows in an index instance are the rows for aggregation)
	virtual void initialize(TableType *tabtype, IndexType *intype);

	bool isInitialized() const
	{
		return initialized_;
	}
	
	// Make a copy of this type. The copy is always uninitialized, no
	// matter whether it was made from an initialized one or not.
	// The subclasses must define the actual copying.
	//
	// The typical subclass copy function looks like this:
	// AgregatorType *MyAggregatorType::copy() const
	// {
	//     return new MyAggregatorType(*this);
	// }
	virtual AggregatorType *copy() const = 0;
	// Make a deep copy of this type. The copy is always uninitialized, no
	// matter whether it was made from an initialized one or not.
	// The subclasses must define the actual copying.
	//
	// The typical subclass copy function looks like this:
	// AgregatorType *MyAggregatorType::deepCopy(HoldRowTypes *holder) const
	// {
	//     return new MyAggregatorType(*this, holder);
	// }
	//
	// Note that using this method holder==NULL has a different meaning 
	// than copy(): copy() will keep the references to the original
	// RowType while deepCopy(NULL) will make an independent copy
	// of for each use of RowType.
	//
	// @param holder - helper object that makes sure that multiple
	//        references to the same row type stay multiple references
	//        to the same copied row type, not multiple row types
	//        (unless it's NULL, which reverts to plain copying).
	//        The caller has to keep a reference to the holder for
	//        the duration.
	virtual AggregatorType *deepCopy(HoldRowTypes *holder) const = 0;

	// Create an AggregatorGadget subclass, one per table.
	//
	// The typical subclass function looks like this:
	// AgregatorGadget *MyAggregatorType::makeGadget(Table *table, IndexType *intype) const
	// {
	//     return new MyAggregatorGadget(table, intype);
	// }
	//
	// @param table - table where the gadget is created (get the unit, front half
	//        of the name, row type and enqueueing mode from there)
	// @param intype - type of the index on which this aggregation happens
	//        (the set of rows in an index instance are the rows for aggregation)
	// @return - a newly created gadget of the proper subclass
	virtual AggregatorGadget *makeGadget(Table *table, IndexType *intype) const = 0;

	// Create an Aggregator subclass, one per index/group.
	//
	// The typical subclass function looks like this:
	// Agregator *MyAggregatorType::makeAggregator(Table *table, AggregatorGadget *gadget) const
	// {
	//     return new MyAggregator(table, gadget);
	// }
	//
	// @param - table where the aggregator is created (will also be passed to all ops)
	// @param - this type's gadget in the table (will also be passed to all ops)
	// @return - a newly created instance of aggregator
	virtual Aggregator *makeAggregator(Table *table, AggregatorGadget *gadget) const = 0;

	// from Type
	virtual Erref getErrors() const;
	// subclasses would probably want to override this
	virtual bool equals(const Type *t) const;
	virtual bool match(const Type *t) const;
	// subclasses also may want to override printTo() if the default is not good enough
	virtual void printTo(string &res, const string &indent = "", const string &subindent = "  ") const;

protected:
	friend class Table;
	friend class TableType;
	friend class IndexType;

	// set the position of this aggregator in table's flat vector
	void setPos(int pos)
	{
		pos_ = pos;
	}
	// get back the position
	int getPos() const
	{
		return pos_;
	}

	// Set the row type, can be called by the subclass initialize().
	// @param rt - the result row type computed by the initialization.
	void setRowType(const RowType *rt)
	{
		rowType_ = rt;
	}

protected:
	const_Autoref<RowType> rowType_; // row type of result
	Erref errors_; // errors from initialization
	string name_; // name inside the table's dotted namespace
	int pos_; // a table has a flat vector of AggregatorGadgets in it, this is the index for this one (-1 if not set)
	bool initialized_; // flag: already initialized, no future changes

private:
	void operator=(const AggregatorType &);
};

}; // TRICEPS_NS

#endif // __Triceps_AggregatorType_h__
