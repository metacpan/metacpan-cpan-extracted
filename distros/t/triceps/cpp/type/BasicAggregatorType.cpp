//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Aggregator through a basic C-style callback function.

#include <typeinfo>
#include <type/BasicAggregatorType.h>
#include <table/BasicAggregator.h>
#include <sched/AggregatorGadget.h>

namespace TRICEPS_NS {

BasicAggregatorType::BasicAggregatorType(const string &name, const RowType *rt, Callback *cb) :
	AggregatorType(name, rt),
	cb_(cb)
{ }

BasicAggregatorType::BasicAggregatorType(const BasicAggregatorType &agg, HoldRowTypes *holder) :
	AggregatorType(agg, holder),
	cb_(agg.cb_)
{ }

AggregatorType *BasicAggregatorType::copy() const
{
	return new BasicAggregatorType(*this);
}

AggregatorType *BasicAggregatorType::deepCopy(HoldRowTypes *holder) const
{
	return new BasicAggregatorType(*this, holder);
}

bool BasicAggregatorType::equals(const Type *t) const
{
	if (this == t)
		return true; // self-comparison, shortcut

	if (!AggregatorType::equals(t))
		return false;
	
	const BasicAggregatorType *bat = static_cast<const BasicAggregatorType *>(t);

	if (cb_ != bat->cb_)
		return false;

	return true;
}

bool BasicAggregatorType::match(const Type *t) const
{
	if (this == t)
		return true; // self-comparison, shortcut

	if (!AggregatorType::match(t))
		return false;
	
	const BasicAggregatorType *bat = static_cast<const BasicAggregatorType *>(t);

	if (cb_ != bat->cb_)
		return false;

	return true;
}

AggregatorGadget *BasicAggregatorType::makeGadget(Table *table, IndexType *intype) const
{
	return new AggregatorGadget(this, table, intype);
}

Aggregator *BasicAggregatorType::makeAggregator(Table *table, AggregatorGadget *gadget) const
{
	return new BasicAggregator;
}

}; // TRICEPS_NS
