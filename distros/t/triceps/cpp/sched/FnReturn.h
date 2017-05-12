//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Representation of a streaming function return.

#ifndef __Triceps_FnReturn_h__
#define __Triceps_FnReturn_h__

#include <type/RowSetType.h>
#include <sched/Label.h>
#include <sched/FnBinding.h>
#include <app/Xtray.h>

namespace TRICEPS_NS {

class Facet;

// The concept of the streaming function is:
// You call some label(s), that performs some streaming computations and 
// produces the result on some other labels. Before you do the call, you
// connect these result labels with some other labels that would handle
// the result. It's like pushing the return address of a common function
// call onto the stack: tells, where to continue with handling of the
// function results after it returns. Unlike the common function call,
// the streaming function may produce multiple result rowops on its result
// labels, and normally the return handlers would be called for them
// right when they are produced, without waiting for the complete function
// return.
//
// FnReturn describes the set of return labels of a streaming function.
// Each of them has a name (by which the handler can be collected later)
// and may be immediately chained to another label on creation.
//
// Since all the labels are single-threaded, the return value is single-
// threaded too.
//

// The call "context" (the arguments that control the processing
// of the other streaming data) can be set up either by calling
// a procedural function or method in the subclass or by sending
// some rowops through some inputs of the function before the
// "data" rowops.
//
// The FnReturn is very inconvenient to subclass, so the context has
// its own class that can be attached to a FnReturn.
// The methods "onPush" and "onPop" can be defined in the subclass
// of FnContext to save and restore this context for the recursive calls.
class FnContext: public Starget
{
public:
	virtual ~FnContext();

	// See the discussion of the call context before the class
	// definition. Methods that allow a subclass to save and restore
	// the call context in the recursive calls.
	// May throw an Exception.
	// onPush() is called before a new binding is pushed.
	// onPop() is called before a binding is popped. If the pop attempt
	// encounters an unexpected binding, onPop() won't be called.
	// Both are called before to provide consistency across all the
	// possible reasons of exceptions: if anything goes wrong and
	// an exception is throws, the push or pop won't be completed.
	//
	// @param fret - the return on which the stack operation happens.
	virtual void onPush(const FnReturn *fret) = 0;
	virtual void onPop(const FnReturn *fret) = 0;
};

class FnReturn: public Starget
{
	friend class Facet;
	friend class TrieadOwner;
protected:
	// The class of labels created inside FnReturn, that forward the rowops
	// to the final destination.
	class RetLabel : public Label
	{
		friend class FnReturn;
	public:
		// @param unit - the unit where this label belongs
		// @param rtype - type of row to be handled by this label
		// @param name - a human-readable name of this label, for tracing
		// @param fnret - FnReturn where this label belongs
		// @param idx - index of this label in FnReturn
		RetLabel(Unit *unit, const_Onceref<RowType> rtype, const string &name,
			FnReturn *fnret, int idx);

	protected:
		// from Label
		// Throws an Exception if the label in the binding is cleared.
		virtual void execute(Rowop *arg) const;
		// from Label
		// Clears the FnReturn.
		virtual void clearSubclass();

		FnReturn *fnret_; // not a ref, to avoid cyclic refs
		int idx_; // index in fnret_ to which to forward
		bool isBegin_; // this label represents a _BEGIN_ in a Facet
		bool isEnd_; // this label represents an _END_ in a Facet
	};

public:
	// representation of the labels in this return
	typedef vector<Autoref<RetLabel> > ReturnVec;
	// representation of the call stack
	typedef vector<Autoref<FnBinding> > BindingVec;

	// The typical construction is done as a chain:
	// ret = initialize(FnReturn::make(unit, name)
	//     ->addLabel("lb1", rt1)
	//     ->addFromLabel("lb2", lbX)
	// );
	//
	// Or with throwing on errors:
	// ret = initializeOrThrow(FnReturn::make(unit, name)
	//     ->addLabel("lb1", rt1)
	//     ->addFromLabel("lb2", lbX)
	// );
	//
	// @param unit - the unit where this return belongs
	// @param name - a human-readable name of this return set
	FnReturn(Unit *unit, const string &name);

	// The convenience wharpper for the constructor.
	// Obviously, it's good only for the base class; for the
	// subclasses either call new() or define a make() in them.
	static FnReturn *make(Unit *unit, const string &name)
	{
		return new FnReturn(unit, name);
	}

	// The destructor clears and unregisters all its labels.
	~FnReturn();

	// Get back the name.
	const string &getName() const
	{
		return name_;
	}

	// If any of return's labels has been cleared, returns NULL, so name it
	// differently, preventing the accidental mistakes.
	Unit *getUnitPtr() const
	{
		return unit_;
	}

	// Getting the unit name is typical, so handle the situation with being cleared.
	// by returning a placeholder.
	const string &getUnitName() const;

