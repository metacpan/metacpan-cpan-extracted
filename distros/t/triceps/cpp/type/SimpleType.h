//
// (C) Copyright 2011-2014 Sergey A. Babkin.
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
		Type(true, id),
		size_(size)
	{ }

	// get the size of a basic element
	int getSize() const
	{
		return size_;
	}

	// from Type
	virtual Erref getErrors() const;

protected:
	int size_; // size of the basic element of this type

private:
	SimpleType();
};

}; // TRICEPS_NS

#endif // __Triceps_SimpleType_h__

