//
// (C) Copyright 2011-2014 Sergey A. Babkin.
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

	if (this == NULL)
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

}; // TRICEPS_NS
