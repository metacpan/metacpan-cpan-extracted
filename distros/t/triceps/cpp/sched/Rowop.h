//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Encapsulation of a row operation.

#ifndef __Triceps_Rowop_h__
#define __Triceps_Rowop_h__

#include <type/RowType.h>
#include <mem/Starget.h>

namespace TRICEPS_NS {

class Label;
class Row;
class Rowref;

// A row operation provides the basic scheduling element for the execution
// unit. It ties together the row argument (may be NULL in some special cases),
// the opcode, additional information such as timestamp and sequence number,
// and the label to call for handling of the row.
// The rowops are fundamentally tied to an execution Unit, so they live
// withing a single thread. They can not be directly passed between two execution
// units even in a single thread, instead they mush be translated. Similarly,
// they need to be translated for passing to a unit inside another thread.
//
// A rowop may also have an enqueueing mode from a gadget. This mostly
// has to do with ordering the aggregator changes right relative to the
// main table change. Most uses of Rowop ignore that mode, except the
// few specially marked ones.
class Rowop : public Starget
{
public:
	enum OpcodeFlags {
		// Each opcode has the flags in the lower 2 bits, classifying it.
		// This allows some labels to act based on this crude classification,
		// without goin into the deeper opcode details. The classification is:
		//   0 - a NOP
		//   INSERT - insert a row, also used for generally passing the rows around
		//   DELETE - delete a row, generally undoing a previous action
		//   (INSERT|DELETE) - currently not defined and may cause random effects
		OCF_INSERT = 0x01,
		OCF_DELETE = 0x02
	};

	enum Opcode {
		OP_NOP = 0,
		OP_INSERT = OCF_INSERT,
		OP_DELETE = OCF_DELETE,
		OP_BAD = (~3), // a NOP opcode returned in bad conversions from string
	};

	// Rowop will hold the references on the row and the label.
	// This defaults the enqMode to EM_FORK as the safest one (see the 
	// explanation before the class, in the normal uses the enqMode is ignored).
	// XXX think of checking the type of row 
	Rowop(const Label *label, Opcode op, const Row *row);
	Rowop(const Label *label, Opcode op, const Rowref &row);

	// The same with explicit enqueueing mode (see the explanation before the class).
	// This way is used in the guts of aggregators.
	// @param enqMode - really a Gadget::EnqMode, but here int to avoid a circular
	//        header dependency; how this row should be enqueued.
	Rowop(const Label *label, Opcode op, const Row *row, int enqMode);
	Rowop(const Label *label, Opcode op, const Rowref &row, int enqMode);

	Rowop(const Rowop &orig);
	// Adoption: use the same opcode etc. with another label
	Rowop(const Label *label, const Rowop *orig);

	~Rowop();

	Opcode getOpcode() const 
	{
		return opcode_;
	}

	// get the crude classification of Opcode
	static bool isInsert(int op)
	{
		return (op & OCF_INSERT);
	}
	static bool isDelete(int op)
	{
		return (op & OCF_DELETE);
	}
	static bool isNop(int op)
	{
		return (op & (OCF_INSERT|OCF_DELETE)) == 0;
	}
	bool isInsert() const
	{
		return isInsert(opcode_);
	}
	bool isDelete() const
	{
		return isDelete(opcode_);
	}
	bool isNop() const
	{
		return isNop(opcode_);
	}

	const Label *getLabel() const
	{
		return  label_;
	}

	const Row *getRow() const
	{
		return row_;
	}

	int getEnqMode() const
	{
		return enqMode_;
	}

	// Convert the opcode to string and back
	static const char *opcodeString(int code);
	// @return - if unknown, returns OP_BAD
	static int stringOpcode(const char *op);

	// Convert the opcode flags to string and back
	static const char *ocfString(int flag, const char *def = "???");
	static int stringOcf(const char *flag);

protected:
	const_Autoref<Label> label_;
	const Row *row_; // a manual reference, the type from Label will be used for deletion
	// no timestamp nor sequence now, these will come later
	Opcode opcode_;
	int enqMode_; // enqueueing mode, as in Gadget::EnqMode

private:
	Rowop();
	void operator=(const Rowop &);
};

}; // TRICEPS_NS

#endif // __Triceps_Rowop_h__
