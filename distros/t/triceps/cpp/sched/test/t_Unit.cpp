//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Test of Unit scheduling and components.

#include <utest/Utest.h>
#include <string.h>

#include <type/CompactRowType.h>
#include <common/StringUtil.h>
#include <common/Exception.h>
#include <sched/Unit.h>
#include <sched/Gadget.h>

// Make fields of all simple types
void mkfields(RowType::FieldVec &fields)
{
	fields.clear();
	fields.push_back(RowType::Field("a", Type::r_uint8, 10));
	fields.push_back(RowType::Field("b", Type::r_int32,0));
	fields.push_back(RowType::Field("c", Type::r_int64));
	fields.push_back(RowType::Field("d", Type::r_float64));
	fields.push_back(RowType::Field("e", Type::r_string));
}

uint8_t v_uint8[10] = "123456789";
int32_t v_int32 = 1234;
int64_t v_int64 = 0xdeadbeefc00c;
double v_float64 = 9.99e99;
char v_string[] = "hello world";

void mkfdata(FdataVec &fd)
{
	fd.resize(4);
	fd[0].setPtr(true, &v_uint8, sizeof(v_uint8));
	fd[1].setPtr(true, &v_int32, sizeof(v_int32));
	fd[2].setPtr(true, &v_int64, sizeof(v_int64));
	fd[3].setPtr(true, &v_float64, sizeof(v_float64));
	// test the constructor
	fd.push_back(Fdata(true, &v_string, sizeof(v_string)));
}

// this just makes sure that the code snippet for the doc compiles
class SampleTracer : public Unit::Tracer
{           
public: 
    virtual void execute(Unit *unit, const Label *label,
		const Label *fromLabel, Rowop *rop, Unit::TracerWhen when)
    {   
        printf("trace %s label '%s' %c\n", Unit::tracerWhenHumanString(when),
			label->getName().c_str(), Unit::tracerWhenIsBefore(when)? '{' : '}');
    }
};

UTESTCASE mkunit(Utest *utest)
{
	Autoref<Unit> unit1 = new Unit("my unit");
	UT_IS(unit1->getName(), "my unit");
	
	UT_IS(unit1->getStackDepth(), 1);

	// try setting a tracer
	Autoref<Unit::Tracer> tracer1 = new Unit::StringNameTracer;
	UT_IS(unit1->getTracer().get(), NULL);
	unit1->setTracer(tracer1);
	UT_IS(unit1->getTracer().get(), tracer1);

	UT_ASSERT(unit1->empty());
	UT_ASSERT(unit1->getEmptyRowType() != NULL);
}

UTESTCASE mklabel(Utest *utest)
{
	// make row types for labels
	RowType::FieldVec fld;
	mkfields(fld);

	Autoref<RowType> rt1 = new CompactRowType(fld);
	if (UT_ASSERT(rt1->getErrors().isNull())) return;

	// rt2 is equal to rt1
	Autoref<RowType> rt2 = new CompactRowType(fld);
	if (UT_ASSERT(rt2->getErrors().isNull())) return;

	// rt3 is matching to rt1
	fld[0].name_ = "field1";
	Autoref<RowType> rt3 = new CompactRowType(fld);
	if (UT_ASSERT(rt3->getErrors().isNull())) return;
	
	// rt4 is outright different
	fld[0].type_ = Type::r_float64;
	Autoref<RowType> rt4 = new CompactRowType(fld);
	if (UT_ASSERT(rt4->getErrors().isNull())) return;

	Autoref<Unit> unit1 = new Unit("unit1");
	
	Autoref<Label> lab1 = new DummyLabel(unit1, rt1, "lab1");
	Autoref<Label> lab2 = new DummyLabel(unit1, rt2, "lab2");
	Autoref<Label> lab3 = new DummyLabel(unit1, rt3, "lab3");
	Autoref<Label> lab4 = new DummyLabel(unit1, rt4, "lab4");

	Autoref<Label> lab11 = new DummyLabel(unit1, rt1, "lab11");
	Autoref<Label> lab12 = new DummyLabel(unit1, rt1, "lab12");
	Autoref<Label> lab13 = new DummyLabel(unit1, rt1, "lab13");

	UT_IS(lab1->getType(), rt1.get());
	UT_IS(lab2->getType(), rt2.get());
	UT_IS(lab3->getType(), rt3.get());
	UT_IS(lab4->getType(), rt4.get());

	UT_ASSERT(!lab1->chain(lab2)->hasError());
	Erref ec3 = lab1->chain(lab3);
	if (!UT_ASSERT(ec3->hasError())) {
		UT_IS(ec3->print(), 
			"can not chain labels with non-equal row types\n"
			"  lab1:\n"
			"    row {\n"
			"      uint8[10] a,\n"
			"      int32[] b,\n"
			"      int64 c,\n"
			"      float64 d,\n"
			"      string e,\n"
			"    }\n"
			"  lab3:\n"
			"    row {\n"
			"      uint8[10] field1,\n"
			"      int32[] b,\n"
			"      int64 c,\n"
			"      float64 d,\n"
			"      string e,\n"
			"    }\n"
		);
	}
	UT_ASSERT(lab1->chain(lab4)->hasError());

	Erref ecloop = lab2->chain(lab1); // this tries to create a circular chain
	if (!UT_ASSERT(ecloop->hasError())) {
		UT_IS(ecloop->print(), 
			"labels must not be chained in a loop\n"
			"  lab2->lab1->lab2\n"
		);
	}

	ecloop = lab2->chain(lab2); // this tries to create a circular chain of label to itself
	if (!UT_ASSERT(ecloop->hasError())) {
		UT_IS(ecloop->print(), 
			"labels must not be chained in a loop\n"
			"  lab2->lab2\n"
		);
	}

	UT_ASSERT(lab1->hasChained());
	UT_IS(lab1->getChain().size(), 1);
	UT_ASSERT(lab1->getChain()[0] == lab2);
	
	lab1->clearChained(); // undoes the endless loop
	UT_ASSERT(!lab1->hasChained());
	UT_IS(lab1->getChain().size(), 0);
	UT_ASSERT(!lab1->chain(lab11)->hasError());
	UT_ASSERT(!lab1->chain(lab12)->hasError());
	UT_IS(lab1->getChain().size(), 2);
	UT_ASSERT(lab1->getChain()[0] == lab11);
	UT_ASSERT(lab1->getChain()[1] == lab12);

	lab1->clearChained(); // clear again and chain from the front
	UT_ASSERT(!lab1->hasChained());
	UT_IS(lab1->getChain().size(), 0);
	UT_ASSERT(!lab1->chain(lab11, true)->hasError());
	UT_ASSERT(!lab1->chain(lab12, true)->hasError());
	UT_ASSERT(!lab1->chain(lab13, true)->hasError());
	UT_IS(lab1->getChain().size(), 3);
	UT_ASSERT(lab1->getChain()[0] == lab13);
	UT_ASSERT(lab1->getChain()[1] == lab12);
	UT_ASSERT(lab1->getChain()[2] == lab11);

	// play with names
	UT_IS(lab1->getName(), "lab1");
}

