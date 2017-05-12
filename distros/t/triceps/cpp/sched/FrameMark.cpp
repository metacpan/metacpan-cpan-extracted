//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// The mark for Unit's execution frame.

#include <sched/FrameMark.h>

namespace TRICEPS_NS {

void FrameMark::clear()
{
	frame_ = NULL;
	if (!next_.isNull())
		next_->clear();
	next_ = NULL;
}

void FrameMark::dropFromList(FrameMark *what)
{
	if (next_.get() == what) {
		Autoref <FrameMark> m = what; // make sure that it doesn't get destroyed yet
		next_ = what->next_;
		what->reset();
	} else if (!next_.isNull()) {
		next_->dropFromList(what);
	}
}

}; // TRICEPS_NS
