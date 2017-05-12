//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// CEP code label.

#include <sched/Rowop.h>
#include <sched/Label.h>
#include <sched/Unit.h>
#include <common/Exception.h>
#include <common/BusyMark.h>

namespace TRICEPS_NS {

////////////////////////////////////// Label /////////////////////////////////

Label::Label(Unit *unit, const_Onceref<RowType> rtype, const string &name) :
	type_(rtype),
	unit_(unit),
	name_(name),
	recursion_(0),
	cleared_(false),
	nonReentrant_(false)
{
	assert(unit);
	assert(!type_.isNull());
	unit->rememberLabel(this);
}

Label::~Label()
{ }

// not inside the function, or it will be initialized in screwed-up order
static string placeholderUnitName = "[label cleared]";
const string &Label::getUnitName() const
{
	return cleared_? placeholderUnitName : unit_->getName();
}

Erref Label::chain(Onceref<Label> lab, bool front)
{
	assert(this != NULL);
	assert(!lab.isNull());
	if (!type_->equals(lab->type_)) {
		Erref err = new Errors;
		err->appendMsg(true, "can not chain labels with non-equal row types");
		err->appendMsg(true, "  " + getName() + ":");
		err->appendMsg(true, "    " + type_->print("    "));
		err->appendMsg(true, "  " + lab->getName() + ":");
		err->appendMsg(true, "    " + lab->type_->print("    "));
		return err;
	}
	ChainedVec path;
	if (lab.get() == this || lab->findChained(this, path)) {
		Erref err = new Errors;
		err->appendMsg(true, "labels must not be chained in a loop");
		string dep = "  " + getName() + "->" + lab->getName();
		while (!path.empty()) {
			dep += "->";
			dep += path.back()->getName();
			path.pop_back();
		}
		err->appendMsg(true, dep);
		return err;
	}

	if (front && !chained_.empty()) {
		// free space in the front by shifting all the contents
		chained_.push_back(chained_.back());
		for (int i = chained_.size() - 2; i > 0; i--)
			chained_[i] = chained_[i-1];
		// and then prepend the new reference
		chained_[0] = lab;
	} else {
		chained_.push_back(lab);
	}
	return NULL;
}

void Label::clearChained()
{
	chained_.clear();
}

void Label::clear()
{
	if (!cleared_) {
		cleared_ = true;
		Erref err;
		try {
			clearSubclass();
		} catch (Exception e) {
			err = e.getErrors();
		}
		clearChained();
		if (!err.isNull())
			throw Exception(err, false);
	}
}

void Label::clearSubclass()
{ }

void Label::call(Unit *unit, Rowop *arg, const Label *chainedFrom) const
{
	if (cleared_) // don't try to execute a cleared label
		return;

	if (unit != unit_) {
		throw Exception::fTrace("Triceps API violation: call() attempt with unit '%s' of label '%s' belonging to unit '%s'.\n", 
			unit->getName().c_str(), getName().c_str(), unit_->getName().c_str());
	}

	if (nonReentrant_ && recursion_ >= 1)
		throw Exception::fTrace("Detected a recursive call of the non-reentrant label '%s'.", getName().c_str());

	{
		int rec = unit->maxRecursionDepth();
		if (rec > 0 && recursion_ >= rec)
			throw Exception::fTrace("Exceeded the unit recursion depth limit %d (attempted %d) on the label '%s'.",
				rec, recursion_ + 1,
				getName().c_str());
	}

	BusyCounter bm(recursion_);

	// XXX this code would be cleaner without exceptions...
	try {
		unit->trace(this, chainedFrom, arg, Unit::TW_BEFORE);
	} catch (Exception e) {
		throw Exception::f(e, "Error when tracing before the label '%s':", getName().c_str());
	}
	try {
		execute(arg);
	} catch (Exception e) {
		Erref err = e.getErrors();
		err.f("Called through the label '%s'.", getName().c_str());
		throw; // the errors buffer got changed in place!
	}
	if (!chained_.empty()) {
		try {
			unit->trace(this, chainedFrom, arg, Unit::TW_BEFORE_CHAINED);
		} catch (Exception e) {
			throw Exception::f(e, "Error when tracing before the chain of the label '%s':", getName().c_str());
		}
		for (ChainedVec::const_iterator it = chained_.begin(); it != chained_.end(); ++it) {
			try {
				(*it)->call(unit, arg, this); // each of them can do their own chaining....
			} catch (Exception e) {
				Erref err = e.getErrors();
				err.f("Called chained from the label '%s'.", getName().c_str());
				throw; // the errors buffer got changed in place!
			}
		}
		try {
			unit->trace(this, chainedFrom, arg, Unit::TW_AFTER_CHAINED);
		} catch (Exception e) {
			throw Exception::f(e, "Error when tracing after the chain of the label '%s':", getName().c_str());
		}
	}
	try {
		unit->trace(this, chainedFrom, arg, Unit::TW_AFTER);
	} catch (Exception e) {
		throw Exception::f(e, "Error when tracing after execution of the label '%s':", getName().c_str());
	}

	// The tracing for TW_BEFORE_DRAIN and TW_AFTER_DRAIN happens in Unit.cpp.
}

bool Label::findChained(const Label *target, ChainedVec &path) const
{
	for (ChainedVec::const_iterator it = chained_.begin(); it != chained_.end(); ++it) {
		if ( it->get() == target || (*it)->findChained(target, path) ) {
			path.push_back(*it);
			return true;
		}
	}
	return false;
}

//////////////////////////////// DummyLabel ///////////////////////////////////////////

void DummyLabel::execute(Rowop *arg) const
{ }


}; // TRICEPS_NS
