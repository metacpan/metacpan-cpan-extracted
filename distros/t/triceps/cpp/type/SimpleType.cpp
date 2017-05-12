//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Common subclass for the simple types

#include <type/SimpleType.h>

namespace TRICEPS_NS {

Erref SimpleType::getErrors() const
{
	return NULL; // never any errors
}

}; // TRICEPS_NS
