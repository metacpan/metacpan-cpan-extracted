//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// The basic execution unit.

#include <sched/Unit.h>
#include <sched/Gadget.h>
#include <common/StringUtil.h>
#include <common/Exception.h>
#include <type/CompactRowType.h>

namespace TRICEPS_NS {

///////////////////////////// UnitFrame //////////////////////////////////

UnitFrame::~UnitFrame()
{
	clear();
}

void UnitFrame::clear()
{
	if (!markList_.isNull()) { // when a frame is popped, all its marks are forgotten
		markList_->clear();
		markList_ = NULL;
	}
	if (!empty())
		Tray::clear();
}

void UnitFrame::mark(Unit *unit, Onceref<FrameMark> mk)
{
	// first see if the mark has to be reassigned
	UnitFrame *oldf = mk->getFrame();
	if (oldf == this) // already here
		return;
	if (oldf != NULL)
		oldf->dropFromList(mk);

	// now point it here
	mk->set(unit, this, markList_);
	markList_ = mk;
}

void UnitFrame::dropFromList(FrameMark *what)
{
	if (markList_.get() == what) {
		Autoref <FrameMark> m = what; // make sure that it doesn't get destroyed yet
		markList_ = what->next_;
		what->reset();
	} else if (!markList_.isNull()) {
		markList_->dropFromList(what);
	}
}

///////////////////////////// Unit::Tracer //////////////////////////////////

Unit::Tracer::Tracer(RowPrinter *rp):
	rowPrinter_(rp),
	buffer_(new Errors)
{ }

Unit::Tracer::~Tracer()
{ }

void Unit::Tracer::printRow(string &res, const RowType *rt, const Row *row)
{
	if (rowPrinter_)
		rowPrinter_(res, rt, row);
}

void Unit::Tracer::clearBuffer()
{
	buffer_ = new Errors;
}

Erref Unit::Tracer::getBuffer()
{
	return buffer_;
}

///////////////////////////// Unit::StringTracer //////////////////////////////////

Unit::StringTracer::StringTracer(bool verbose, RowPrinter *rp) :
	Tracer(rp),
	verbose_(verbose)
{ }

void Unit::StringTracer::execute(Unit *unit, const Label *label, const Label *fromLabel, Rowop *rop, TracerWhen when)
{
	if (!verbose_ && when != TW_BEFORE)
		return;

	string res = strprintf("unit %p '%s' %s label %p '%s' ",
		unit, unit->getName().c_str(), tracerWhenHumanString(when),
		label, label->getName().c_str());

	if (fromLabel != NULL) {
		res.append(strprintf("(chain %p '%s') ", fromLabel, fromLabel->getName().c_str()));
	};
	res.append(strprintf("op %p %s", rop, Rowop::opcodeString(rop->getOpcode()) ));
	printRow(res,  label->getType(), rop->getRow());

	if (verbose_) {
		if (Unit::tracerWhenIsBefore(when))
			res.append(" {");
		else if (Unit::tracerWhenIsAfter(when))
			res.append(" }");
	}

	buffer_->appendMsg(false, res);
}

///////////////////////////// Unit::StringNameTracer //////////////////////////////////

Unit::StringNameTracer::StringNameTracer(bool verbose, RowPrinter *rp) :
	StringTracer(verbose, rp)
{ }

void Unit::StringNameTracer::execute(Unit *unit, const Label *label, const Label *fromLabel, Rowop *rop, TracerWhen when)
{
	if (!verbose_ && when != TW_BEFORE)
		return;

	string res = strprintf("unit '%s' %s label '%s' ", 
		unit->getName().c_str(), tracerWhenHumanString(when), label->getName().c_str());

	if (fromLabel != NULL) {
		res.append("(chain '");
		res.append(fromLabel->getName());
		res.append("') ");
	};
	res.append("op ");
	res.append(Rowop::opcodeString(rop->getOpcode()));
	printRow(res,  label->getType(), rop->getRow());

	if (verbose_) {
		if (Unit::tracerWhenIsBefore(when))
			res.append(" {");
		else if (Unit::tracerWhenIsAfter(when))
			res.append(" }");
	}

	buffer_->appendMsg(false, res);
}

///////////////////////////// Unit //////////////////////////////////

Unit::Unit(const string &name) :
	name_(name), stackDepth_(1),
	maxStackDepth_(0), maxRecursionDepth_(1),
	clearing_(false)
{
	// the outermost frame is always present
	innerFrame_ = outerFrame_ = new UnitFrame;
	queue_.push_front(outerFrame_);

	// create the empty row type instance
	RowType::FieldVec fv; // empty!
	emptyRowType_ = new CompactRowType(fv);
	assert(emptyRowType_->getErrors().isNull());
}

Unit::~Unit()
{
	clearLabels();
}

void Unit::schedule(Onceref<Rowop> rop)
{
	// XXX check the Unit match in the label
	outerFrame_->push_back(rop);
}

void Unit::scheduleTray(const_Onceref<Tray> tray)
{
	for (Tray::const_iterator it = tray->begin(); it != tray->end(); ++it)
		// XXX check the Unit match in the label
		outerFrame_->push_back(*it);
}


void Unit::fork(Onceref<Rowop> rop)
{
	// XXX check the Unit match in the label
	innerFrame_->push_back(rop);
}

void Unit::forkTray(const_Onceref<Tray> tray)
{
	for (Tray::const_iterator it = tray->begin(); it != tray->end(); ++it)
		// XXX check the Unit match in the label
		innerFrame_->push_back(*it);
}


void Unit::call(Onceref<Rowop> rop)
{
	callGuts(rop);
}

void Unit::callGuts(Rowop *rop)
{
	if (maxStackDepth_ > 0 && stackDepth_ >= maxStackDepth_) {
		throw Exception::fTrace("Unit '%s' exceeded the stack depth limit %d, current depth %d, when calling the label '%s'.",
			name_.c_str(), maxStackDepth_, stackDepth_+1, rop->getLabel()->getName().c_str());
	}

	pushFrame();

	try {
		rop->getLabel()->call(this, rop); // may throw
		drainForkedFrame(rop->getLabel(), rop);
	} catch (Exception e) {
		popFrame();
		throw;
	}

	popFrame();
}

void Unit::callTray(const_Onceref<Tray> tray)
{
	pushFrame();

	try {
		forkTray(tray);
		drainFrame();
	} catch (Exception e) {
		popFrame();
		throw;
	}

	popFrame();
}

void Unit::enqueue(int em, Onceref<Rowop> rop)
{
	switch(em) {
	case Gadget::EM_SCHEDULE:
		schedule(rop);
		break;
	case Gadget::EM_FORK:
		fork(rop);
		break;
	case Gadget::EM_CALL:
		call(rop); // may throw
		break;
	case Gadget::EM_IGNORE:
		break;
	default:
		throw Exception::fTrace("Triceps API violation: Invalid enqueueing mode %d\n", em);
		break;
	}
}

void Unit::enqueueTray(int em, const_Onceref<Tray> tray)
{
	switch(em) {
	case Gadget::EM_SCHEDULE:
		scheduleTray(tray);
		break;
	case Gadget::EM_FORK:
		forkTray(tray);
		break;
	case Gadget::EM_CALL:
		callTray(tray); // may throw
		break;
	case Gadget::EM_IGNORE:
		break;
	default:
		throw Exception::fTrace("Triceps API violation: Invalid enqueueing mode %d\n", em);
		break;
	}
}

void Unit::enqueueDelayedTray(const_Onceref<Tray> tray)
{
	for (Tray::const_iterator it = tray->begin(); it != tray->end(); ++it) {
		// XXX check the Unit match in the label
		Rowop *rop = *it;
		enqueue(rop->getEnqMode(), rop); // may throw
	}
}

void Unit::setMark(Onceref<FrameMark> mark)
{
	if (innerFrame_ == outerFrame_) {
		// At outermost frame: clear the mark.
		// This has historic reasons but still works conveniently:
		// a cleared mark is treated as at the outermost frame.
		UnitFrame *oldf = mark->getFrame();
		if (oldf != NULL)
			oldf->dropFromList(mark);
	} else {
		// mark the parent frame
		innerFrame_->mark(this, mark);
	}
}

void Unit::loopAt(FrameMark *mark, Onceref<Rowop> rop)
{
	UnitFrame *f = mark->getFrame();
	// XXX check the Unit match in the label
	if (f == NULL) {
		outerFrame_->push_back(rop);
	} else {
		if (mark->getUnit() != this) {
			throw Exception::fTrace("Triceps API violation: loopAt() attempt on unit '%s' with mark '%s' from unit '%s'\n", 
				getName().c_str(), mark->getName().c_str(), mark->getUnit()->getName().c_str());
		}
		f->push_back(rop);
	}
}

void Unit::loopTrayAt(FrameMark *mark, const_Onceref<Tray> tray)
{
	UnitFrame *f = mark->getFrame();
	// XXX check the Unit match in the label
	if (f == NULL) {
		f = outerFrame_;
	} else {
		if (mark->getUnit() != this) {
			throw Exception::fTrace("Triceps API violation: loopTrayAt() attempt on unit '%s' with mark '%s' from unit '%s'\n", 
				getName().c_str(), mark->getName().c_str(), mark->getUnit()->getName().c_str());
		}
	}
	for (Tray::const_iterator it = tray->begin(); it != tray->end(); ++it)
		f->push_back(*it);
}

void Unit::callNext()
{
	if (!innerFrame_->empty()) {
		Autoref<Rowop> rop = innerFrame_->front();
		innerFrame_->pop_front();
		callGuts(rop);
	}
}

void Unit::drainFrame()
{
	try {
		while (!innerFrame_->empty())
			callNext(); // may throw
	} catch (Exception e) {
		innerFrame_->clear(); // the frame gets cleared anyway, by throwing things out
		throw;
	}
}

void Unit::callNextForked()
{
	if (!innerFrame_->empty()) {
		Autoref<Rowop> rop = innerFrame_->front();
		innerFrame_->pop_front();

		// Runs in the parent's inherited frame.
		rop->getLabel()->call(this, rop); // may throw
		// No frame draining afterwards.
	}
}

void Unit::drainForkedFrame(const Label *lab, Rowop *rop)
{
	if (innerFrame_->empty())
		return;

	try {
		trace(lab, NULL, rop, Unit::TW_BEFORE_DRAIN);
	} catch (Exception e) {
		throw Exception::f(e, "Error when tracing before draining the label '%s':",
			lab->getName().c_str());
	}
	try {
		while (!innerFrame_->empty())
			callNextForked(); // may throw
	} catch (Exception e) {
		innerFrame_->clear(); // the frame gets cleared anyway, by throwing things out
		// this might not be the exact parent label, since the forking might have
		// been done by one of the labels chained from it, or by a label that
		// has been forked itself
		throw Exception::f(e, "Called when draining the frame of label '%s'.", 
			lab->getName().c_str());
	}
	try {
		trace(lab, NULL, rop, Unit::TW_AFTER_DRAIN);
	} catch (Exception e) {
		throw Exception::f(e, "Error when tracing after draining the label '%s':",
			lab->getName().c_str());
	}
}

bool Unit::empty() const
{
	return innerFrame_ == outerFrame_ && innerFrame_->empty();
}

void Unit::pushFrame()
{
	if (freePool_.empty()) {
		innerFrame_ = new UnitFrame;
		queue_.push_front(innerFrame_);
	} else {
		innerFrame_ = freePool_.front();
		queue_.push_front(innerFrame_);
		freePool_.pop_front(); // only after it has been pushed onto queue
	}
	stackDepth_++;
	// fprintf(stderr, "DEBUG Unit::pushFrame (%d) new %p\n", (int)queue_.size(), innerFrame_);
}

void Unit::popFrame()
{
	// fprintf(stderr, "DEBUG Unit::popFrame (%d) was %p\n", (int)queue_.size(), innerFrame_);
	
	// make sure that there are no stray rowops left (such as after an exception)
	innerFrame_->clear(); 

	if (innerFrame_ != outerFrame_) { // never pop the outermost frame
		freePool_.push_front(innerFrame_); // save for later
		queue_.pop_front();
		innerFrame_ = queue_.front();
		stackDepth_--;
	}
	// fprintf(stderr, "DEBUG Unit::popFrame (%d) now %p\n", (int)queue_.size(), innerFrame_);
}

Valname twhens[] = {
	{ Unit::TW_BEFORE, "TW_BEFORE" },
	{ Unit::TW_BEFORE_CHAINED, "TW_BEFORE_CHAINED" },
	{ Unit::TW_AFTER_CHAINED, "TW_AFTER_CHAINED" },
	{ Unit::TW_AFTER, "TW_AFTER" },
	{ Unit::TW_BEFORE_DRAIN, "TW_BEFORE_DRAIN" },
	{ Unit::TW_AFTER_DRAIN, "TW_AFTER_DRAIN" },
	{ -1, NULL }
};

Valname humanTwhens[] = {
	{ Unit::TW_BEFORE, "before" },
	{ Unit::TW_BEFORE_CHAINED, "before-chained" },
	{ Unit::TW_AFTER_CHAINED, "after-chained" },
	{ Unit::TW_AFTER, "after" },
	{ Unit::TW_BEFORE_DRAIN, "before-drain" },
	{ Unit::TW_AFTER_DRAIN, "after-drain" },
	{ -1, NULL }
};

const char *Unit::tracerWhenString(int when, const char *def)
{
	return enum2string(twhens, when, def);
}

int Unit::stringTracerWhen(const char *when)
{
	return string2enum(twhens, when);
}

const char *Unit::tracerWhenHumanString(int when, const char *def)
{
	return enum2string(humanTwhens, when, def);
}

int Unit::humanStringTracerWhen(const char *when)
{
	return string2enum(humanTwhens, when);
}

void Unit::setTracer(Onceref<Tracer> tracer)
{
	tracer_ = tracer;
}

void Unit::trace(const Label *label, const Label *fromLabel, Rowop *rop, TracerWhen when)
{
	if (!tracer_.isNull()) {
		tracer_->execute(this, label, fromLabel, rop, when);
	}
}

void Unit::clearLabels()
{
	if (clearing_)
		return; // avoid the recursive calls
	clearing_ = true;
	for(LabelMap::iterator it = labelMap_.begin(); it != labelMap_.end(); ++it) {
		try {
			it->first->clear();
		} catch (Exception e) {
			// can not pass the exception through, because may be called in the destructor
			Erref err = e.getErrors();
			fprintf(stderr, "%s", err->print().c_str());
		}
	}
	labelMap_.clear();
	clearing_ = false;
}

void Unit::rememberLabel(Label *lab)
{
	if (clearing_)
		return;
	labelMap_[lab] = lab;
}

void  Unit::forgetLabel(Label *lab)
{
	if (clearing_)
		return;
	labelMap_.erase(lab);
}

///////////////////////////// UnitClearingTrigger //////////////////////////////////

UnitClearingTrigger::UnitClearingTrigger(Unit *unit) :
	unit_(unit)
{ }

UnitClearingTrigger::~UnitClearingTrigger()
{
	unit_->clearLabels();
}

}; // TRICEPS_NS
