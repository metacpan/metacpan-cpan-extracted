//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
// The Triceps aggregator for Perl calls and the wrapper for it.

// Include TricepsPerl.h and PerlCallback.h before this one.

#include <common/Conf.h>
#include <type/AggregatorType.h>
#include <type/HoldRowTypes.h>
#include <sched/AggregatorGadget.h>
#include <table/Aggregator.h>

// ###################################################################################

#ifndef __TricepsPerl_PerlAggregator_h__
#define __TricepsPerl_PerlAggregator_h__

using namespace TRICEPS_NS;

namespace TRICEPS_NS
{
namespace TricepsPerl 
{

class PerlAggregatorType : public AggregatorType
{
public:
	
	// @param name - name for aggregators' gadget in the table, will be tablename.name
	// @param rt - type of rows produced by this aggregator, will be referenced, may be
	//        NULL until after the initialization runs
	// @param cbInit - callback that runs at the type initialization time, may be NULL, will be
	//        referenced, may be used to check that the args make sense and
	//        generate the constructor and handler callbacks on the fly.
	//        Args: AggregatorType aggtm TableType tabt, IndexType idxt, RowType tabrowt, RowType resrowt
	//          aggt - link back to this object (used to set the constructor and handler
	//                 callbacks, result row type and such), DO NOT SAVE IT INSIDE THE
	//                 AGGREGATOR'S DATA OR IT WILL BE A CIRCULAR REFERENCE.
	//          tabt - table type that performs the initialization
	//          idxt - link back to the index type that contains the aggregator (can be used
	//                 to find the grouping, if possible with this index type)
	//          tabrowt - row type of the table, passed directly as a convenience
	//          resrowt - row type of the result as ik't known so far (may be undef if not set yet)
	//        Returns undef on success or an error message (may freely contain \n) on error.
	// @param cbConstructor - callback for construction of sv_ in aggregator, may be NULL, 
	//        will be referenced
	// @param cbHandler - callback for execution of aggregator, may be NULL untill after the
	//        initialization runs, will be referenced
	PerlAggregatorType(const string &name, const RowType *rt, Onceref<PerlCallback> cbInit,
		Onceref<PerlCallback> cbConstructor, Onceref<PerlCallback> cbHandler);

	// for deep copy
	PerlAggregatorType(const PerlAggregatorType &agg, HoldRowTypes *holder);

	// from AggregatorType
	virtual AggregatorType *copy() const;
	// The holder will be kept until the initialization time.
	// This is needed because the RowType objects in PerlCallback are not constructed
	// until the initialization time, because it can not be extracted
	// separately from the Perl objects, and extracting those would
	// mess up the memory management, because the Nexuses are kept
	// separate from any Perl threads.
	virtual AggregatorType *deepCopy(HoldRowTypes *holder) const;
	virtual void initialize(TableType *tabtype, IndexType *intype);
	// creates just the generic AggregatorGadget, nothing special
	virtual AggregatorGadget *makeGadget(Table *table, IndexType *intype) const;
	virtual Aggregator *makeAggregator(Table *table, AggregatorGadget *gadget) const;

	// from Type
	virtual bool equals(const Type *t) const;
	virtual bool match(const Type *t) const;

	// Set the result row type, could be called from the initializer.
	// Similar to the one in the base class, only publicly exported, 
	// to make it available in XS, and will fail if attempted after
	// initialization.
	// @return - true on success, false if the object is already initialized
	bool setRowType(const RowType *rt);
	// Set the constructor, could be called from the initializer.
	// @return - true on success, false if the object is already initialized
	bool setConstructor(Onceref<PerlCallback> cbConstructor);
	// Set the handler, could be called from the initializer.
	// @return - true on success, false if the object is already initialized
	bool setHandler(Onceref<PerlCallback> cbHandler);

protected:
	friend class PerlAggregator;

	Autoref<PerlCallback> cbInit_; // initializes the aggregator type instance
	Autoref<PerlCallback> cbConstructor_; // constructs sv_ for makeAggregator
	Autoref<PerlCallback> cbHandler_; // handler called from PerlAggregator
	Autoref<HoldRowTypes> hrt_; // held temporarily, between deep copy and initialization
};

class PerlAggregator : public Aggregator
{
public:
	// @param table - passed to Aggregator
	// @param gadget - passed to Aggregator
	// @param sv - state SV or NULL, increases its refcount if not NULL
	PerlAggregator(Table *table, AggregatorGadget *gadget, SV *sv);
	virtual ~PerlAggregator();

	// from Aggregator
    virtual void handle(Table *table, AggregatorGadget *gadget, Index *index,
		const IndexType *parentIndexType, GroupHandle *gh, Tray *dest,
		AggOp aggop, Rowop::Opcode opcode, RowHandle *rh);

	// Set a new value in sv_, increases the refcount if not NULL.
	void setsv(SV *sv);
protected:
	SV *sv_; // may be used to keep the arbitrary Perl values
};

extern WrapMagic magicWrapAggregatorType;
typedef Wrap<magicWrapAggregatorType, PerlAggregatorType> WrapAggregatorType;

}; // Triceps::TricepsPerl
}; // Triceps

using namespace TRICEPS_NS::TricepsPerl;

#endif // __TricepsPerl_PerlAggregator_h__
