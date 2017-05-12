//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// The mark for Unit's execution frame.

#ifndef __Triceps_FrameMark_h__
#define __Triceps_FrameMark_h__

#include <common/Common.h>

namespace TRICEPS_NS {

class Unit;
class UnitFrame;

// The FrameMark is used to mark the frame where a loop starts,
// to later fork there the records for the next iteration of the loop.
class FrameMark : public Starget
{
	friend class Unit;
	friend class UnitFrame;

public:
	FrameMark(const string &name) :
		name_(name),
		unit_(NULL),
		frame_(NULL)
	{ }

	~FrameMark()
	{
		assert(frame_ == NULL);
	}

	const string &getName() const
	{
		return name_;
	}

	// A way for unit to check that the mark points to it.
	// Also used in XS code.
	Unit *getUnit() const
	{
		return unit_;
	}

protected:
	string name_;
	// if frame_ is NULL, unit_ and next_ are also guaranteed to be NULL
	Unit *unit_; // where the mark points, gets set together with frame_
	UnitFrame *frame_; // what is marked (not Autoref, to avoid circular references)
	Autoref <FrameMark> next_; // there may be multiple marks on a frame, forming a list

	///////////// API for Unit ///////////////////////////////
	
	// Clear recursively the whole list of marks starting from this mark.
	// When a frame gets popped, it uses this function to clear all its marks.
	void clear();

	// Reset this mark to NULLs.
	void reset()
	{
		next_ = NULL;
		frame_ = NULL;
		unit_ = NULL;
	}

	// Go recursively through the list and drop a mark from it.
	// When a mark that is still active gets reused, it is removed
	// from the old list before being put onto the new list.
	//
	// @param what - the mark to remove from the list
	void dropFromList(FrameMark *what);

	// Add this mark to a frame's list.
	// @param unit - unit owning the frame
	// @param frame - frame where it's added
	// @param list - the previous contents of the frame's list
	void set(Unit *unit, UnitFrame *frame, Onceref<FrameMark> list) 
	{
		frame_ = frame;
		unit_ = unit;
		next_ = list;
	}

	// A way for the Unit to find, what frame is marked.
	UnitFrame *getFrame() const
	{
		return frame_;
	}

private:
	FrameMark(const FrameMark &);
	void operator=(const FrameMark &);
};


}; // TRICEPS_NS

#endif // __Triceps_FrameMark_h__
