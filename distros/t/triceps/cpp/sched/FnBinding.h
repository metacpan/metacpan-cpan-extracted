//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Binding of a streaming function return to a set of concrete labels.

#ifndef __Triceps_FnBinding_h__
#define __Triceps_FnBinding_h__

#include <type/RowSetType.h>
#include <sched/Label.h>
#include <sched/Tray.h>

namespace TRICEPS_NS {

class FnReturn;

// This defines the "return point" for a concrete call of a streaming
// function. It binds the labels int the function's return set to
// the concrete labels provided by the caller.
class FnBinding : public Starget
{
public:
	typedef vector<Autoref<Label> > LabelVec; 
	typedef vector<bool> BoolVec; 

	// The typical construction is done as a chain:
	// Autoref<FnBinding> bind = FnBinding::make(fn)
	//     ->addLabel("lb1", lb1, true)
	//     ->addLabel("lb2", lb2, false);
	//
	// Or to throw on errors:
	// Autoref<FnBinding> bind = checkOrThrow(FnBinding::make(fn)
	//     ->addLabel("lb1", lb1, true)
	//     ->addLabel("lb2", lb2, false)
	// );
	//
	// @param name - name of the binding (not strictly necessary but convenient
	//        for diagnostics.
	// @param fn - the return of the function to bind to. Must be initialized.
	FnBinding(const string &name, FnReturn *fn);
	~FnBinding();
	
	// The convenience wharpper for the constructor
	static FnBinding *make(const string &name, FnReturn *fn)
	{
		return new FnBinding(name, fn);
	}

	// Add a label to the binding. Any errors found can be read
	// later with getErrors(). The repeated bindings to the same
	// name are considered errors.
	//
	// This does not check for the label loops because that would not
	// cover all the possible mess-ups anyway. But you still must not
	// attempt to create the tight loops, or they will be caught at
	// run time.
	//
	// It is OK for the labels in the FnBinding be from a different
	// Unit than in FnReturn.
	//
	// @param name - name of the element in the return to bind to
	// @param lb - label to bind. Must have a matching row type.
	//        The binding will keep a reference to that label.
	// @param autoclear - flag: when the binding gets destroyed, automatically
	//        clear the label and forget it in the Unit, thus getting it
	//        destroyed when all the other references go.
	// @return - the same FnBinding object, for chained calls.
	FnBinding *addLabel(const string &name, Autoref<Label> lb, bool autoclear);

	// Set the tray collection mode: if enabled, instead of calling the
	// rowops immediately, they will be collected on a tray and can
	// be called later.
	//
	// @param on - true to enable the tray collection, false to disable.
	// @return - the same FnBinding object, for chained calls.
	FnBinding *withTray(bool on);

	// Get the current tray and replace it in the binding with a new
	// clean tray. If the tray mode is disabled, has no effect and returns NULL.
	// @return - the tray with collected data, or NULL is disabled.
	Onceref<Tray> swapTray();

	// Get the current tray.
	// @return - the current tray, or NULL is disabled.
	Tray *getTray() const
	{
		return tray_;
	}

	// Swap the tray and call all the collected rowops.
	// The swapping is done before calling anything, so if the calls cause
	// more data to be sent to the binding, it will be collected on the
	// fresh tray.
	// If the tray collection is not enabled, does nothing.
	//
	// Each rowop is called with its label's unit. Mixing units within one
	// binding and one tray is still generally not a good idea, but in
	// this particular case it happens to work correctly.
	//
	// May propagate the Exception from calling, or throw an Exception
	// if some label has been cleared. On exception, the rest of the
	// tray contents is thrown away.
	void callTray();

	// Get the collected error info. A binding with errors should
	// not be used for calls.
	Erref getErrors() const
	{
		return errors_;
	}

	// Get back the name.
	const string &getName() const
	{
		return name_;
	}

	// Get the number of labels in the type.
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

	// Get a label by name.
	// @param name - the name of the label, as was specified in addLabel()
	// @return - the label, or NULL if not found
	Label *getLabel(const string &name) const;
	
	// Translate the label name to its index in the internal array. This index
	// can later be used to get the label quickly.
	// @param name - the name of the label, as was specified in addLabel()
	// @return - the index, or -1 if not found
	int findLabel(const string &name) const;

	// Get back the label by index. Mostly for the benefit of FnReturn.
	// @param idx - index of the label
	// @return - the label pointer or NULL if that label is not defined
	Label *getLabel(int idx) const;

	// Get the type.
	RowSetType *getType() const
	{
		return type_;
	}

	// Get back the set of labels.
	// The elements that are not defined will be NULL.
	const LabelVec &getLabels() const
	{
		return labels_;
	}

	// Get back the clear flags
	const BoolVec &getAutoclear() const
	{
		return autoclear_;
	}

	// Check if the named label has the 
	// @return - the autoclear flag, or false for the unknown names.
	bool isAutoclear(const string &name) const;

	// This is technically not a type but these are convenient wrappers to
	// compare the equality of the underlying row set types.
	bool equals(const FnReturn *t) const;
	bool match(const FnReturn *t) const;
	bool equals(const FnBinding *t) const;
	bool match(const FnBinding *t) const;

protected:
	string name_;
	Autoref<RowSetType> type_; // type of FnReturn/FnBinding
	LabelVec labels_; // looked up by index
	BoolVec autoclear_; // of the same size as labels_
	Erref errors_; // the accumulated errors
	Autoref<Tray> tray_; // the collection tray, if enabled
};

}; // TRICEPS_NS

#endif // __Triceps_FnBinding_h__