UTESTCASE rowop(Utest *utest)
{
	// make a unit 
	Autoref<Unit> unit = new Unit("my unit");

	// make row for setting
	RowType::FieldVec fld;
	mkfields(fld);

	Autoref<RowType> rt1 = new CompactRowType(fld);
	if (UT_ASSERT(rt1->getErrors().isNull())) return;

	FdataVec dv;
	mkfdata(dv);
	Rowref r1(rt1,  rt1->makeRow(dv));

	if (UT_ASSERT(!r1.isNull())) return;

	// make a few labels
	Autoref<Label> lab1 = new DummyLabel(unit, rt1, "lab1");
	Autoref<Label> lab2 = new DummyLabel(unit, rt1, "lab2");
	Autoref<Label> lab3 = new DummyLabel(unit, rt1, "lab3");

	UT_IS(lab1->getUnitPtr(), unit.get());
	UT_IS(lab1->getUnitName(), "my unit");

	// now make the rowops
	Autoref<Rowop> op1 = new Rowop(lab1, Rowop::OP_NOP, NULL);
	UT_ASSERT(!op1.isNull()); // make the compiler shut up about unused vars
	Autoref<Rowop> op2 = new Rowop(lab2, Rowop::OP_INSERT, rt1->makeRow(dv));
	UT_ASSERT(!op2.isNull()); // make the compiler shut up about unused vars
	Autoref<Rowop> op3 = new Rowop(lab3, Rowop::OP_DELETE, r1);
	UT_ASSERT(!op3.isNull()); // make the compiler shut up about unused vars

	// the opcode translation
	UT_ASSERT(!Rowop::isInsert(Rowop::OP_NOP));
	UT_ASSERT(!Rowop::isDelete(Rowop::OP_NOP));
	UT_ASSERT(Rowop::isNop(Rowop::OP_NOP));
	UT_ASSERT(Rowop::isInsert(Rowop::OP_INSERT));
	UT_ASSERT(!Rowop::isDelete(Rowop::OP_INSERT));
	UT_ASSERT(!Rowop::isNop(Rowop::OP_INSERT));
	UT_ASSERT(!Rowop::isInsert(Rowop::OP_DELETE));
	UT_ASSERT(Rowop::isDelete(Rowop::OP_DELETE));
	UT_ASSERT(!Rowop::isNop(Rowop::OP_DELETE));
	UT_ASSERT(Rowop::isInsert((Rowop::Opcode)0x333));
	UT_ASSERT(Rowop::isDelete((Rowop::Opcode)0x333));
	UT_ASSERT(!Rowop::isNop((Rowop::Opcode)0x333));
	UT_ASSERT(!Rowop::isInsert((Rowop::Opcode)0x330));
	UT_ASSERT(!Rowop::isDelete((Rowop::Opcode)0x330));
	UT_ASSERT(Rowop::isNop((Rowop::Opcode)0x330));

	UT_ASSERT(!op1->isInsert());
	UT_ASSERT(!op1->isDelete());
	UT_ASSERT(op1->isNop());
	UT_ASSERT(op2->isInsert());
	UT_ASSERT(!op2->isDelete());
	UT_ASSERT(!op2->isNop());
	UT_ASSERT(!op3->isInsert());
	UT_ASSERT(op3->isDelete());
	UT_ASSERT(!op3->isNop());

	UT_IS(string(Rowop::opcodeString(Rowop::OP_NOP)), "OP_NOP");
	UT_IS(string(Rowop::opcodeString(Rowop::OP_INSERT)), "OP_INSERT");
	UT_IS(string(Rowop::opcodeString(Rowop::OP_DELETE)), "OP_DELETE");
	UT_IS(string(Rowop::opcodeString((Rowop::Opcode)0x330)), "[NOP]");
	UT_IS(string(Rowop::opcodeString((Rowop::Opcode)0x331)), "[I]");
	UT_IS(string(Rowop::opcodeString((Rowop::Opcode)0x332)), "[D]");
	UT_IS(string(Rowop::opcodeString((Rowop::Opcode)0x333)), "[ID]");

	UT_IS(Rowop::stringOpcode("OP_NOP"), Rowop::OP_NOP);
	UT_IS(Rowop::stringOpcode("OP_INSERT"), Rowop::OP_INSERT);
	UT_IS(Rowop::stringOpcode("OP_DELETE"), Rowop::OP_DELETE);
	UT_IS(Rowop::stringOpcode("[I]"), Rowop::OP_BAD);

	UT_IS(string(Rowop::ocfString(Rowop::OCF_INSERT)), "OCF_INSERT");
	UT_IS(string(Rowop::ocfString(Rowop::OCF_DELETE)), "OCF_DELETE");
	UT_IS(string(Rowop::ocfString((Rowop::OpcodeFlags)0x333)), "???");
	UT_IS(string(Rowop::ocfString((Rowop::OpcodeFlags)0x333, "unknown")), "unknown");
	UT_IS(Rowop::ocfString((Rowop::OpcodeFlags)0x333, NULL), NULL);

	UT_IS(Rowop::stringOcf("OCF_INSERT"), Rowop::OCF_INSERT);
	UT_IS(Rowop::stringOcf("OCF_DELETE"), Rowop::OCF_DELETE);
	UT_IS(Rowop::stringOcf("OP_INSERT"), -1);

	// getting back the components
	UT_IS(op1->getOpcode(), Rowop::OP_NOP);
	UT_IS(op2->getOpcode(), Rowop::OP_INSERT);
	UT_IS(op3->getOpcode(), Rowop::OP_DELETE);

	UT_IS(op1->getLabel(), lab1.get());
	UT_IS(op2->getLabel(), lab2.get());
	UT_IS(op3->getLabel(), lab3.get());

	UT_IS(op1->getRow(), NULL);
	UT_ASSERT(op2->getRow() != NULL);
	UT_IS(op3->getRow(), r1.get());
}

#if 0 // {
// for scheduling test, make labels that push more labels
// onto the queue in different ways.
// (note that memory management here works only because there are no loops in the graph)
class LabelCallTwo : public Label
{
public:
	LabelCallTwo(Unit *unit, Onceref<RowType> rtype, const string &name,
			Onceref<Rowop> sub1, Onceref<Rowop> sub2) :
		Label(unit, rtype, name),
		sub1_(sub1),
		sub2_(sub2)
	{ }

	virtual void execute(Rowop *arg) const
	{
		unit_->call(sub1_);
		unit_->enqueue(Gadget::EM_CALL, sub2_);
	}

	Autoref<Rowop> sub1_, sub2_;
};

class LabelForkTwo : public Label
{
public:
	LabelForkTwo(Unit *unit, Onceref<RowType> rtype, const string &name,
			Onceref<Rowop> sub1, Onceref<Rowop> sub2) :
		Label(unit, rtype, name),
		sub1_(sub1),
		sub2_(sub2)
	{ }

	virtual void execute(Rowop *arg) const
	{
		unit_->fork(sub1_);
		unit_->enqueue(Gadget::EM_FORK, sub2_);
	}

	Autoref<Rowop> sub1_, sub2_;
};

class LabelSchedTwo : public Label
{
public:
	LabelSchedTwo(Unit *unit, Onceref<RowType> rtype, const string &name,
			Onceref<Rowop> sub1, Onceref<Rowop> sub2) :
		Label(unit, rtype, name),
		sub1_(sub1),
		sub2_(sub2)
	{ }

	virtual void execute(Rowop *arg) const
	{
		unit_->schedule(sub1_);
		unit_->schedule(sub2_);
	}

	Autoref<Rowop> sub1_, sub2_;
};
#endif // }

