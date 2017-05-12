//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// An ordered set of names.

#ifndef __Triceps_NameSet_h__
#define __Triceps_NameSet_h__

#include <common/Common.h>
#include <mem/Mtarget.h>

namespace TRICEPS_NS {

// The ordered set of names gets used to specify subsets of fields,
// in particular, the index keys.
class NameSet : public Mtarget, public vector<string>
{
public:
	NameSet();
	NameSet(const vector<string> *other);
	NameSet(const vector<string> &other);
	// Constructors duplicated as make() for syntactically better usage.
	static NameSet *make()
	{
		return new NameSet;
	}
	static NameSet *make(const vector<string> *other)
	{
		return new NameSet(other);
	}
	static NameSet *make(const vector<string> &other)
	{
		return new NameSet(other);
	}

	// for chained initialization
	NameSet *add(const string &s);

	// compare for the exact same set
	bool equals(const NameSet *other) const;
};

}; // TRICEPS_NS

#endif // __Triceps_NameSet_h__
