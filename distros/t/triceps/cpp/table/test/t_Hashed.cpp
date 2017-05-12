//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Test of table creation with a primary index.

#include <utest/Utest.h>
#include <string.h>

#include <type/AllTypes.h>
#include <common/StringUtil.h>
#include <table/Table.h>
#include <mem/Rhref.h>

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

UTESTCASE primaryIndex(Utest *utest)
{
	RowType::FieldVec fld;
	mkfields(fld);

	Autoref<Unit> unit = new Unit("u");
	Autoref<RowType> rt1 = new CompactRowType(fld);
	UT_ASSERT(rt1->getErrors().isNull());

	Autoref<TableType> tt = (new TableType(rt1))
		->addSubIndex("primary", new HashedIndexType(
			(new NameSet())->add("a")->add("e"))
		);

	UT_ASSERT(tt);
	tt->initialize();
	UT_ASSERT(tt->getErrors().isNull());
	UT_ASSERT(!tt->getErrors()->hasError());

	Autoref<Table> t = tt->makeTable(unit, "t");
	UT_ASSERT(!t.isNull());
	UT_ASSERT(t->getInputLabel() != NULL);
	UT_ASSERT(t->getLabel() != NULL);
	UT_IS(t->getInputLabel()->getName(), "t.in");
	UT_IS(t->getLabel()->getName(), "t.out");
}

UTESTCASE uninitialized(Utest *utest)
{
	RowType::FieldVec fld;
	mkfields(fld);

	Autoref<Unit> unit = new Unit("u");
	Autoref<RowType> rt1 = new CompactRowType(fld);
	UT_ASSERT(rt1->getErrors().isNull());

	Autoref<TableType> tt = (new TableType(rt1))
		->addSubIndex("primary", new HashedIndexType(
			(new NameSet())->add("a")->add("e"))
		);

	UT_ASSERT(tt);

	Autoref<Table> t = tt->makeTable(unit, "t");
	UT_ASSERT(t.isNull());
}

UTESTCASE withError(Utest *utest)
{
	RowType::FieldVec fld;
	mkfields(fld);

	Autoref<Unit> unit = new Unit("u");
	Autoref<RowType> rt1 = new CompactRowType(fld);
	UT_ASSERT(rt1->getErrors().isNull());

	Autoref<TableType> tt = (new TableType(rt1))
		->addSubIndex("primary", new HashedIndexType(
			(new NameSet())->add("x")->add("e"))
		);

	UT_ASSERT(tt);
	tt->initialize();
	UT_ASSERT(!tt->getErrors().isNull());
	UT_ASSERT(tt->getErrors()->hasError());

	Autoref<Table> t = tt->makeTable(unit, "t");
	UT_ASSERT(t.isNull());
}

UTESTCASE tableops(Utest *utest)
{
	RowType::FieldVec fld;
	mkfields(fld);

	Autoref<Unit> unit = new Unit("u");
	Autoref<RowType> rt1 = new CompactRowType(fld);
	UT_ASSERT(rt1->getErrors().isNull());

	Autoref<TableType> tt = (new TableType(rt1))
		->addSubIndex("primary", new HashedIndexType(
			(new NameSet())->add("a")->add("e"))
		);

	UT_ASSERT(tt);
	tt->initialize();
	UT_ASSERT(tt->getErrors().isNull());
	UT_ASSERT(!tt->getErrors()->hasError());

	Autoref<Table> t = tt->makeTable(unit, "t");
	UT_ASSERT(!t.isNull());

	IndexType *prim = tt->findSubIndex("primary");
	UT_ASSERT(prim != NULL);

	// other instance, for checking of errors
	Autoref<Table> t2 = tt->makeTable(unit, "t2");
	UT_ASSERT(!t2.isNull());
	IndexType *prim2 = tt->findSubIndex("primary");
	UT_ASSERT(prim2 != NULL);

	// 3rd instance, with its own type, for checking of errors
	Autoref<TableType> tt3 = (new TableType(rt1))
		->addSubIndex("primary", new HashedIndexType(
			(new NameSet())->add("a")->add("e"))
		);
	UT_ASSERT(tt3);
	tt3->initialize();
	Autoref<Table> t3 = tt3->makeTable(unit, "t3");
	UT_ASSERT(!t3.isNull());
	IndexType *prim3 = tt3->findSubIndex("primary");
	UT_ASSERT(prim3 != NULL);

	// above here was a copy of primaryIndex()

	RowHandle *iter;
	FdataVec dv;
	mkfdata(dv);
	Rowref r1(rt1,  rt1->makeRow(dv));
	Rhref rh1(t, t->makeRowHandle(r1));

	// so far the table must be empty
	iter = t->begin();
	UT_IS(iter, NULL);

	// basic insertion
	UT_ASSERT(t->insert(rh1));
	iter = t->begin();
	UT_IS(iter, rh1);
	iter = t->next(iter);
	UT_IS(iter, NULL);

	// this should replace the row with an identical one but with auto-created handle
	UT_ASSERT(t->insertRow(r1));
	iter = t->begin();
	RowHandle *iter2 = iter;
	UT_ASSERT(iter != NULL);
	UT_ASSERT(iter != rh1);
	iter = t->next(iter);
	UT_IS(iter, NULL);

	// check that the newly inserted record can be found by find on the same key
	iter = t->findIdx(prim, rh1);
	UT_ASSERT(iter == iter2);
	iter = t->findRowIdx(prim, r1);
	UT_ASSERT(iter == iter2);

	// check that the type is shared between tables
	iter = t->findIdx(prim2, rh1);
	UT_ASSERT(iter == iter2);

	// check that the finding by other table type's index returns NULL
	iter = t->findIdx(prim3, rh1);
	UT_ASSERT(iter == NULL);

	// check that iteration with NULL doesn't crash
	UT_ASSERT(t->next(NULL) == NULL);

	// add 2nd record
	const char *key2 = "key2";
	dv[4].setPtr(true, key2, sizeof(key2));
	Rowref r2(rt1, rt1->makeRow(dv));

	UT_ASSERT(t->insertRow(r2));

	// check that now have 2 records
	iter = t->begin();
	UT_ASSERT(iter != NULL);
	iter = t->next(iter);
	UT_ASSERT(iter != NULL);
	iter = t->next(iter);
	UT_ASSERT(iter == NULL);

	// add 3rd record
	const char *key3 = "key3";
	dv[4].setPtr(true, key3, sizeof(key3));
	Rowref r3(rt1, rt1->makeRow(dv));

	UT_ASSERT(t->insertRow(r3));

	// check that now have 3 records
	iter = t->begin();
	UT_ASSERT(iter != NULL);
	iter = t->next(iter);
	UT_ASSERT(iter != NULL);
	iter = t->next(iter);
	UT_ASSERT(iter != NULL);
	iter = t->next(iter);
	UT_ASSERT(iter == NULL);

	// find and remove the 1st record
	iter = t->findIdx(prim, rh1);
	UT_ASSERT(iter != NULL);
	t->remove(iter);

	// check that the record is not there any more
	iter = t->findIdx(prim, rh1);
	UT_ASSERT(iter == NULL);

	// check that now have 2 records
	iter = t->begin();
	UT_ASSERT(iter != NULL);
	iter = t->next(iter);
	UT_ASSERT(iter != NULL);
	iter = t->next(iter);
	UT_ASSERT(iter == NULL);

	// test deleteRow()
	UT_ASSERT(t->deleteRow(r3));
	UT_ASSERT(!t->deleteRow(r3)); // already removed, not found any more
}

// queuing is tested in t_HashedNested
