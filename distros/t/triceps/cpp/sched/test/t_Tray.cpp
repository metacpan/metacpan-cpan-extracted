//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Test of Tray building.

#include <utest/Utest.h>
#include <string.h>

#include <type/CompactRowType.h>
#include <common/StringUtil.h>
#include <common/Exception.h>
#include <sched/Unit.h>

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

UTESTCASE tray(Utest *utest)
{
	// make row types for labels
	RowType::FieldVec fld;
	mkfields(fld);

	Autoref<RowType> rt1 = new CompactRowType(fld);
	if (UT_ASSERT(rt1->getErrors().isNull())) return;
	
	// make a unit 
	Autoref<Unit> unit = new Unit("u");
	Autoref<Label> lab1 = new DummyLabel(unit, rt1, "lab1");

	FdataVec dv;
	mkfdata(dv);
	Rowref r1(rt1,  rt1->makeRow(dv));
	Autoref<Rowop> op1 = new Rowop(lab1, Rowop::OP_NOP, r1);
	Autoref<Rowop> op2 = new Rowop(lab1, Rowop::OP_NOP, r1);

	Autoref<Tray> t1 = new Tray;
	t1->push_back(op1);
	t1->push_back(op1);
	t1->push_back(op1);

	Autoref<Tray> t2 = new Tray;
	t2->push_back(op2);
	t2->push_back(op2);

	UT_IS(t1->getref(), 1);
	UT_IS(t2->getref(), 1);

	Autoref<Tray> t3 = new Tray(*t1);
	UT_IS(t1->getref(), 1);
	UT_IS(t3->getref(), 1);
	UT_IS(t3->size(), 3);

	*t1 = *t2;
	UT_IS(t1->getref(), 1);
	UT_IS(t2->getref(), 1);
	UT_IS(t1->size(), 2);
	UT_IS(t1->at(0).get(), op2.get());
}