class LabelSchedForkCall : public Label
{
public:
	LabelSchedForkCall(Unit *unit, Onceref<RowType> rtype, const string &name,
			Onceref<Label> sub1, Onceref<Label> sub2, Onceref<Label> sub3, Rowref r) :
		Label(unit, rtype, name),
		sub1_(sub1),
		sub2_(sub2),
		sub3_(sub3),
		r_(r)
	{ }

	virtual void execute(Rowop *arg) const
	{
		unit_->schedule(new Rowop(sub1_, Rowop::OP_INSERT, r_));
		unit_->schedule(new Rowop(sub1_, Rowop::OP_DELETE, r_));
		unit_->fork(new Rowop(sub2_, Rowop::OP_INSERT, r_));
		unit_->fork(new Rowop(sub2_, Rowop::OP_DELETE, r_));
		unit_->call(new Rowop(sub3_, Rowop::OP_INSERT, r_));
		unit_->call(new Rowop(sub3_, Rowop::OP_DELETE, r_));
	}

	Autoref<Label> sub1_, sub2_, sub3_;
	Rowref r_;
};

// test all 3 kinds of scheduling
UTESTCASE scheduling(Utest *utest)
{
	// make a unit 
	Autoref<Unit> unit = new Unit("u");
	Autoref<Unit::Tracer> trace = new Unit::StringNameTracer;
	unit->setTracer(trace);

	// make row for setting
	RowType::FieldVec fld;
	mkfields(fld);

	Autoref<RowType> rt1 = new CompactRowType(fld);
	if (UT_ASSERT(rt1->getErrors().isNull())) return;

	FdataVec dv;
	mkfdata(dv);
	Rowref r1(rt1,  rt1->makeRow(dv));

	if (UT_ASSERT(!r1.isNull())) return;

	// make a few labels
	Autoref<Label> lab1 = new DummyLabel(unit, rt1, "lab1");
	Autoref<Label> lab2 = new DummyLabel(unit, rt1, "lab2");
	Autoref<Label> lab3 = new DummyLabel(unit, rt1, "lab3");

	Autoref<Label> lab4 = new LabelSchedForkCall(unit, rt1, "lab4", lab1, lab2, lab3, r1);
	Autoref<Label> lab5 = new LabelSchedForkCall(unit, rt1, "lab5", lab1, lab2, lab3, r1);

	Autoref<Rowop> op4 = new Rowop(lab4, Rowop::OP_NOP, NULL);
	Autoref<Rowop> op5 = new Rowop(lab5, Rowop::OP_NOP, NULL);

	unit->schedule(op4);
	unit->enqueue(Gadget::EM_SCHEDULE, op5);
	UT_ASSERT(!unit->empty());

	// now run it
	unit->drainFrame();
	UT_ASSERT(unit->empty());

	string tlog;
	tlog = trace->getBuffer()->print();

	string expect_sched = 
		"unit 'u' before label 'lab4' op OP_NOP\n"
		"unit 'u' before label 'lab3' op OP_INSERT\n"
		"unit 'u' before label 'lab3' op OP_DELETE\n"
		"unit 'u' before label 'lab2' op OP_INSERT\n"
		"unit 'u' before label 'lab2' op OP_DELETE\n"

		"unit 'u' before label 'lab5' op OP_NOP\n"
		"unit 'u' before label 'lab3' op OP_INSERT\n"
		"unit 'u' before label 'lab3' op OP_DELETE\n"
		"unit 'u' before label 'lab2' op OP_INSERT\n"
		"unit 'u' before label 'lab2' op OP_DELETE\n"

		"unit 'u' before label 'lab1' op OP_INSERT\n"
		"unit 'u' before label 'lab1' op OP_DELETE\n"
		"unit 'u' before label 'lab1' op OP_INSERT\n"
		"unit 'u' before label 'lab1' op OP_DELETE\n"
	;

	UT_IS(tlog, expect_sched);

	// now clear the log and do the same with a tray
	trace->clearBuffer();
	tlog = trace->getBuffer()->print();
	UT_IS(tlog, "");

	Autoref<Tray> tray = new Tray;
	tray->push_back(op4);
	tray->push_back(op5);

	unit->scheduleTray(tray);

	tray->push_back(op4); // mess with the tray afterwards, check that it doesn't affect what is scheduled
	tray->push_back(op5);
	UT_IS(tray->size(), 4);

	unit->drainFrame(); // run and check the result
	UT_ASSERT(unit->empty());
	tlog = trace->getBuffer()->print();
	UT_IS(tlog, expect_sched);

	// the same schedule through enqueueTray

	trace->clearBuffer();
	tlog = trace->getBuffer()->print();
	UT_IS(tlog, "");

	tray->clear(); // make the same train contents again
	tray->push_back(op4);
	tray->push_back(op5);

	unit->enqueueTray(Gadget::EM_SCHEDULE, tray);

	unit->drainFrame(); // run and check the result
	UT_ASSERT(unit->empty());
	tlog = trace->getBuffer()->print();
	UT_IS(tlog, expect_sched);

	// try the tray version of fork() - produces the same result
	trace->clearBuffer();
	tlog = trace->getBuffer()->print();
	UT_IS(tlog, "");

	unit->forkTray(tray); // reuse the tray contents from before

	unit->drainFrame();
	UT_ASSERT(unit->empty());
	tlog = trace->getBuffer()->print();
	UT_IS(tlog, expect_sched);

	// the same schedule through enqueueTray

	trace->clearBuffer();
	tlog = trace->getBuffer()->print();
	UT_IS(tlog, "");

	unit->enqueueTray(Gadget::EM_FORK, tray); // reuse the tray contents from before

	unit->drainFrame(); // run and check the result
	UT_ASSERT(unit->empty());
	tlog = trace->getBuffer()->print();
	UT_IS(tlog, expect_sched);

	// the tray version of call() - this one is different
	trace->clearBuffer();
	tlog = trace->getBuffer()->print();
	UT_IS(tlog, "");
	tray->clear();

	unit->schedule(new Rowop(lab1, Rowop::OP_NOP, r1)); // add a little background

	tray->push_back(op4);
	tray->push_back(op5);

	unit->callTray(tray); // produces the immediate result, so check it before draining

	string expect_call_1 = 
		"unit 'u' before label 'lab4' op OP_NOP\n"
		"unit 'u' before label 'lab3' op OP_INSERT\n"
		"unit 'u' before label 'lab3' op OP_DELETE\n"
		"unit 'u' before label 'lab2' op OP_INSERT\n"
		"unit 'u' before label 'lab2' op OP_DELETE\n"

		"unit 'u' before label 'lab5' op OP_NOP\n"
		"unit 'u' before label 'lab3' op OP_INSERT\n"
		"unit 'u' before label 'lab3' op OP_DELETE\n"
		"unit 'u' before label 'lab2' op OP_INSERT\n"
		"unit 'u' before label 'lab2' op OP_DELETE\n"
	;

	UT_ASSERT(!unit->empty());
	tlog = trace->getBuffer()->print();
	UT_IS(tlog, expect_call_1);

	trace->clearBuffer(); // then pick up the delayed processing
	unit->drainFrame();

	string expect_call_2 = 
		"unit 'u' before label 'lab1' op OP_NOP\n"
		"unit 'u' before label 'lab1' op OP_INSERT\n"
		"unit 'u' before label 'lab1' op OP_DELETE\n"
		"unit 'u' before label 'lab1' op OP_INSERT\n"
		"unit 'u' before label 'lab1' op OP_DELETE\n"
	;

	UT_ASSERT(unit->empty());
	tlog = trace->getBuffer()->print();
	UT_IS(tlog, expect_call_2);
}