	// Add a label to the result. Any errors will be remembered and
	// reported during initialization.
	// May be used only until initialized.
	//
	// Technically, a RetLabel label gets created in the FnReturn,
	// having the same type as the argument label, and getting
	// chained to that argument label.
	//
	// Adding multiple copies of the same label is technically legal
	// but achieves nothing useful, just multiple aliases.
	//
	// @param lname - name, by which this label can be connected later;
	//        the actual label name will be return-name.label-name
	// @param from - a label, from which the row type will be taken, 
	//        and to which the result label will be chained.
	//        Must belong to the same unit (or error will be remembered).
	// @param front - flag: chain this label at the front of the "from" label
	//        Is true by default, matching Perl!
	// @return - the same FnReturn object, for chained calls.
	FnReturn *addFromLabel(const string &lname, Autoref<Label>from, bool front = true);
	
	// Add a RetLabel to the result. Any errors will be remembered and
	// reported during initialization.
	// May be used only until initialized.
	//
	// @param lname - name, by which this label can be connected later;
	//   the actual label name will be return-name.label-name
	// @param rtype - row type for the label
	// @return - the same FnReturn object, for chained calls.
	FnReturn *addLabel(const string &lname, const_Autoref<RowType>rtype);

	// Set an FnContext for the result. Only one context may be added.
	// May be used only until initialized.
	// @param ctx - the context object; the return creates a reference to it;
	//   that reference is removed when any of the FnReturn's labels get cleared.
	FnReturn *setContext(Onceref<FnContext> ctx);

	// Get back the context. May be NULL.
	FnContext *context() const
	{
		return context_.get();
	}

	// Get back the context, with the casting to a subclass. May be NULL.
	template<class C>
	C *contextIn() const
	{
		return static_cast<C *>(context_.get());
	}

	// Check all the definition and derive the internal
	// structures. The result gets returned by getErrors().
	// May be called repeatedly with no ill effects.
	// @return - the same FnReturn object, for chained calls.
	void initialize()
	{
		type_->initialize();
		initialized_ = true;
	}

	// Whether it was already initialized
	bool isInitialized() const
	{
		return initialized_;
	}

	// Get the type. Works only after initialization. Throws an
	// Exception before then.
	RowSetType *getType() const;

	// Get all the errors detected during construction.
	Erref getErrors() const
	{
		return type_->getErrors();
	}
	// Get the number of labels
	int size() const
	{
		return labels_.size();
	}

	// Propagation from type_.
	const RowSetType::NameVec &getLabelNames() const
	{
		return type_->getRowNames();
	}
	const RowSetType::RowTypeVec &getRowTypes() const
	{
		return type_->getRowTypes();
	}
	const string *getLabelName(int idx) const
	{
		return type_->getRowTypeName(idx);
	}
	RowType *getRowType(const string &name) const
	{
		return type_->getRowType(name);
	}
	RowType *getRowType(int idx) const
	{
		return type_->getRowType(idx);
	}

	// This is technically not a type but these are convenient wrappers to
	// compare the equality of the underlying row set types.
	bool equals(const FnReturn *t) const;
	bool match(const FnReturn *t) const;
	bool equals(const FnBinding *t) const;
	bool match(const FnBinding *t) const;

	// Get a label by name.
	// @param name - the name of the label, as was specified in addLabel()
	// @return - the label, or NULL if not found
	Label *getLabel(const string &name) const;
	
	// Translate the label name to its index in the internal array. This index
	// can later be used to get the label quickly.
	// @param name - the name of the label, as was specified in addLabel()
	// @return - the index, or -1 if not found
	int findLabel(const string &name) const;

	// Get a label by its index in the internal array.
	// @param idx - the name of the label, as was specified in addLabel()
	// @return - the label, or NULL if not found
	Label *getLabel(int idx) const;

	// Get back the set of labels.
	const ReturnVec &getLabels() const
	{
		return labels_;
	}

	// Push a binding onto the "call stack". The binding on the top
	// of the stack will be used to forward the rowops.
	//
	// Throws an Exception if not initialized or if a binding is of
	// not a matching type.
	//
	// @param bind - the binding. Must be of a matching type or may
	void push(Onceref<FnBinding> bind);

	// Similar to push(), only doesn't check that the types of the
	// return and binding match (assuming that the caller knows what
	// it's duing).
	// Throws an Exception if not initialized.
	//
	// @param bind - the binding. Must be of a matching type or may
	//        crash if it's not.
	void pushUnchecked(Onceref<FnBinding> bind);

	// Pop a binding from the top of the stack.
	// Throws an Exception if the stack is empty.
	void pop();
	// Pop a binding from the top of the stack and check that it
	// matches the expected ones. If it doesn't match, will throw
	// an Exception. Useful for diagnostics of incorrect push-pop sequences.
	// @param bind - the expected binding.
	void pop(Onceref<FnBinding> bind);

	// Mostly for diagnostics: get the binding stack size.
	int bindingStackSize() const
	{
		return stack_.size();
	}

