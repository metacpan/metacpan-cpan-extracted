//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// An ordered set of names.

#include <type/NameSet.h>

namespace TRICEPS_NS {

NameSet::NameSet()
{ }

NameSet::NameSet(const vector<string> *other) :
	vector<string> (*other)
{ }

NameSet::NameSet(const vector<string> &other) :
	vector<string> (other)
{ }

NameSet *NameSet::add(const string &s)
{
	push_back(s);
	return this;
}

bool NameSet::equals(const NameSet *other) const
{
	if (this == other)
		return true;

	size_t n = size();
	if (n != other->size())
		return false;

	for (size_t i = 0; i < n; ++i)
		if ((*this)[i] != (*other)[i])
			return false;
	return true;
}

}; // TRICEPS_NS