// the row printer for tracing
void printB(string &res, const RowType *rt, const Row *row)
{
	int32_t b = rt->getInt32(row, 1, 0); // field b at idx 1
	res.append(strprintf(" b=%d", (int)b));
}

// test the chaining of labels
UTESTCASE chaining(Utest *utest)
{
	// make a unit 
	Autoref<Unit> unit = new Unit("u");
	Autoref<Unit::Tracer> trace = new Unit::StringNameTracer(true);
	unit->setTracer(trace);

	// make row for setting
	RowType::FieldVec fld;
	mkfields(fld);

	Autoref<RowType> rt1 = new CompactRowType(fld);
	if (UT_ASSERT(rt1->getErrors().isNull())) return;

	FdataVec dv;
	mkfdata(dv);
	Rowref r1(rt1,  rt1->makeRow(dv));

	int32_t val4321 = 4321;
	dv[1].setPtr(true, &val4321, sizeof(val4321));
	Rowref r2(rt1,  rt1->makeRow(dv));

	if (UT_ASSERT(!r1.isNull())) return;

	// make a few labels
	Autoref<Label> lab1 = new DummyLabel(unit, rt1, "lab1");
	Autoref<Label> lab2 = new DummyLabel(unit, rt1, "lab2");
	Autoref<Label> lab3 = new DummyLabel(unit, rt1, "lab3");

	// add chaining
	UT_ASSERT(!lab1->chain(lab2)->hasError());
	UT_ASSERT(!lab1->chain(lab3)->hasError());
	UT_ASSERT(!lab2->chain(lab3)->hasError());

	Autoref<Rowop> op1 = new Rowop(lab1, Rowop::OP_INSERT, r1);
	Autoref<Rowop> op2 = new Rowop(lab1, Rowop::OP_DELETE, r2);

	unit->schedule(op1);
	unit->schedule(op2);
	UT_ASSERT(!unit->empty());

	// now run it
	unit->drainFrame();
	UT_ASSERT(unit->empty());

	string expect = 
		"unit 'u' before label 'lab1' op OP_INSERT {\n"
		"unit 'u' before-chained label 'lab1' op OP_INSERT {\n"
			"unit 'u' before label 'lab2' (chain 'lab1') op OP_INSERT {\n"
			"unit 'u' before-chained label 'lab2' (chain 'lab1') op OP_INSERT {\n"
				"unit 'u' before label 'lab3' (chain 'lab2') op OP_INSERT {\n"
				"unit 'u' after label 'lab3' (chain 'lab2') op OP_INSERT }\n"
			"unit 'u' after-chained label 'lab2' (chain 'lab1') op OP_INSERT }\n"
			"unit 'u' after label 'lab2' (chain 'lab1') op OP_INSERT }\n"

			"unit 'u' before label 'lab3' (chain 'lab1') op OP_INSERT {\n"
			"unit 'u' after label 'lab3' (chain 'lab1') op OP_INSERT }\n"
		"unit 'u' after-chained label 'lab1' op OP_INSERT }\n"
		"unit 'u' after label 'lab1' op OP_INSERT }\n"

		"unit 'u' before label 'lab1' op OP_DELETE {\n"
		"unit 'u' before-chained label 'lab1' op OP_DELETE {\n"
			"unit 'u' before label 'lab2' (chain 'lab1') op OP_DELETE {\n"
			"unit 'u' before-chained label 'lab2' (chain 'lab1') op OP_DELETE {\n"
				"unit 'u' before label 'lab3' (chain 'lab2') op OP_DELETE {\n"
				"unit 'u' after label 'lab3' (chain 'lab2') op OP_DELETE }\n"
			"unit 'u' after-chained label 'lab2' (chain 'lab1') op OP_DELETE }\n"
			"unit 'u' after label 'lab2' (chain 'lab1') op OP_DELETE }\n"

			"unit 'u' before label 'lab3' (chain 'lab1') op OP_DELETE {\n"
			"unit 'u' after label 'lab3' (chain 'lab1') op OP_DELETE }\n"
		"unit 'u' after-chained label 'lab1' op OP_DELETE }\n"
		"unit 'u' after label 'lab1' op OP_DELETE }\n"
	;

	string tlog = trace->getBuffer()->print();
	if (UT_IS(tlog, expect)) printf("Expected: \"%s\"\n", expect.c_str());

	// now try the same with StringTracer, but since the pointers are unpredictable,
	// just count the records
	Autoref<Unit::Tracer> trace2 = new Unit::StringTracer(true);
	unit->setTracer(trace2);
	unit->schedule(op1);
	unit->schedule(op2);
	unit->drainFrame();
	UT_ASSERT(unit->empty());
	UT_IS(trace2->getBuffer()->size(), 24);
	// uncomment to check visually
	// printf("StringTracer got:\n%s", trace2->getBuffer()->print().c_str());

	// now the StringTracer not verbose
	Autoref<Unit::Tracer> trace3 = new Unit::StringTracer();
	unit->setTracer(trace3);
	unit->schedule(op1);
	unit->schedule(op2);
	unit->drainFrame();
	UT_ASSERT(unit->empty());
	UT_IS(trace3->getBuffer()->size(), 8);
	// uncomment to check visually
	// printf("StringTracer got:\n%s", trace3->getBuffer()->print().c_str());
	
	// now try the same with StringNameTracer with row printer
	Autoref<Unit::Tracer> trace4 = new Unit::StringNameTracer(true, printB);
	unit->setTracer(trace4);
	unit->schedule(op1);
	unit->schedule(op2);
	unit->drainFrame();
	UT_ASSERT(unit->empty());
	UT_IS(trace4->getBuffer()->size(), 24);

	string expect4 = 
		"unit 'u' before label 'lab1' op OP_INSERT b=1234 {\n"
		"unit 'u' before-chained label 'lab1' op OP_INSERT b=1234 {\n"
			"unit 'u' before label 'lab2' (chain 'lab1') op OP_INSERT b=1234 {\n"
			"unit 'u' before-chained label 'lab2' (chain 'lab1') op OP_INSERT b=1234 {\n"
				"unit 'u' before label 'lab3' (chain 'lab2') op OP_INSERT b=1234 {\n"
				"unit 'u' after label 'lab3' (chain 'lab2') op OP_INSERT b=1234 }\n"
			"unit 'u' after-chained label 'lab2' (chain 'lab1') op OP_INSERT b=1234 }\n"
			"unit 'u' after label 'lab2' (chain 'lab1') op OP_INSERT b=1234 }\n"

			"unit 'u' before label 'lab3' (chain 'lab1') op OP_INSERT b=1234 {\n"
			"unit 'u' after label 'lab3' (chain 'lab1') op OP_INSERT b=1234 }\n"
		"unit 'u' after-chained label 'lab1' op OP_INSERT b=1234 }\n"
		"unit 'u' after label 'lab1' op OP_INSERT b=1234 }\n"

		"unit 'u' before label 'lab1' op OP_DELETE b=4321 {\n"
		"unit 'u' before-chained label 'lab1' op OP_DELETE b=4321 {\n"
			"unit 'u' before label 'lab2' (chain 'lab1') op OP_DELETE b=4321 {\n"
			"unit 'u' before-chained label 'lab2' (chain 'lab1') op OP_DELETE b=4321 {\n"
				"unit 'u' before label 'lab3' (chain 'lab2') op OP_DELETE b=4321 {\n"
				"unit 'u' after label 'lab3' (chain 'lab2') op OP_DELETE b=4321 }\n"
			"unit 'u' after-chained label 'lab2' (chain 'lab1') op OP_DELETE b=4321 }\n"
			"unit 'u' after label 'lab2' (chain 'lab1') op OP_DELETE b=4321 }\n"

			"unit 'u' before label 'lab3' (chain 'lab1') op OP_DELETE b=4321 {\n"
			"unit 'u' after label 'lab3' (chain 'lab1') op OP_DELETE b=4321 }\n"
		"unit 'u' after-chained label 'lab1' op OP_DELETE b=4321 }\n"
		"unit 'u' after label 'lab1' op OP_DELETE b=4321 }\n"
	;

	tlog = trace4->getBuffer()->print();
	if (UT_IS(tlog, expect4)) printf("Expected: \"%s\"\n", expect4.c_str());
}

