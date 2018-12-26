//
// (C) Copyright 2011-2018 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Common subclass for the simple types

#ifndef __Triceps_SimpleType_h__
#define __Triceps_SimpleType_h__

#include <type/Type.h>

namespace TRICEPS_NS {

// Later, when there will be own language, these definitions may become
// more complex and be split into their separate files.

class SimpleType : public Type
{
public:
	SimpleType(TypeId id, int size) :
		Type(true, id, size)
	{ }

	// from Type
	virtual Erref getErrors() const;

private:
	SimpleType();
};

}; // TRICEPS_NS

#endif // __Triceps_SimpleType_h__

