//
// (C) Copyright 2011-2018 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Intermediate hold for cloning a set of row types.

#include <type/HoldRowTypes.h>

namespace TRICEPS_NS {

RowType *HoldRowTypes::copy(const RowType *orig)
{
	if (orig == NULL)
		return NULL;

	if (this == NO_HOLD_ROW_TYPES)
		return orig->copy();

	Map::iterator it = map_.find(orig);
	if (it != map_.end()) {
		return it->second;
	} else {
		RowType *rt = orig->copy();
		map_[orig] = rt;
		return rt;
	}
}

NoHoldRowTypes::NoHoldRowTypes()
{ 
	// Makes sure that this object gets never destroyed by Autoref.
	incref();
}

NoHoldRowTypes NO_HOLD_ROW_TYPES_OBJECT;
HoldRowTypes * const NO_HOLD_ROW_TYPES = &NO_HOLD_ROW_TYPES_OBJECT;

}; // TRICEPS_NS
