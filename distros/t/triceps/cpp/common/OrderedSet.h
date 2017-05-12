//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// An set that preserves the order of insertions but weeds out duplicates

#ifndef __Triceps_OrderedSet_h__
#define __Triceps_OrderedSet_h__

#include <set>
#include <vector>

namespace TRICEPS_NS {

template<typename Target>

// The operations follow the STL model, but only a subset is available.
// Insert-only, no removal (other than full clearing).
class OrderedSet
{
public:
	typedef vector<Target>::iterator iterator;
	// typedef vector<Target>::const_iterator const_iterator;

	OrderedSet()
	{ }

	OrderedSet(const OrderedSet &orig) :
		order_(orig.order_),
		set_(orig.set_)
	{ }

	void reserve(size_t size)
	{
		order_.reserve(size);
	}

	void clear()
	{
		order_.clear();
		set_.clear();
	}

	size_t size() const
	{
		return order_.size();
	}

	// insert an element
	// @return - true if this element was not in the set yet
	bool insert(const Target &elem)
	{
		pait<set<Target>::iterator, bool> res = set_.insert(elem);
		if (res.second) {
			order_.push_back(elem);
			return true;
		} else
			return false;
	}

	iterator begin() const
	{
		return order_.begin();
	}

	iterator end() const
	{
		return order_.end();
	}

	// the contents is read-only
	const Target &at(size_t i) const
	{
		return order_[i];
	}

	const Target &operator[](size_t i) const
	{
		return order_[i];
	}

protected:
	vector<Target> order_;
	set<Target> set_;
};

}; // TRICEPS_NS

#endif // __Triceps_OrderedSet_h__
