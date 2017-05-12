//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// A basic stateful element inside a Unit.

#ifndef __Triceps_Gadget_h__
#define __Triceps_Gadget_h__

#include <sched/Unit.h>

namespace TRICEPS_NS {

// A Gadget is something with its own mind, which in response to
// operations on it may produce records and enqueues them to the Unit's
// scheduler. A Gadget has its own dummy label for those records,
// so that processing can be chained from it. Duplicates of these
// records can also be collected on a Tray.
// A Table is a concrete example of Gadget.
//
// Gadgets are a part of Unit, so Starget is good enough.
class Gadget : public Starget
{
public:
	// How the rows get enqueued in the Unit
	enum EnqMode {
		EM_SCHEDULE,
		EM_FORK,
		EM_CALL,
		EM_IGNORE, // rows aren't equeued at all
	};

	virtual ~Gadget();

	// Get back the enqueueing mode
	EnqMode getEnqMode() const
	{
		return mode_;
	}
	
	// Get back the name
	const string &getName() const
	{
		return name_;
	}

	// Get the unit
	Unit *getUnit() const
	{
		return unit_;
	}

	// Get the label where the rowops will be sent to.
	// (Gadget is normally not going anywhere, so returning a pointer is OK).
	// @return - the label after it was initialized, or NULL before that
	Label *getLabel() const
	{
		return label_;
	}

	// Convert the EnqMode to string and back
	// @param enval - enum value
	// @param def - default string to return if not a known value
	static const char *emString(int enval, const char *def = "???");
	// @param str - string value
	// @return - if unknown, returns -1
	static int stringEm(const char *str);

protected:
	// interface for subclasses

	// @param unit - Unit where the gadget belongs
	// @param mode - how the rowops will be enqueued
	// @parem name - name of the gadget if known, will be used to name the label
	// @param rt - row type produced by this gadget, or NULL if not known yet
	Gadget(Unit *unit, EnqMode mode, const string &name, const_Onceref<RowType> rt = (const RowType*)NULL);

	// Change the enqueueing mode.
	void setEnqMode(EnqMode mode)
	{
		mode_ = mode;
	}

	// Set the row type. This initializes the label.
	void setRowType(const_Onceref<RowType> rt);

	// Send a row.
	// By this time the row type must be set, and so the embedded label initialized
	// (even if the mode is EM_IGNORE).
	//
	// If the user requests a copy, he should not try to schdeule it as is, since
	// that would repeat the change the second time. Instead he should either do a
	// translation on that tray or pick the records individually.
	//
	// @param row - row being sent, may be NULL which will be ignored and produce nothing
	// @param opcode - opcode for rowop
	// XXX later will add timestamp and sequence
	void send(const Row *row, Rowop::Opcode opcode) const;

	// Collect a row in the delayed tray, with the right enqueueing mode, to be
	// sent later. All the caveats from send() apply.
	//
	// @param dest - delayed tray, where the rowops will be appended with the proper EnqMode
	// @param row - row being sent, may be NULL which will be ignored and produce nothing
	// @param opcode - opcode for rowop
	void sendDelayed(Tray *dest, const Row *row, Rowop::Opcode opcode) const;

protected:
	Autoref<Unit> unit_; // unit where it belongs (and Unit must not autoref gadgets, to avoid loops)
	Autoref<Label> label_; // this gadget's label
	const_Autoref<RowType> type_; // type of rows
	string name_; // name of the gadget, passed to the label name
	EnqMode mode_; // how the rowops get enqueued in unit

private:
	Gadget(const Gadget &);
	void operator=(const Gadget &);
};

// a version that exports setEnqMode()
// (CS stands for Changeable Enqueueing)
class GadgetCE : public Gadget
{
public:
	GadgetCE(Unit *unit, EnqMode mode, const string &name = "", Onceref<RowType> rt = (RowType*)NULL) :
		Gadget(unit, mode, name, rt)
	{ }

	void setEnqMode(EnqMode mode)
	{
		mode_ = mode;
	}
};

}; // TRICEPS_NS

#endif // __Triceps_Gadget_h__