	// mostly for diagnostics: get the binding stack
	const BindingVec &bindingStack() const
	{
		return stack_;
	}

	// Check whether this FnReturn is used to write to a facet.
	bool isFaceted() const
	{
		return !xtray_.isNull();
	}

protected:
	// Called on the clearing of any RetLabel in this return.
	void clear()
	{
		if (unit_) {
			unit_ = NULL;
			context_ = NULL;
		}
	}

	// Interface for Facet
	// {

	// Check if the Xtray is empty.
	bool isXtrayEmpty() const
	{
		return xtray_.isNull() || xtray_->empty();
	}

	// Swap the xtray reference. 
	// This is used in multiple ways:
	// * to set up the first tray when the FnReturn gets tied to a writer Facet
	// * to set a fresh xtray and get the filled one to send it to the nexus
	// * to clear the xtray when the Facet disconnectes itself from FnReturn
	// @param other - other Xtray reference to swap with
	void swapXtray(Autoref<Xtray> &other)
	{
		xtray_.swap(other);
	}

	// Set the relation to a Facet.
	// Sets facet_ and the flags in the labels that represent _BEGIN_ and _END_.
	void setFacet(Facet *fa);

	// }

	// Interface for TrieadOwner (closely connected to Facet).
	// {

	// Check whether the label either has a chaining directly from the
	// FnReturn or is defined in the current pushed binding. This is used by
	// TrieadOwner to decide whether it needs to generate the artificial
	// _BEGIN_ and _END_ rowops.
	// @param idx - index of the label
	// @return - pointer to the label of there is a chaining, NULL if not
	Label *checkLabelChained(int idx) const;
	// }

	Unit *unit_; // not a reference, used only to create the labels
	Facet *facet_; // not a reference, the facet that wraps this object, or NULL; set directly by Facet
	string name_; // human-readable name, and base for the label names
	Autoref<RowSetType> type_;
	Autoref<FnContext> context_;
	Autoref<Xtray> xtray_; // if writing to a Nexus, the buffer to collect the transaction
	ReturnVec labels_; // the return labels, same size as the type
	BindingVec stack_; // the top of call stack is the end of vector
	bool initialized_; // flag: has already been initialized, no more changes allowed
};

// Bind and unbind a return as a scope:
// push on object creation, pop on object deletion.
// {
//     ScopeFnBind autobind(ret, binding);
//     ...
// }
class ScopeFnBind
{
public:
	// Pushes the binding on construction.
	ScopeFnBind(Onceref<FnReturn> ret, Onceref<FnBinding> binding);
	// Pops the binding on destruction.
	// May throw an Exception if the binding stack got messed up.
	~ScopeFnBind();

protected:
	Autoref<FnReturn> ret_;
	Autoref<FnBinding> binding_;
};

// Bind and unbind multiple returns as a group, and maintain the set
// by reference (this allows it to be used from Perl).
// The typical use (provided that all the calls are correct):
// {
//     Autoref<AutoFnBind> bind = AutoFnBind::make()
//         ->add(ret1, binding1)
//         ->add(ret2, binding2);
//     ...
// }
// But if add() might throw, that would leave a memory leak of the
// AutoFnBind object. Then assign it to an Autoref first, and call
// add() later:
// {
//     Autoref<AutoFnBind> bind = new AutoFnBind;
//     bind
//         ->add(ret1, binding1)
//         ->add(ret2, binding2);
//     ...
// }
class AutoFnBind: public Starget
{
public:
	// The default constructor works good enough.
	
	// Pops the binding on destruction (calls clear() internally).
	// If the stack order got disrupted, this may throw an Exception.
	// Which is OK for the C++ programs with the default exception handling
	// by abort(). If not aborting, an exception from a destructor is
	// a Bad Thing. In this case (such as in the scripting language wrappers)
	// should call clear() first, process the exceptions if any, and only
	// then destroy.
	~AutoFnBind();

	// Pop the bindings and forget about them.
	// If the stack order got disrupted, this may throw an Exception.
	// It will go through all the elements backwards, doing pop() for each of them,
	// and catching the exceptions. Then all the bindings information
	// will be cleared. Then if any exceptions were caught,
	// a new exception will be thrown with all the collected info.
	void clear();

	// a convenience factory, more convenient to use than parenthesis
	// around the new statement
	static AutoFnBind *make()
	{
		return new AutoFnBind;
	}

	// push a binding, and remember it for popping
	// @param ret - return to push onto
	// @param binding - binding to push
	// @return - the same AutoFnBind object, for chained calls
	AutoFnBind *add(Onceref<FnReturn> ret, Autoref<FnBinding> binding);

protected:
	vector<Autoref<FnReturn> > rets_;
	vector<Autoref<FnBinding> > bindings_;
};

}; // TRICEPS_NS

#endif // __Triceps_FnReturn_h__