// a class to build circular references between labels, to see how they
// would get resolved
class CircularLabel: public Label
{
public:
	CircularLabel(Unit *unit, Onceref<RowType> rtype, const string &name,
			Onceref<Label> refto) :
		Label(unit, rtype, name),
		refto_(refto)
	{ }

	virtual void execute(Rowop *arg) const
	{ }

	virtual void clearSubclass()
	{
		refto_ = NULL;
		refunit_ = NULL;
	}

	Autoref<Label> refto_;
	Autoref<Unit> refunit_; // to create circular refs to the unit
};

// test that the unit clears the labels when it gets destroyed
UTESTCASE clearing1(Utest *utest)
{
	// make row for setting
	RowType::FieldVec fld;
	mkfields(fld);
	Autoref<RowType> rt1 = new CompactRowType(fld);
	if (UT_ASSERT(rt1->getErrors().isNull())) return;

	Autoref<Unit> unit = new Unit("u");
	Autoref<CircularLabel> lab1 = new CircularLabel(unit, rt1, "lab1", NULL);
	Autoref<CircularLabel> lab2 = new CircularLabel(unit, rt1, "lab2", lab1);
	lab1->refto_ = lab2; // create the circularity

	// when the unit get destoryed, the circularity should get resolved
}

// test that even if Unit is in a circular reference, the UnitClearingTrigger
// comes to the resque
UTESTCASE clearing2(Utest *utest)
{
	// make row for setting
	RowType::FieldVec fld;
	mkfields(fld);
	Autoref<RowType> rt1 = new CompactRowType(fld);
	if (UT_ASSERT(rt1->getErrors().isNull())) return;

	Autoref<Unit> unit = new Unit("u");

	Autoref<CircularLabel> lab1 = new CircularLabel(unit, rt1, "lab1", NULL);
	Autoref<CircularLabel> lab2 = new CircularLabel(unit, rt1, "lab2", lab1);
	lab1->refto_ = lab2; // create the circularity

	// create circularity to the Unit
	lab1->refunit_ = unit;
	lab2->refunit_ = unit;

	// when the UnitClearingTrigger get destoryed, the circularity should get resolved
	{ 
		Autoref<UnitClearingTrigger> cleanTrigger = new UnitClearingTrigger(unit);
	}
	// check that the labels got cleared
	UT_ASSERT(lab1->isCleared());
	UT_IS(lab1->getUnitPtr(), NULL);
	UT_IS(lab1->getUnitName(), "[label cleared]");
}

class TestFrameMark: public FrameMark
{
public:
	TestFrameMark(const string &name) :
		FrameMark(name)
	{ }

	Unit *getUnit() const
	{
		return unit_;
	}

	UnitFrame *getFrame() const
	{
		return frame_;
	}

	FrameMark *getNext() const
	{
		return next_.get();
	}
};

// For marks to be set properly, it must happen with at least one
// frame already on the stack, so do it by calling this label
class LabelTestMarks : public Label
{
public:
	LabelTestMarks(Unit *unit, Onceref<RowType> rtype, const string &name,
			Utest *utest) :
		Label(unit, rtype, name),
		utest_(utest)
	{ }

	virtual void execute(Rowop *rop) const
	{
		Utest *utest = utest_; // variable expected by all macros
		Unit *unit1 = unit_;

		UT_IS(unit1->getStackDepth(), 2);

		Autoref<Unit> unit2 = new Unit("u2");

		Autoref<TestFrameMark> mark1 = new TestFrameMark("m1");
		Autoref<TestFrameMark> mark2 = new TestFrameMark("m2");
		Autoref<TestFrameMark> mark3 = new TestFrameMark("m3");

		UT_IS(mark1->getUnit(), NULL);
		UT_IS(mark1->getFrame(), NULL);
		UT_IS(mark1->getNext(), NULL);

		// set 3 marks on the same frame
		unit1->setMark(mark1);
		UT_IS(mark1->getUnit(), unit1);
		UT_ASSERT(mark1->getFrame() != NULL);
		UT_IS(mark1->getNext(), NULL);

		unit1->setMark(mark2);
		UT_IS(mark2->getUnit(), unit1);
		UT_IS(mark2->getFrame(), mark1->getFrame());
		UT_IS(mark2->getNext(), mark1.get());

		unit1->setMark(mark3);
		UT_IS(mark3->getUnit(), unit1);
		UT_IS(mark3->getFrame(), mark1->getFrame());
		UT_IS(mark3->getNext(), mark2.get());

		// move the marks to a different unit, effectively clearing them
		// because there are no frames pushed on that unit yet
		// (this is not something to do in production but a convenient test)

		// middle mark
		unit2->setMark(mark2);
		UT_IS(mark2->getUnit(), NULL);
		UT_IS(mark2->getFrame(), NULL);
		UT_IS(mark2->getNext(), NULL);

		// end-of-list mark
		unit2->setMark(mark1);
		UT_IS(mark1->getUnit(), NULL);
		UT_IS(mark1->getFrame(), NULL);
		UT_IS(mark1->getNext(), NULL);

		// the only mark left
		unit2->setMark(mark3);
		UT_IS(mark3->getUnit(), NULL);
		UT_IS(mark3->getFrame(), NULL);
		UT_IS(mark3->getNext(), NULL);
	}

	Utest *utest_;
};

UTESTCASE frameMarks(Utest *utest)
{
	Autoref<Unit> unit1 = new Unit("u1");

	// make a row for calling a label
	RowType::FieldVec fld;
	mkfields(fld);

	Autoref<RowType> rt1 = new CompactRowType(fld);
	if (UT_ASSERT(rt1->getErrors().isNull())) return;

	FdataVec dv;
	mkfdata(dv);
	Rowref r1(rt1,  rt1->makeRow(dv)); // the initial row to start the loop
	if (UT_ASSERT(!r1.isNull())) return;

	// build the label
	Autoref<LabelTestMarks> lab = new LabelTestMarks(unit1, rt1, "lab", utest);
	unit1->call(new Rowop(lab, Rowop::OP_NOP, r1)); // and call it
	// the label doe sthe rest
}

