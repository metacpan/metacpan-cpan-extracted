//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Encapsulation of a row operation.

#include <sched/Rowop.h>
#include <sched/Label.h>
#include <sched/Gadget.h>
#include <common/StringUtil.h>

namespace TRICEPS_NS {

Rowop::Rowop(const Label *label, Opcode op, const Row *row) :
	label_(label),
	row_(row),
	opcode_(op),
	enqMode_(Gadget::EM_FORK)
{
	assert(label);
	if (row_)
		row_->incref(); // manual reference keeping
}

Rowop::Rowop(const Label *label, Opcode op, const Rowref &row) :
	label_(label),
	row_(row),
	opcode_(op),
	enqMode_(Gadget::EM_FORK)
{
	assert(label);
	if (row_)
		row_->incref(); // manual reference keeping
}

Rowop::Rowop(const Label *label, Opcode op, const Row *row, int enqMode) :
	label_(label),
	row_(row),
	opcode_(op),
	enqMode_(enqMode)
{
	assert(label);
	if (row_)
		row_->incref(); // manual reference keeping
}

Rowop::Rowop(const Label *label, Opcode op, const Rowref &row, int enqMode) :
	label_(label),
	row_(row),
	opcode_(op),
	enqMode_(enqMode)
{
	assert(label);
	if (row_)
		row_->incref(); // manual reference keeping
}

Rowop::Rowop(const Rowop &orig) :
	label_(orig.getLabel()),
	row_(orig.getRow()),
	opcode_(orig.getOpcode()),
	enqMode_(orig.getEnqMode())
{
	if (row_)
		row_->incref(); // manual reference keeping
}

Rowop::Rowop(const Label *label, const Rowop *orig) :
	label_(label),
	row_(orig->getRow()),
	opcode_(orig->getOpcode()),
	enqMode_(orig->getEnqMode())
{
	if (row_)
		row_->incref(); // manual reference keeping
}

Rowop::~Rowop()
{
	if (row_) {
		if (row_->decref() <= 0)
			label_->getType()->destroyRow(const_cast<Row *>(row_));
	}
}

Valname opcodes[] = {
	{ Rowop::OP_NOP, "OP_NOP" },
	{ Rowop::OP_INSERT, "OP_INSERT" },
	{ Rowop::OP_DELETE, "OP_DELETE" },
	{ -1, NULL }
};

const char *Rowop::opcodeString(int code)
{
	const char *def = "?";
	const char *res = enum2string(opcodes, code, def);
	if (res == def) {
		// for the unknown opcodes, get at least the general sense
		if (isInsert(code) && isDelete(code))
			return "[ID]";
		else if (isInsert(code))
			return "[I]";
		else if (isDelete(code))
			return "[D]";
		else
			return "[NOP]";
	} else {
		return res;
	}
}

int Rowop::stringOpcode(const char *op)
{
	int res = string2enum(opcodes, op);
	if (res == -1)
		return OP_BAD;
	return res;
}

Valname opcodeFlags[] = {
	{ Rowop::OCF_INSERT, "OCF_INSERT" },
	{ Rowop::OCF_DELETE, "OCF_DELETE" },
	{ -1, NULL }
};

const char *Rowop::ocfString(int flag, const char *def)
{
	return enum2string(opcodeFlags, flag, def);
}

int Rowop::stringOcf(const char *flag)
{
	return string2enum(opcodeFlags, flag);
}

}; // TRICEPS_NS
