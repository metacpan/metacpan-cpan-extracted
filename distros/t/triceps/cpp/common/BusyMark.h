//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// A scope-based helper class to set and clear the busy mark.

#ifndef __Triceps_Proto_h__
#define __Triceps_Proto_h__

#include <common/Common.h>

namespace TRICEPS_NS {

// Set the mark to true on construction and reset to false on destruction.
class BusyMark
{
public:
	// @param markp - mark to set now and clear on leaving the scope
	BusyMark(bool &mark) :
		markp_(&mark)
	{ 
		mark = true; // mark busy
	}

	~BusyMark()
	{
		*markp_ = false;
	}

protected:
	bool *markp_;

private:
	BusyMark(); // no default constructor
};

// Increase the counter on construction and decrease on destruction.
class BusyCounter
{
public:
	// @param markp - mark to set now and clear on leaving the scope
	BusyCounter(int &count) :
		cp_(&count)
	{ 
		++count; // mark busy
	}

	~BusyCounter()
	{
		--*cp_;
	}

protected:
	int *cp_;

private:
	BusyCounter(); // no default constructor
};

}; // TRICEPS_NS

#endif // __Triceps_Proto_h__