class LabelStartLoop : public Label
{
public:
	LabelStartLoop(Unit *unit, Onceref<RowType> rtype, const string &name,
			Label *next, TestFrameMark *mark) :
		Label(unit, rtype, name),
		next_(next),
		mark_(mark)
	{ }

	virtual void execute(Rowop *rop) const
	{
		// fprintf(stderr, "DEBUG LabelStartLoop mark was at %p\n", mark_->getFrame());
		unit_->setMark(mark_);
		int32_t val = type_->getInt32(rop->getRow(), 1, 0);
		// fprintf(stderr, "DEBUG LabelStartLoop mark set to %p val=%d\n", mark_->getFrame(), val);

		if (val >= 3)
			return; // end of loop

		if (val == 0) {
			unit_->fork(new Rowop(next_, Rowop::OP_NOP, rop->getRow()));
			unit_->fork(new Rowop(next_, Rowop::OP_NOP, rop->getRow()));
			unit_->fork(new Rowop(next_, Rowop::OP_NOP, rop->getRow()));
		} else {
			unit_->call(new Rowop(next_, Rowop::OP_INSERT, rop->getRow()));
		}
		// fprintf(stderr, "DEBUG LabelStartLoop mark eventually at %p\n", mark_->getFrame());
	}

	Label *next_;
	TestFrameMark *mark_;
};

class LabelNextLoop : public Label
{
public:
	LabelNextLoop(Unit *unit, Onceref<RowType> rtype, const string &name,
			Label *next, TestFrameMark *mark, bool useTray) :
		Label(unit, rtype, name),
		next_(next),
		mark_(mark),
		useTray_(useTray)
	{ }

	virtual void execute(Rowop *rop) const
	{
		int32_t val = type_->getInt32(rop->getRow(), 1, 0);
		++val;

		FdataVec dv;
		mkfdata(dv);
		dv[1].setPtr(true, &val, sizeof(val));

		Rowref r(type_,  type_->makeRow(dv));

		// fprintf(stderr, "DEBUG LabelNextLoop mark at %p val increased to %d\n", mark_->getFrame(), val);
		if (useTray_) {
			Autoref<Tray> tray = new Tray;
			tray->push_back(new Rowop(next_, Rowop::OP_DELETE, type_->makeRow(dv)));
			unit_->loopTrayAt(mark_, tray);
		} else {
			unit_->loopAt(mark_, new Rowop(next_, Rowop::OP_DELETE, type_->makeRow(dv)));
		}
	}

	Label *next_;
	TestFrameMark *mark_;
	bool useTray_;
};


UTESTCASE markLoop(Utest *utest)
{
	// make a unit 
	Autoref<Unit> unit = new Unit("u");
	Autoref<Unit::Tracer> trace = new Unit::StringNameTracer(false);
	unit->setTracer(trace);

	// make row for setting
	RowType::FieldVec fld;
	mkfields(fld);

	Autoref<RowType> rt1 = new CompactRowType(fld);
	if (UT_ASSERT(rt1->getErrors().isNull())) return;

	FdataVec dv;
	mkfdata(dv);
	int32_t zero = 0;
	dv[1].setPtr(true, &zero, sizeof(zero));
	Rowref r1(rt1,  rt1->makeRow(dv)); // the initial row to start the loop
	if (UT_ASSERT(!r1.isNull())) return;

	Autoref<TestFrameMark> mark1 = new TestFrameMark("mark1");
	UT_IS(mark1->getUnit(), NULL);

	// build the labels
	Autoref<LabelStartLoop> lstart = new LabelStartLoop(unit, rt1, "lstart", NULL, mark1);
	Autoref<LabelNextLoop> lnext = new LabelNextLoop(unit, rt1, "lnext", lstart.get(), mark1, false);
	lstart->next_ = lnext.get();
	Autoref<DummyLabel> ldummy = new DummyLabel(unit, rt1, "ldummy");

	// send a record to unset mark - same as schedule()
	UT_ASSERT(unit->empty());
	unit->schedule(new Rowop(ldummy, Rowop::OP_DELETE, r1)); // to precede the loop
	unit->loopAt(mark1, new Rowop(lstart, Rowop::OP_NOP, r1)); // sends to outermost frame
	unit->schedule(new Rowop(ldummy, Rowop::OP_INSERT, r1)); // to follow after the loop
	UT_ASSERT(!unit->empty());

	// run the loop
	unit->drainFrame();
	UT_ASSERT(unit->empty());

	string tlog;
	tlog = trace->getBuffer()->print();

	string expect_sched = 
		"unit 'u' before label 'ldummy' op OP_DELETE\n"
		"unit 'u' before label 'lstart' op OP_NOP\n"

		// LabelStartLoop executes and for the first iteration
		// forks 3 rowops for lnext.
		"unit 'u' before label 'lnext' op OP_NOP\n"
		"unit 'u' before label 'lnext' op OP_NOP\n"
		"unit 'u' before label 'lnext' op OP_NOP\n"

		// LabelStartLoop moves the mark1 to itself,
		// so the whole loop gets through before the lstart frame
		// completes and returns.
		// These go in this order because of the EM_CALL on lnext.
		"unit 'u' before label 'lstart' op OP_DELETE\n"
		"unit 'u' before label 'lnext' op OP_INSERT\n"
		"unit 'u' before label 'lstart' op OP_DELETE\n"
		"unit 'u' before label 'lnext' op OP_INSERT\n"
		"unit 'u' before label 'lstart' op OP_DELETE\n"
		"unit 'u' before label 'lnext' op OP_INSERT\n"

		"unit 'u' before label 'lstart' op OP_DELETE\n"
		"unit 'u' before label 'lnext' op OP_INSERT\n"
		"unit 'u' before label 'lstart' op OP_DELETE\n"
		"unit 'u' before label 'lnext' op OP_INSERT\n"
		"unit 'u' before label 'lstart' op OP_DELETE\n"
		"unit 'u' before label 'lnext' op OP_INSERT\n"

		"unit 'u' before label 'lstart' op OP_DELETE\n"
		"unit 'u' before label 'lstart' op OP_DELETE\n"
		"unit 'u' before label 'lstart' op OP_DELETE\n"

		// Finally the next item from the outermost frame executes.
		"unit 'u' before label 'ldummy' op OP_INSERT\n"
	;

	UT_IS(tlog, expect_sched);

	// change mode to use tray and repeat
	lnext->useTray_ = true;
	trace->clearBuffer();
	
	// send a record to unset mark - same as schedule()
	UT_ASSERT(unit->empty());
	unit->schedule(new Rowop(ldummy, Rowop::OP_DELETE, r1)); // to precede the loop
	unit->loopAt(mark1, new Rowop(lstart, Rowop::OP_NOP, r1));
	unit->schedule(new Rowop(ldummy, Rowop::OP_INSERT, r1)); // to follow after the loop
	UT_ASSERT(!unit->empty());

	// run the loop
	unit->drainFrame();
	UT_ASSERT(unit->empty());

	tlog = trace->getBuffer()->print();

	UT_IS(tlog, expect_sched);
}

class LabelLoopWrongUnit : public Label
{
public:
	LabelLoopWrongUnit(Unit *unit, Onceref<RowType> rtype, const string &name,
			Unit *unit2, Onceref<Rowop> op2) :
		Label(unit, rtype, name),
		unit2_(unit2),
		op2_(op2)
	{ }

