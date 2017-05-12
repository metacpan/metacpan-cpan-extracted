//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Test of the Xtray.

#include <assert.h>
#include <utest/Utest.h>
#include <type/AllTypes.h>
#include <app/Xtray.h>
#include "AppTest.h"

UTESTCASE xtray(Utest *utest)
{
	// prepare fragments
	RowType::FieldVec fld;
	mkfields(fld);
	Autoref<RowType> rt1 = new CompactRowType(fld);

	FdataVec dv;
	mkfdata(dv);
	Rowref r1(rt1,  rt1->makeRow(dv));

	Autoref<RowSetType> rst1 = RowSetType::make()
		->addRow("one", rt1)
		->addRow("two", rt1)
	;

	// construct
	Autoref<Xtray> xt1 = new Xtray(rst1);
	UT_ASSERT(xt1->empty());
	UT_IS(xt1->size(), 0);

	// insert
	UT_IS(r1->getref(), 1);
	xt1->push_back(0, r1, Rowop::OP_INSERT);
	UT_IS(r1->getref(), 2);
	UT_ASSERT(!xt1->empty());
	UT_IS(xt1->size(), 1);

	Xtray::Op op2(1, r1, Rowop::OP_DELETE);
	xt1->push_back(op2);
	UT_IS(r1->getref(), 3);
	UT_ASSERT(!xt1->empty());
	UT_IS(xt1->size(), 2);

	// read
	const Xtray::Op &back1 = xt1->at(0);
	UT_IS(back1.idx_, 0);
	UT_IS(back1.row_, r1.get());
	UT_IS(back1.opcode_, Rowop::OP_INSERT);

	const Xtray::Op &back2 = xt1->at(1);
	UT_IS(back2.idx_, 1);
	UT_IS(back2.row_, r1.get());
	UT_IS(back2.opcode_, Rowop::OP_DELETE);

	// delete
	xt1 = NULL;
	UT_IS(r1->getref(), 1);
}

