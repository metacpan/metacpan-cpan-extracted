//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Representation of a streaming function return.

#include <sched/FnReturn.h>
#include <sched/Unit.h>
#include <app/Facet.h>

namespace TRICEPS_NS {

FnReturn::FnReturn(Unit *unit, const string &name) :
	unit_(unit),
	facet_(NULL),
	name_(name),
	type_(new RowSetType),
	initialized_(false)
{ }

FnReturn::~FnReturn()
{
	for (size_t i = 0; i < labels_.size(); i++) {
		Label *lb = labels_[i];
		Unit *u = lb->getUnitPtr();
		if (u) {
			u->forgetLabel(lb);
			lb->clear();
		}
	}
}

// not inside the function, or it will be initialized in screwed-up order
static string placeholderUnitName = "[fn return cleared]";
const string &FnReturn::getUnitName() const
{
	return unit_? unit_->getName() : placeholderUnitName;
}

FnReturn *FnReturn::addFromLabel(const string &lname, Autoref<Label>from, bool front)
{
	if (initialized_)
		throw Exception::fTrace("Attempted to add label '%s' to an initialized FnReturn '%s'.", lname.c_str(), name_.c_str());

	if (from->getUnitPtr() != unit_) {
		// if the unit in the from label is NULL, this will crash
		type_->addError("Can not include the label '" + from->getName() 
			+ "' into the FnReturn as '" + lname + "': it has a different unit, '"
			+ from->getUnitPtr()->getName() + "' vs '" + unit_->getName() + "'.");
	} else {
		const RowType *rtype = from->getType();
		int szpre = type_->size();
		type_->addRow(lname, rtype);
		if (type_->size() != szpre) {
			// type detected no error
			Autoref<RetLabel> lb = new RetLabel(unit_, rtype, name_ + "." + lname, this, szpre);
			labels_.push_back(lb);
			Erref cherr = from->chain(lb, front);
			if (cherr->hasError())
				type_->appendErrors()->append("Failed the chaining of label '" + lname + "':", cherr);
		}
	}
	return this;
}

FnReturn *FnReturn::addLabel(const string &lname, const_Autoref<RowType>rtype)
{
	if (initialized_)
		throw Exception::fTrace("Attempted to add label '%s' to an initialized FnReturn '%s'.", lname.c_str(), name_.c_str());
	int szpre = type_->size();
	type_->addRow(lname, rtype);
	if (type_->size() != szpre) {
		// type detected no error
		Autoref<RetLabel> lb = new RetLabel(unit_, rtype, name_ + "." + lname, this, szpre);
		labels_.push_back(lb);
	}
	return this;
}

FnReturn *FnReturn::setContext(Onceref<FnContext> ctx)
{
	if (initialized_)
		throw Exception::fTrace("Attempted to set FnContext in an initialized FnReturn '%s'.", name_.c_str());
	if (context_)
		throw Exception::fTrace("Attempted to replace an existing FnContext in FnReturn '%s'.", name_.c_str());
	context_ = ctx;
	return this;
}

RowSetType *FnReturn::getType() const
{
	if (!initialized_)
		throw Exception::fTrace("Attempted to get the type from an uninitialized FnReturn '%s'.", name_.c_str());
	return type_;
}

bool FnReturn::equals(const FnReturn *t) const
{
	return type_->equals(t->type_);
}

bool FnReturn::match(const FnReturn *t) const
{
	return type_->match(t->type_);
}

bool FnReturn::equals(const FnBinding *t) const
{
	return type_->equals(t->getType());
}

bool FnReturn::match(const FnBinding *t) const
{
	return type_->match(t->getType());
}

Label *FnReturn::getLabel(const string &name) const
{
	return getLabel(type_->findName(name));
}

int FnReturn::findLabel(const string &name) const
{
	return type_->findName(name);
}

Label *FnReturn::getLabel(int idx) const
{
	if (idx >= 0 && idx < labels_.size())
		return labels_[idx];
	else
		return NULL;
}

void FnReturn::push(Onceref<FnBinding> bind)
{
	if (!type_->match(bind->getType())) 
		throw Exception::fTrace("Attempted to push a mismatching binding '%s' on the FnReturn '%s'.", 
			bind->getName().c_str(), name_.c_str());
	if (!initialized_)
		throw Exception::fTrace("Attempted to push a binding on an uninitialized FnReturn '%s'.", name_.c_str());
	if (!context_.isNull())
		context_->onPush(this);
	stack_.push_back(bind);
}

void FnReturn::pushUnchecked(Onceref<FnBinding> bind)
{
	if (!initialized_)
		throw Exception::fTrace("Attempted to push a binding on an uninitialized FnReturn '%s'.", name_.c_str());
	if (!context_.isNull())
		context_->onPush(this);
	stack_.push_back(bind);
}

void FnReturn::pop()
{
	if (stack_.empty())
		throw Exception::fTrace("Attempted to pop from an empty FnReturn '%s'.", name_.c_str());
	if (!context_.isNull())
		context_->onPop(this);
	stack_.pop_back();
}

void FnReturn::pop(Onceref<FnBinding> bind)
{
	if (stack_.empty())
		throw Exception::fTrace("Attempted to pop from an empty FnReturn '%s'.", name_.c_str());
	FnBinding *top = stack_.back();
	if (top != bind) {
		Erref stkerr = new Errors;
		for (int i = stack_.size()-1; i >= 0; i--)
			stkerr->appendMsg(true, stack_[i]->getName());
		Erref err = new Errors;
		err.f("Attempted to pop an unexpected binding '%s' from FnReturn '%s'.", 
			bind->getName().c_str(), name_.c_str());
		err->append("The bindings on the stack (top to bottom) are:", stkerr);
		throw Exception(err, true);
		// XXX should give some better diagnostics, helping to find the root cause.
	}
	if (!context_.isNull())
		context_->onPop(this);
	stack_.pop_back();
}

void FnReturn::setFacet(Facet *fa)
{
	facet_ = fa;
	if (fa != NULL) {
		int i;

		i = fa->beginIdx();
		if (i >= 0 && i < labels_.size())
			labels_[i]->isBegin_ = true;

		i = fa->endIdx();
		if (i >= 0 && i < labels_.size())
			labels_[i]->isEnd_ = true;
	}
}

Label *FnReturn::checkLabelChained(int idx) const
{
	if (idx < 0 || idx >= labels_.size())
 		return NULL;

	Label *lb = labels_[idx];
	if (lb->hasChained())
		return lb;

	if (stack_.empty())
		return NULL;

	FnBinding *top = stack_.back();
	if (top->getLabel(idx) != NULL)
		return lb; // always go honestly through FnReturn, no shortcuts directly to FnBinding
	return NULL;
}

///////////////////////////////////////////////////////////////////////////
// FnContext

FnContext::~FnContext()
{ }

///////////////////////////////////////////////////////////////////////////
// RetLabel

FnReturn::RetLabel::RetLabel(Unit *unit, const_Onceref<RowType> rtype, const string &name,
	FnReturn *fnret, int idx
) :
	Label(unit, rtype, name),
	fnret_(fnret),
	idx_(idx),
	isBegin_(false),
	isEnd_(false)
{ }

void FnReturn::RetLabel::execute(Rowop *arg) const
{
	// first see if the cross-nexus procesisng needs to be done
	{
		Xtray *xtray = fnret_->xtray_;
		if (xtray != NULL) { // this means a writer facet
			if (isBegin_) {
				if (!xtray->empty()) {
					// beginning of the next transaction flushes the last transaction
					fnret_->facet_->flushWriter();
					if ((xtray = fnret_->xtray_) == NULL)
						goto done_xtray;
				}
				if (!type_->isRowEmpty(arg->getRow()) || arg->getOpcode() != Rowop::OP_INSERT) // add the non-empty _BEGIN_ into the Xtray
					xtray->push_back(idx_, arg->getRow(), arg->getOpcode());
			} else if (isEnd_) {
				if (!type_->isRowEmpty(arg->getRow()) || arg->getOpcode() != Rowop::OP_INSERT) // add the non-empty _END_ into the Xtray
					xtray->push_back(idx_, arg->getRow(), arg->getOpcode());
				// flush right away
				if (!xtray->empty()) {
					fnret_->facet_->flushWriter();
				}
			} else {
				xtray->push_back(idx_, arg->getRow(), arg->getOpcode());
			}
		}
	}
done_xtray:

	// then the local processing
	if (fnret_->stack_.empty())
		return; // no binding yet
	FnBinding *top = fnret_->stack_.back();
	Label *lab = top->getLabel(idx_);
	if (lab == NULL)
		return; // not bound here

	Unit *u = lab->getUnitPtr();
	if (u == NULL)
		throw Exception::f("FnReturn '%s' attempted to call a cleared label '%s' in FnBinding '%s'.",
			fnret_->getName().c_str(), lab->getName().c_str(), top->getName().c_str());

	// This can safely call another unit.
	Autoref<Rowop> adrop = new Rowop(lab, arg);
	Tray *tray = top->getTray();
	if (tray) {
		tray->push_back(adrop);
	} else {
		if (u == unit_)
			u->callAsChained(lab, adrop, this); // this prevents the creation of an extra frame
		else
			u->call(adrop);
	}
}

void FnReturn::RetLabel::clearSubclass()
{
	fnret_->clear();
	fnret_ = NULL; // don't be tempted to use it again
}

///////////////////////////////////////////////////////////////////////////
// ScopeFnBind

ScopeFnBind::ScopeFnBind(Onceref<FnReturn> ret, Onceref<FnBinding> binding)
{
	ret->push(binding); // this might throw
	// Set the elements only after the dangers of throwing are over.
	ret_= ret;
	binding_ = binding;
}

ScopeFnBind::~ScopeFnBind()
{
	try {
		ret_->pop(binding_);
	} catch (Exception e) {
		// Make sure that the references get cleaned. Since this object
		// itself is allocated on the stack, there should be no memory
		// leak by throwing in the destructor, even when it doesn't abort.
		ret_ = NULL;
		binding_ = NULL;
		throw;
	}
}

///////////////////////////////////////////////////////////////////////////
// AutoFnBind

AutoFnBind *AutoFnBind::add(Onceref<FnReturn> ret, Autoref<FnBinding> binding)
{
	ret->push(binding);
	rets_.push_back(ret);
	bindings_.push_back(binding);
	return this;
}

void AutoFnBind::clear()
{
	// Pop in the opposite order. This is not a must, since presumably all the
	// FnReturns should be different. But just in case.
	Erref err;
	for (int i = rets_.size()-1; i >= 0; i--) {
		try {
			// fprintf(stderr, "DEBUG popping FnReturn '%s'\n", rets_[i]->getName().c_str());
			rets_[i]->pop(bindings_[i]);
		} catch (Exception e) {
			// fprintf(stderr, "DEBUG caught\n");
			err.fAppend(e.getErrors(), "AutoFnBind::clear: caught an exception at position %d", i);
		}
	}
	rets_.clear(); bindings_.clear();
	if (err->hasError()) {
		// fprintf(stderr, "DEBUG AutoFnBind::clear throwing\n");
		throw Exception(err, false); // no need to add stack, already in the messages
	}
}

AutoFnBind::~AutoFnBind()
{
	clear();
}

}; // TRICEPS_NS