	virtual void execute(Rowop *arg) const
	{
		Autoref<TestFrameMark> mark1 = new TestFrameMark("m1");
		unit_->setMark(mark1);
		if (arg->isDelete()) {
			Autoref<Tray> tray = new Tray;
			tray->push_back(op2_);
			unit2_->loopTrayAt(mark1, tray);
		} else {
			unit2_->loopAt(mark1, op2_);
		}
	}

	Unit *unit2_;
	Autoref<Rowop> op2_;
};

class LabelThrowOnClear : public Label
{
public:
	LabelThrowOnClear(Unit *unit, Onceref<RowType> rtype, const string &name) :
		Label(unit, rtype, name)
	{ }

	virtual void execute(Rowop *arg) const
	{ }

	virtual void clearSubclass()
	{ 
		throw Exception("Test report of the exception on clear", true);
	}
};

class LabelThrowOnCall : public Label
{
public:
	LabelThrowOnCall(Unit *unit, Onceref<RowType> rtype, const string &name) :
		Label(unit, rtype, name)
	{ }

	virtual void execute(Rowop *arg) const
	{
		throw Exception("Test throw on call", true);
	}
};

class LabelRecursive : public Label
{
public:
	LabelRecursive(Unit *unit, Onceref<RowType> rtype, const string &name) :
		Label(unit, rtype, name)
	{ }

	virtual void execute(Rowop *arg) const
	{
		unit_->call(arg); // a recursive call attempt
	}
};

UTESTCASE exceptions(Utest *utest)
{
	string msg;

	Exception::abort_ = false; // make them catchable
	Exception::enableBacktrace_ = false; // make the error messages predictable

	// make row for setting
	RowType::FieldVec fld;
	mkfields(fld);
	Autoref<RowType> rt1 = new CompactRowType(fld);
	if (UT_ASSERT(rt1->getErrors().isNull())) return;

	Autoref<Unit> unit1 = new Unit("u1");
	Autoref<Unit> unit2 = new Unit("u2");

	Autoref<Label> lab1 = new DummyLabel(unit1, rt1, "lab1");

	FdataVec dv;
	mkfdata(dv);
	Rowref r1(rt1,  rt1->makeRow(dv)); // the initial row to start the loop
	Autoref<Rowop> op1 = new Rowop(lab1, Rowop::OP_INSERT, r1);

	msg.clear();
	try {
		unit1->enqueue(999, op1);
	} catch (Exception e) {
		msg = e.getErrors()->print();
	}
	UT_IS(msg, "Triceps API violation: Invalid enqueueing mode 999\n");

	msg.clear();
	try {
		Autoref<Tray> tray = new Tray;
		tray->push_back(op1);
		unit1->enqueueTray(999, tray);
	} catch (Exception e) {
		msg = e.getErrors()->print();
	}
	UT_IS(msg, "Triceps API violation: Invalid enqueueing mode 999\n");

	// this tests loopAt() and the tracing of the label stack
	msg.clear();
	try {
		Autoref<Label> labwu = new LabelLoopWrongUnit(unit2, rt1, "labwu", unit1.get(), op1);
		Autoref<Rowop> opwu = new Rowop(labwu, Rowop::OP_INSERT, r1);
		unit2->schedule(opwu);
		unit2->drainFrame();
	} catch (Exception e) {
		msg = e.getErrors()->print();
	}
	UT_IS(msg, "Triceps API violation: loopAt() attempt on unit 'u1' with mark 'm1' from unit 'u2'\nCalled through the label 'labwu'.\n");
	UT_ASSERT(unit2->empty()); // the frame must get popped

	// this tests loopAt() and the tracing of the label stack
	msg.clear();
	try {
		Autoref<Label> labwu = new LabelLoopWrongUnit(unit2, rt1, "labwu", unit1.get(), op1);
		Autoref<Rowop> opwu = new Rowop(labwu, Rowop::OP_DELETE, r1);
		unit2->call(opwu);
	} catch (Exception e) {
		msg = e.getErrors()->print();
	}
	UT_IS(msg, "Triceps API violation: loopTrayAt() attempt on unit 'u1' with mark 'm1' from unit 'u2'\nCalled through the label 'labwu'.\n");
	UT_ASSERT(unit2->empty()); // the frame must get popped, there was only one rowop

	// test that the label clearing catches and consumes the exception
	try {
		Autoref<Label> labclr = new LabelThrowOnClear(unit2, rt1, "labclr");
		unit2->clearLabels();
	} catch (Exception e) {
		UT_ASSERT(false);
	}

	// test of callTray and also of drainFrame() being interrupted
	msg.clear();
	try {
		Autoref<Label> labt = new LabelThrowOnCall(unit1, rt1, "labt");
		Autoref<Tray> tray = new Tray;
		Autoref<Rowop> opt = new Rowop(labt, Rowop::OP_INSERT, r1);
		tray->push_back(opt);
		tray->push_back(opt);

		unit1->callTray(tray);
	} catch (Exception e) {
		msg = e.getErrors()->print();
	}
	UT_IS(msg, "Test throw on call\nCalled through the label 'labt'.\n");
	UT_ASSERT(unit1->empty()); // the frame must get popped

	// draining of the frame, even if the exception is thrown in a recursive call;
	// and also the max stack depth limit 
	// (the max recusrion depth limit is tested with the labels)
	unit1->setMaxStackDepth(3);
	unit1->setMaxRecursionDepth(10);
	msg.clear();
	try {
		Autoref<Label> labrec = new LabelRecursive(unit1, rt1, "labrec");
		Autoref<Rowop> oprec = new Rowop(labrec, Rowop::OP_DELETE, r1);
		unit1->schedule(oprec);
		unit1->schedule(oprec);
		unit1->schedule(oprec);

		unit1->drainFrame();
	} catch (Exception e) {
		msg = e.getErrors()->print();
	}
	unit1->setMaxStackDepth(0);
	unit1->setMaxRecursionDepth(1);
	UT_IS(msg, 
		"Unit 'u1' exceeded the stack depth limit 3, current depth 4, when calling the label 'labrec'.\n"
		"Called through the label 'labrec'.\n"
		"Called through the label 'labrec'.\n");

	UT_ASSERT(unit1->empty());

	Exception::abort_ = true; // restore back
	Exception::enableBacktrace_ = true; // restore back
}

class ThrowingTracer : public Unit::Tracer
{
public:
	ThrowingTracer(Unit::TracerWhen when) :
		when_(when)
	{ }

	virtual void execute(Unit *unit, const Label *label, const Label *fromLabel, Rowop *rop, Unit::TracerWhen when)
	{
		// printf("trace %s label '%s' %c\n", Unit::tracerWhenHumanString(when), label->getName().c_str(), Unit::tracerWhenIsBefore(when)? '{' : '}');
		if (when == when_)
			throw Exception("exception in tracer", true);
	}

	Unit::TracerWhen when_;
};

class ForkingLabel : public Label
{
public:
	ForkingLabel(Unit *unit, Onceref<RowType> rtype, const string &name,
			Onceref<Label> next) :
		Label(unit, rtype, name),
		next_(next)
	{ }

	virtual void execute(Rowop *arg) const
	{
		// printf("forking\n");
		unit_->fork(next_->adopt(arg));
	}

	Autoref<Label> next_;
};

