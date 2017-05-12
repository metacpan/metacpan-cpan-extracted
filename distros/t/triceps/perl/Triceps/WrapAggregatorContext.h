//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
// The "wrapper" that stores the AggregatorContext data.

#ifndef __TricepsPerl_WrapAggregatorContext_h__
#define __TricepsPerl_WrapAggregatorContext_h__

#include <common/Conf.h>
#include <type/AggregatorType.h>
#include <sched/AggregatorGadget.h>
#include <table/Aggregator.h>

using namespace TRICEPS_NS;

namespace TRICEPS_NS
{
namespace TricepsPerl 
{

// This is not really a wrapper, it's really the aggregator context that points to
// a bunch of objects. But since it  follows the convention of Wrap* classes,
// it's named consistently to them.
//
// Currently it refers to the components in the same way as the aggregator handler
// call, by pointers, instead of counted references. This makes it faster but
// potentially unsafe if the context object is abused and preserved outside of the 
// aggregator handler call. So to prevent the abuse the wrapper object is invalidated
// after the handler returns. Then the XS code can check whether the wrapper is
// valid, and fail if not (see O_WRAP_INVALIDABLE_OBJECT in typemap).
// Through the handler call and  until invalidation, the C++ code must keep
// a reference on the SV pointing here!

extern WrapMagic magicWrapAggregatorContext; // defined in AggregatorContext.xs
class WrapAggregatorContext
{
public:
	WrapAggregatorContext(Table *table, AggregatorGadget *gadget, Index *index,
			const IndexType *parentIndexType, GroupHandle *gh, Tray *dest) :
		magic_(magicWrapAggregatorContext),
		table_(table),
		gadget_(gadget),
		index_(index),
		parentIndexType_(parentIndexType),
		gh_(gh),
		dest_(dest),
		valid_(true)
	{ }

	bool badMagic() const
	{
		return magic_ != magicWrapAggregatorContext;
	}

	bool isValid() const
	{
		return valid_;
	}

	// Called after the handler returns, so that any saved references will be invalid
	void invalidate()
	{
		valid_ = false;
	}

	Table *getTable() const
	{
		return table_;
	}

	AggregatorGadget *getGadget() const
	{
		return gadget_;
	}

	Index *getIndex() const
	{
		return index_;
	}

	const IndexType *getParentIdxType() const
	{
		return parentIndexType_;
	}

	GroupHandle *getGroupHandle() const
	{
		return gh_;
	}

	Tray *getDest() const
	{
		return dest_;
	}

protected:
	WrapMagic magic_;
	Table *table_;
	AggregatorGadget *gadget_;
	Index *index_;
	const IndexType *parentIndexType_;
	GroupHandle *gh_;
	Tray *dest_;
	bool valid_;
private:
	WrapAggregatorContext();
};

}; // Triceps::TricepsPerl
}; // Triceps

using namespace TRICEPS_NS::TricepsPerl;

#endif // __TricepsPerl_WrapAggregatorContext_h__
