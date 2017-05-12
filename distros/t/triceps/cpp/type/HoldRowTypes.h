//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Intermediate hold for cloning a set of row types.

#ifndef __Triceps_HoldRowTypes_h__
#define __Triceps_HoldRowTypes_h__

#include <map>
#include <type/RowType.h>

namespace TRICEPS_NS {

// When deep-copying a RowSetType, TableType and a set of RowTypes
// for a Nexus or such, there is a problem that the originals may be
// referring in multiple places to the same RowType while a straightforward
// copy would split it into multiple copies. It's not a big deal
// memory-wise but if the rows get passed between these types at
// Perl level, would add the overhead of the comparison of row types
// on each row.
//
// So this structure keeps the row types through the copy sequence
// and does the mapping from the original references to the
// copying ones.
class HoldRowTypes: public Starget
{
public:
	// the default constructor and destructor are good enough
	// (and the copy constructor/assignment would work too)
	
	// Perofrm the mapping from the original to copied row type.
	// If that row type has not been seen yet, it will be copied
	// and remembered. If it was seen, the previous mapping will be
	// returned.
	//
	// The special feature is that this object may be NULL. This
	// allows to do a simple-minded copy without having a HoldRowTypes
	// object, just passing a NULL for it.
	//
	// @param orig - the original row type to copy, if it's NULL then a NULL
	//        will be returned
	// @return - the copied row type
	RowType *copy(const RowType *orig);

protected:
	// Mapping from the original to the copied types.
	typedef map<const RowType *, Autoref<RowType> > Map;

	Map map_;
};

}; // TRICEPS_NS

#endif // __Triceps_HoldRowTypes_h__