// test the exception propagation through the labels
UTESTCASE label_exceptions(Utest *utest)
{
	string msg;

	Exception::abort_ = false; // make them catchable
	Exception::enableBacktrace_ = false; // make the error messages predictable

	// make row for setting
	RowType::FieldVec fld;
	mkfields(fld);
	Autoref<RowType> rt1 = new CompactRowType(fld);
	if (UT_ASSERT(rt1->getErrors().isNull())) return;

	Autoref<Unit> unit1 = new Unit("u1");
	Autoref<Unit> unit2 = new Unit("u2");

	FdataVec dv;
	mkfdata(dv);
	Rowref r1(rt1,  rt1->makeRow(dv)); // the initial row to start the loop

	// recursive call and chaining and propagation through call
	msg.clear();
	try {
		Autoref<Label> labrec = new LabelRecursive(unit1, rt1, "labrec");
		Autoref<Label> lab1 = new DummyLabel(unit1, rt1, "lab1");
		Autoref<Label> lab2 = new DummyLabel(unit1, rt1, "lab2");

		lab1->chain(lab2);
		lab2->chain(labrec);

		Autoref<Rowop> oprec = new Rowop(lab1, Rowop::OP_DELETE, r1);
		unit1->call(oprec);
	} catch (Exception e) {
		msg = e.getErrors()->print();
	}
	UT_IS(msg, "Exceeded the unit recursion depth limit 1 (attempted 2) on the label 'lab1'.\n\
Called through the label 'labrec'.\n\
Called chained from the label 'lab2'.\n\
Called chained from the label 'lab1'.\n");

	// recursive call of a non-reentrant label
	unit1->setMaxRecursionDepth(3);
	msg.clear();
	try {
		Autoref<Label> labrec = new LabelRecursive(unit1, rt1, "labrec");
		UT_ASSERT(!labrec->isNonReentrant());
		labrec->setNonReentrant();
		UT_ASSERT(labrec->isNonReentrant());

		Autoref<Rowop> oprec = new Rowop(labrec, Rowop::OP_DELETE, r1);
		unit1->call(oprec);
	} catch (Exception e) {
		msg = e.getErrors()->print();
	}
	unit1->setMaxRecursionDepth(1);
	UT_IS(msg, "Detected a recursive call of the non-reentrant label 'labrec'.\n\
Called through the label 'labrec'.\n");

	// wrong unit
	msg.clear();
	try {
		Autoref<Label> labwu = new DummyLabel(unit2, rt1, "labwu");
		Autoref<Rowop> opwu = new Rowop(labwu, Rowop::OP_DELETE, r1);
		unit1->call(opwu);
	} catch (Exception e) {
		msg = e.getErrors()->print();
	}
	UT_IS(msg, "Triceps API violation: call() attempt with unit 'u1' of label 'labwu' belonging to unit 'u2'.\n");

	// all kinds of tracing errors
	
	// tracer throws on BEFORE
	msg.clear();
	try {
		Autoref<Unit::Tracer> tracer1 = new ThrowingTracer(Unit::TW_BEFORE);
		unit1->setTracer(tracer1);

		Autoref<Label> lab1 = new DummyLabel(unit1, rt1, "lab1");
		Autoref<Label> lab2 = new DummyLabel(unit1, rt1, "lab2");

		lab1->chain(lab2);

		Autoref<Rowop> oprec = new Rowop(lab1, Rowop::OP_DELETE, r1);
		unit1->call(oprec);
	} catch (Exception e) {
		msg = e.getErrors()->print();
	}
	UT_IS(msg, "Error when tracing before the label 'lab1':\n  exception in tracer\n");

	// tracer throws on AFTER;
	// also propagation of the exception through chaining
	msg.clear();
	try {
		Autoref<Unit::Tracer> tracer1 = new ThrowingTracer(Unit::TW_AFTER);
		unit1->setTracer(tracer1);

		Autoref<Label> lab1 = new DummyLabel(unit1, rt1, "lab1");
		Autoref<Label> lab2 = new DummyLabel(unit1, rt1, "lab2");

		lab1->chain(lab2);

		Autoref<Rowop> oprec = new Rowop(lab1, Rowop::OP_DELETE, r1);
		unit1->call(oprec);
	} catch (Exception e) {
		msg = e.getErrors()->print();
	}
	UT_IS(msg, "Error when tracing after execution of the label 'lab2':\n  exception in tracer\nCalled chained from the label 'lab1'.\n");

	// tracer throws on BEFORE_CHAINED
	msg.clear();
	try {
		Autoref<Unit::Tracer> tracer1 = new ThrowingTracer(Unit::TW_BEFORE_CHAINED);
		unit1->setTracer(tracer1);

		Autoref<Label> lab1 = new DummyLabel(unit1, rt1, "lab1");
		Autoref<Label> lab2 = new DummyLabel(unit1, rt1, "lab2");

		lab1->chain(lab2);

		Autoref<Rowop> oprec = new Rowop(lab1, Rowop::OP_DELETE, r1);
		unit1->call(oprec);
	} catch (Exception e) {
		msg = e.getErrors()->print();
	}
	UT_IS(msg, "Error when tracing before the chain of the label 'lab1':\n  exception in tracer\n");

	// tracer throws on AFTER_CHAINED
	msg.clear();
	try {
		Autoref<Unit::Tracer> tracer1 = new ThrowingTracer(Unit::TW_AFTER_CHAINED);
		unit1->setTracer(tracer1);

		Autoref<Label> lab1 = new DummyLabel(unit1, rt1, "lab1");
		Autoref<Label> lab2 = new DummyLabel(unit1, rt1, "lab2");

		lab1->chain(lab2);

		Autoref<Rowop> oprec = new Rowop(lab1, Rowop::OP_DELETE, r1);
		unit1->call(oprec);
	} catch (Exception e) {
		msg = e.getErrors()->print();
	}
	UT_IS(msg, "Error when tracing after the chain of the label 'lab1':\n  exception in tracer\n");

	// tracer throws on BEFORE_DRAIN
	msg.clear();
	try {
		Autoref<Unit::Tracer> tracer1 = new ThrowingTracer(Unit::TW_BEFORE_DRAIN);
		unit1->setTracer(tracer1);

		Autoref<Label> lab2 = new DummyLabel(unit1, rt1, "lab2");
		Autoref<Label> lab1 = new ForkingLabel(unit1, rt1, "lab1", lab2);

		Autoref<Rowop> oprec = new Rowop(lab1, Rowop::OP_DELETE, r1);
		unit1->call(oprec);
	} catch (Exception e) {
		msg = e.getErrors()->print();
	}
	UT_IS(msg, "Error when tracing before draining the label 'lab1':\n  exception in tracer\n");

	// tracer throws on AFTER_DRAIN
	msg.clear();
	try {
		Autoref<Unit::Tracer> tracer1 = new ThrowingTracer(Unit::TW_AFTER_DRAIN);
		unit1->setTracer(tracer1);

		Autoref<Label> lab2 = new DummyLabel(unit1, rt1, "lab2");
		Autoref<Label> lab1 = new ForkingLabel(unit1, rt1, "lab1", lab2);

		Autoref<Rowop> oprec = new Rowop(lab1, Rowop::OP_DELETE, r1);
		unit1->call(oprec);
	} catch (Exception e) {
		msg = e.getErrors()->print();
	}
	UT_IS(msg, "Error when tracing after draining the label 'lab1':\n  exception in tracer\n");

	Exception::abort_ = true; // restore back
	Exception::enableBacktrace_ = true; // restore back
}
