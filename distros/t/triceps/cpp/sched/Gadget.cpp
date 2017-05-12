//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// A basic stateful element inside a Unit.

#include <sched/Gadget.h>
#include <common/StringUtil.h>

namespace TRICEPS_NS {

Gadget::Gadget(Unit *unit, EnqMode mode, const string &name, const_Onceref<RowType> rt) :
	unit_(unit),
	name_(name),
	mode_(mode)
{
	assert(unit);
	if (!rt.isNull())
		setRowType(rt);
}

Gadget::~Gadget()
{ }

void Gadget::setRowType(const_Onceref<RowType> rt)
{
	type_ = rt;
	if (!rt.isNull()) {
		label_ = new DummyLabel(unit_, type_, name_);
	}
}

void Gadget::send(const Row *row, Rowop::Opcode opcode) const
{
	// fprintf(stderr, "DEBUG Gadget::send(row=%p, opcode=0x%x) mode=%d\n", row, opcode, mode_);
	assert(!label_.isNull());

	if (row == NULL)
		return; // nothing to do

	if (mode_ != EM_IGNORE) {
		Autoref<Rowop> rop = new Rowop(label_, opcode, row);
		switch(mode_) {
		case EM_SCHEDULE:
			unit_->schedule(rop);
			break;
		case EM_FORK:
			unit_->fork(rop);
			break;
		case EM_CALL:
			unit_->call(rop);
			break;
		default:
			break; // shut up the compiler
		}
	}
}

void Gadget::sendDelayed(Tray *dest, const Row *row, Rowop::Opcode opcode) const
{
	// fprintf(stderr, "DEBUG Gadget::sendDelayed(dest=%p, row=%p, opcode=0x%x) mode=%d\n", dest, row, opcode, mode_);
	assert(!label_.isNull());

	if (row == NULL)
		return; // nothing to do

	if (mode_ != EM_IGNORE) {
		Autoref<Rowop> rop = new Rowop(label_, opcode, row, mode_);
		dest->push_back(rop);
	}
}

Valname enqModes[] = {
	{ Gadget::EM_SCHEDULE, "EM_SCHEDULE" },
	{ Gadget::EM_FORK, "EM_FORK" },
	{ Gadget::EM_CALL, "EM_CALL" },
	{ Gadget::EM_IGNORE, "EM_IGNORE" },
	{ -1, NULL }
};

const char *Gadget::emString(int enval, const char *def)
{
	return enum2string(enqModes, enval, def);
}

int Gadget::stringEm(const char *str)
{
	return string2enum(enqModes, str);
}


}; // TRICEPS_NS
