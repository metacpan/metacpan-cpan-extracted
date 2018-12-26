//
// (C) Copyright 2011-2018 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Test of the ordered index.

#include <utest/Utest.h>
#include <string.h>

#include <type/AllTypes.h>
#include <sched/AggregatorGadget.h>
#include <common/StringUtil.h>
#include <common/Exception.h>
#include <common/Value.h>
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

// All fields are scalars
void mkfieldsScalar(RowType::FieldVec &fields)
{
	fields.clear();
	fields.push_back(RowType::Field("a", Type::r_uint8));
	fields.push_back(RowType::Field("b", Type::r_int32));
	fields.push_back(RowType::Field("c", Type::r_int64));
	fields.push_back(RowType::Field("d", Type::r_float64));
	fields.push_back(RowType::Field("e", Type::r_string));
}

// All fields are arrays
void mkfieldsArray(RowType::FieldVec &fields)
{
	fields.clear();
	fields.push_back(RowType::Field("a", Type::r_uint8, 0));
	fields.push_back(RowType::Field("b", Type::r_int32, 0));
	fields.push_back(RowType::Field("c", Type::r_int64, 0));
	fields.push_back(RowType::Field("d", Type::r_float64, 0));
}

uint8_t v_uint8[10] = "123456789";
int32_t v_int32[2] = { 1234, 2345 };
int64_t v_int64[2] = { 0xdeadbeefc00c, 0xf00f };
double v_float64[2] = { 9.99e99, 1.11e11 };
char v_string[] = "hello world";

void mkfdata(FdataVec &fd)
{
	fd.resize(4);
	fd[0].setPtr(true, &v_uint8, sizeof(v_uint8));
	fd[1].setPtr(true, &v_int32, sizeof(v_int32[0]));
	fd[2].setPtr(true, &v_int64, sizeof(v_int64[0]));
	fd[3].setPtr(true, &v_float64, sizeof(v_float64[0]));
	// test the constructor
	fd.push_back(Fdata(true, &v_string, sizeof(v_string)));
}

void mkfdataScalar(FdataVec &fd)
{
	fd.resize(4);
	fd[0].setPtr(true, &v_uint8, sizeof(v_uint8[0]));
	fd[1].setPtr(true, &v_int32, sizeof(v_int32[0]));
	fd[2].setPtr(true, &v_int64, sizeof(v_int64[0]));
	fd[3].setPtr(true, &v_float64, sizeof(v_float64[0]));
	// test the constructor
	fd.push_back(Fdata(true, &v_string, sizeof(v_string)));
}

void mkfdataArray(FdataVec &fd)
{
	fd.resize(4);
	fd[0].setPtr(true, &v_uint8, sizeof(v_uint8));
	fd[1].setPtr(true, &v_int32, sizeof(v_int32));
	fd[2].setPtr(true, &v_int64, sizeof(v_int64));
	fd[3].setPtr(true, &v_float64, sizeof(v_float64));
}

// The basic tests are similar to those in t_TableType for the other index types.
// Also see the copy tests in t_TableType.

UTESTCASE orderedIndex(Utest *utest)
{
	RowType::FieldVec fld;
	mkfields(fld);

	Autoref<RowType> rt1 = new CompactRowType(fld);
	UT_ASSERT(rt1->getErrors().isNull());

	Autoref<TableType> tt = (new TableType(rt1))
		->addSubIndex("primary", new OrderedIndexType(
			(new NameSet())->add("a")->add("!e"))
		);

	UT_ASSERT(tt);
	tt->initialize();
	UT_ASSERT(tt->getErrors().isNull());
	UT_ASSERT(!tt->getErrors().hasError());

	// repeated initialization should be fine
	tt->initialize();
	UT_ASSERT(tt->getErrors().isNull());
	UT_ASSERT(!tt->getErrors().hasError());

	const char *expect =
		"table (\n"
		"  row {\n"
		"    uint8[10] a,\n"
		"    int32[] b,\n"
		"    int64 c,\n"
		"    float64 d,\n"
		"    string e,\n"
		"  }\n"
		") {\n"
		"  index OrderedIndex(a, !e, ) primary,\n"
		"}"
	;
	if (UT_ASSERT(tt->print() == expect)) {
		printf("---Expected:---\n%s\n", expect);
		printf("---Received:---\n%s\n", tt->print().c_str());
		printf("---\n");
		fflush(stdout);
	}
	UT_IS(tt->print(NOINDENT), "table ( row { uint8[10] a, int32[] b, int64 c, float64 d, string e, } ) { index OrderedIndex(a, !e, ) primary, }");

	// get back the initialized types
	IndexType *prim = tt->findSubIndex("primary");
	UT_ASSERT(prim != NO_INDEX_TYPE);
	UT_IS(tt->findSubIndexById(IndexType::IT_ORDERED), prim);
	UT_IS(tt->getFirstLeaf(), prim);

	{
		Autoref<NameSet> expectKey = (new NameSet())->add("a")->add("e");
		const NameSet *key = prim->getKey();
		UT_ASSERT(key != NULL);
		UT_ASSERT(key->equals(expectKey));
	}
	{
		Autoref<NameSet> expectKey = (new NameSet())->add("a")->add("!e");
		const NameSet *key = prim->getKeyExpr();
		UT_ASSERT(key != NULL);
		UT_ASSERT(key->equals(expectKey));
	}

	UT_IS(tt->findSubIndexById(IndexType::IT_LAST), NO_INDEX_TYPE);
	UT_IS(tt->findSubIndex("nosuch"), NO_INDEX_TYPE);

	UT_IS(prim->findSubIndex("nosuch"), NO_INDEX_TYPE);
	UT_IS(prim->findSubIndex("nosuch")->findSubIndex("nothat"), NO_INDEX_TYPE);
	UT_IS(prim->findSubIndexById(IndexType::IT_LAST), NO_INDEX_TYPE);
	UT_IS(prim->findSubIndex("nosuch")->findSubIndexById(IndexType::IT_LAST), NO_INDEX_TYPE);
}

UTESTCASE orderedNested(Utest *utest)
{
	RowType::FieldVec fld;
	mkfields(fld);

	Autoref<RowType> rt1 = new CompactRowType(fld);
	UT_ASSERT(rt1->getErrors().isNull());

	Autoref<TableType> tt = initializeOrThrow(TableType::make(rt1)
		->addSubIndex("primary", (new OrderedIndexType(
			(new NameSet())->add("a")->add("!e")))
			->addSubIndex("level2", new OrderedIndexType(
				(new NameSet())->add("!a")->add("e"))
			)
		)
	);

	UT_ASSERT(tt);
	if (UT_ASSERT(tt->getErrors().isNull()))
		return;
	
	const char *expect =
		"table (\n"
		"  row {\n"
		"    uint8[10] a,\n"
		"    int32[] b,\n"
		"    int64 c,\n"
		"    float64 d,\n"
		"    string e,\n"
		"  }\n"
		") {\n"
		"  index OrderedIndex(a, !e, ) {\n"
		"    index OrderedIndex(!a, e, ) level2,\n"
		"  } primary,\n"
		"}"
	;
	if (UT_ASSERT(tt->print() == expect)) {
		printf("---Expected:---\n%s\n", expect);
		printf("---Received:---\n%s\n", tt->print().c_str());
		printf("---\n");
		fflush(stdout);
	}
	UT_IS(tt->print(NOINDENT), "table ( row { uint8[10] a, int32[] b, int64 c, float64 d, string e, } ) { index OrderedIndex(a, !e, ) { index OrderedIndex(!a, e, ) level2, } primary, }");

	// get back the initialized types
	IndexType *prim = tt->findSubIndex("primary");
	if (UT_ASSERT(prim != NO_INDEX_TYPE))
		return;
	UT_IS(tt->findSubIndexById(IndexType::IT_ORDERED), prim);

	IndexType *sec = prim->findSubIndex("level2");
	if (UT_ASSERT(sec != NO_INDEX_TYPE))
		return;
	UT_IS(prim->getTabtype(), tt);
	UT_IS(prim->findSubIndexById(IndexType::IT_ORDERED), sec);

	UT_IS(sec->findSubIndex("nosuch"), NO_INDEX_TYPE);
	UT_IS(sec->findSubIndexById(IndexType::IT_LAST), NO_INDEX_TYPE);
}

UTESTCASE orderedBadField(Utest *utest)
{
	RowType::FieldVec fld;
	mkfields(fld);

	Autoref<RowType> rt1 = new CompactRowType(fld);
	UT_ASSERT(rt1->getErrors().isNull());

	Autoref<TableType> tt = (new TableType(rt1))
		->addSubIndex("primary", new OrderedIndexType(
			(new NameSet())->add("!x")->add("e"))
		)
		;

	UT_ASSERT(tt);
	tt->initialize();
	if (UT_ASSERT(!tt->getErrors().isNull()))
		return;
	UT_ASSERT(tt->getErrors().hasError());
	UT_IS(tt->getErrors()->print(), "index error:\n  nested index 1 'primary':\n    can not find the key field 'x'\n");
}

// The tests similar to t_xSortedIndex

// indexing by all kinds of scalar values
UTESTCASE orderedIndexScalar(Utest *utest)
{
	RowType::FieldVec fld;
	mkfieldsScalar(fld);

	Autoref<RowType> rt1 = new CompactRowType(fld);
	UT_ASSERT(rt1->getErrors().isNull());

	Autoref<IndexType> it = new OrderedIndexType(
		(new NameSet())->add("!a")->add("b")->add("!c")->add("d")->add("e")
		);
	UT_ASSERT(it);
	Autoref<IndexType> itcopy = it->copy();
	UT_ASSERT(itcopy);
	UT_ASSERT(it != itcopy);
	UT_ASSERT(it->equals(itcopy));
	UT_ASSERT(it->match(itcopy));

	// to make sure that the copy works just as well, use both at once
	Autoref<TableType> tt = (new TableType(rt1))
		->addSubIndex("primary", it
		)->addSubIndex("secondary", itcopy
		);

	UT_ASSERT(tt);
	tt->initialize();
	if (UT_ASSERT(tt->getErrors().isNull())) {
		printf("errors: %s\n", tt->getErrors()->print().c_str());
		fflush(stdout);
	}

	const char *expect =
		"table (\n"
		"  row {\n"
		"    uint8 a,\n"
		"    int32 b,\n"
		"    int64 c,\n"
		"    float64 d,\n"
		"    string e,\n"
		"  }\n"
		") {\n"
		"  index OrderedIndex(!a, b, !c, d, e, ) primary,\n"
		"  index OrderedIndex(!a, b, !c, d, e, ) secondary,\n"
		"}"
	;
	if (UT_ASSERT(tt->print() == expect)) {
		printf("---Expected:---\n%s\n", expect);
		printf("---Received:---\n%s\n", tt->print().c_str());
		printf("---\n");
		fflush(stdout);
	}

	// make a table, some rows, and check the order
	Autoref<Unit> unit = new Unit("u");
	Autoref<Table> t = tt->makeTable(unit, "t");

	FdataVec dv;

	uint8_t myv_uint8;
	int32_t myv_int32;
	int64_t myv_int64;
	double myv_float64;
	string myv_string;

	// each type gets exercised with 2 values and a NULL
	{
		mkfdataScalar(dv);
		myv_uint8 = 11;
		dv[0].data_ = (char *)&myv_uint8;
		Rowref r1(rt1,  dv);
		t->insertRow(r1);
	}
	{
		mkfdataScalar(dv);
		myv_uint8 = 250;
		dv[0].data_ = (char *)&myv_uint8;
		Rowref r1(rt1,  dv);
		t->insertRow(r1);
	}
	{
		mkfdataScalar(dv);
		dv[0].setNull();
		Rowref r1(rt1,  dv);
		t->insertRow(r1);
	}

	{
		mkfdataScalar(dv);
		myv_int32 = 10;
		dv[1].data_ = (char *)&myv_int32;
		Rowref r1(rt1,  dv);
		t->insertRow(r1);
	}
	{
		mkfdataScalar(dv);
		myv_int32 = -10;
		dv[1].data_ = (char *)&myv_int32;
		Rowref r1(rt1,  dv);
		t->insertRow(r1);
	}
	{
		mkfdataScalar(dv);
		dv[1].setNull();
		Rowref r1(rt1,  dv);
		t->insertRow(r1);
	}

	{
		mkfdataScalar(dv);
		myv_int64 = 10;
		dv[2].data_ = (char *)&myv_int64;
		Rowref r1(rt1,  dv);
		t->insertRow(r1);
	}
	{
		mkfdataScalar(dv);
		myv_int64 = -10;
		dv[2].data_ = (char *)&myv_int64;
		Rowref r1(rt1,  dv);
		t->insertRow(r1);
	}
	{
		mkfdataScalar(dv);
		dv[2].setNull();
		Rowref r1(rt1,  dv);
		t->insertRow(r1);
	}

	{
		mkfdataScalar(dv);
		myv_float64 = 10.;
		dv[3].data_ = (char *)&myv_float64;
		Rowref r1(rt1,  dv);
		t->insertRow(r1);
	}
	{
		mkfdataScalar(dv);
		myv_float64 = -10.;
		dv[3].data_ = (char *)&myv_float64;
		Rowref r1(rt1,  dv);
		t->insertRow(r1);
	}
	{
		mkfdataScalar(dv);
		dv[3].setNull();
		Rowref r1(rt1,  dv);
		t->insertRow(r1);
	}

	// string gets one more value, an empty string
	{
		mkfdataScalar(dv);
		myv_string = "a";
		dv[4].setPtr(true, myv_string.c_str(), myv_string.size()+1);
		Rowref r1(rt1,  dv);
		t->insertRow(r1);
	}
	{
		mkfdataScalar(dv);
		myv_string = "aa";
		dv[4].setPtr(true, myv_string.c_str(), myv_string.size()+1);
		Rowref r1(rt1,  dv);
		t->insertRow(r1);
	}
	{
		mkfdataScalar(dv);
		myv_string = "";
		dv[4].setPtr(true, myv_string.c_str(), myv_string.size()+1);
		Rowref r1(rt1,  dv);
		t->insertRow(r1);
	}
	{
		mkfdataScalar(dv);
		dv[4].setNull();
		Rowref r1(rt1,  dv);
		t->insertRow(r1);
	}

	// re-insert one value, to make sure that the row gets replaced in the table
	// (i.e. the equality comparison works)
	{
		mkfdataScalar(dv);
		myv_uint8 = 250;
		dv[0].data_ = (char *)&myv_uint8;
		Rowref r1(rt1,  dv);
		t->insertRow(r1);
	}

	UT_IS(t->size(), 16);
	RowHandle *iter = t->begin();

	// field 0 "a" goes backwards
	UT_IS((int)rt1->getUint8(iter->getRow(), 0), 250); 

	// stock field 0 {

	iter = t->next(iter);
	UT_IS((int)rt1->getUint8(iter->getRow(), 0), 49); 
	UT_ASSERT(rt1->isFieldNull(iter->getRow(), 1));

	iter = t->next(iter);
	UT_IS((int)rt1->getUint8(iter->getRow(), 0), 49); 
	UT_IS(rt1->getInt32(iter->getRow(), 1), -10); 

	iter = t->next(iter);
	UT_IS((int)rt1->getUint8(iter->getRow(), 0), 49); 
	UT_IS(rt1->getInt32(iter->getRow(), 1), 10); 

	// stock field 1 {
	// stock field 2 {

	// field 2 "c" goes backwards
	iter = t->next(iter);
	UT_IS((int)rt1->getUint8(iter->getRow(), 0), 49); 
	UT_IS(rt1->getInt32(iter->getRow(), 1), 1234); 
	UT_IS(rt1->getInt64(iter->getRow(), 2), 0xdeadbeefc00c);
	UT_ASSERT(rt1->isFieldNull(iter->getRow(), 3));

	iter = t->next(iter);
	UT_IS((int)rt1->getUint8(iter->getRow(), 0), 49); 
	UT_IS(rt1->getInt32(iter->getRow(), 1), 1234); 
	UT_IS(rt1->getInt64(iter->getRow(), 2), 0xdeadbeefc00c);
	UT_IS(rt1->getFloat64(iter->getRow(), 3), -10.);

	iter = t->next(iter);
	UT_IS((int)rt1->getUint8(iter->getRow(), 0), 49); 
	UT_IS(rt1->getInt32(iter->getRow(), 1), 1234); 
	UT_IS(rt1->getInt64(iter->getRow(), 2), 0xdeadbeefc00c);
	UT_IS(rt1->getFloat64(iter->getRow(), 3), 10.);

	// stock field 3 {
	iter = t->next(iter);
	UT_IS((int)rt1->getUint8(iter->getRow(), 0), 49); 
	UT_IS(rt1->getInt32(iter->getRow(), 1), 1234); 
	UT_IS(rt1->getInt64(iter->getRow(), 2), 0xdeadbeefc00c);
	UT_IS(rt1->getFloat64(iter->getRow(), 3), 9.99e99);
	UT_ASSERT(rt1->isFieldNull(iter->getRow(), 4));

	iter = t->next(iter);
	UT_IS((int)rt1->getUint8(iter->getRow(), 0), 49); 
	UT_IS(rt1->getInt32(iter->getRow(), 1), 1234); 
	UT_IS(rt1->getInt64(iter->getRow(), 2), 0xdeadbeefc00c);
	UT_IS(rt1->getFloat64(iter->getRow(), 3), 9.99e99);
	UT_IS(string(rt1->getString(iter->getRow(), 4)), "");

	iter = t->next(iter);
	UT_IS((int)rt1->getUint8(iter->getRow(), 0), 49); 
	UT_IS(rt1->getInt32(iter->getRow(), 1), 1234); 
	UT_IS(rt1->getInt64(iter->getRow(), 2), 0xdeadbeefc00c);
	UT_IS(rt1->getFloat64(iter->getRow(), 3), 9.99e99);
	UT_IS(string(rt1->getString(iter->getRow(), 4)), "a");

	iter = t->next(iter);
	UT_IS((int)rt1->getUint8(iter->getRow(), 0), 49); 
	UT_IS(rt1->getInt32(iter->getRow(), 1), 1234); 
	UT_IS(rt1->getInt64(iter->getRow(), 2), 0xdeadbeefc00c);
	UT_IS(rt1->getFloat64(iter->getRow(), 3), 9.99e99);
	UT_IS(string(rt1->getString(iter->getRow(), 4)), "aa");

	// stock field 3 }
	// stock field 2 }

	iter = t->next(iter);
	UT_IS((int)rt1->getUint8(iter->getRow(), 0), 49); 
	UT_IS(rt1->getInt32(iter->getRow(), 1), 1234); 
	UT_IS(rt1->getInt64(iter->getRow(), 2), 10);

	iter = t->next(iter);
	UT_IS((int)rt1->getUint8(iter->getRow(), 0), 49); 
	UT_IS(rt1->getInt32(iter->getRow(), 1), 1234); 
	UT_IS(rt1->getInt64(iter->getRow(), 2), -10);

	iter = t->next(iter);
	UT_IS((int)rt1->getUint8(iter->getRow(), 0), 49); 
	UT_IS(rt1->getInt32(iter->getRow(), 1), 1234); 
	UT_ASSERT(rt1->isFieldNull(iter->getRow(), 2));

	// stock field 1 }
	// stock field 0 }

	iter = t->next(iter);
	UT_IS(rt1->getUint8(iter->getRow(), 0), 11); 

	iter = t->next(iter);
	UT_ASSERT(rt1->isFieldNull(iter->getRow(), 0));
}

// indexing by all kinds of array values
UTESTCASE orderedIndexArray(Utest *utest)
{
	RowType::FieldVec fld;
	mkfieldsArray(fld);

	Autoref<RowType> rt1 = new CompactRowType(fld);
	UT_ASSERT(rt1->getErrors().isNull());

	Autoref<IndexType> it = new OrderedIndexType(
		(new NameSet())->add("!a")->add("b")->add("!c")->add("d")
		);
	UT_ASSERT(it);
	Autoref<IndexType> itcopy = it->copy();
	UT_ASSERT(itcopy);
	UT_ASSERT(it != itcopy);
	UT_ASSERT(it->equals(itcopy));
	UT_ASSERT(it->match(itcopy));

	// to make sure that the copy works just as well, use both at once
	Autoref<TableType> tt = (new TableType(rt1))
		->addSubIndex("primary", it
		)->addSubIndex("secondary", itcopy
		);

	UT_ASSERT(tt);
	tt->initialize();
	if (UT_ASSERT(tt->getErrors().isNull())) {
		printf("errors: %s\n", tt->getErrors()->print().c_str());
		fflush(stdout);
	}

	const char *expect =
		"table (\n"
		"  row {\n"
		"    uint8[] a,\n"
		"    int32[] b,\n"
		"    int64[] c,\n"
		"    float64[] d,\n"
		"  }\n"
		") {\n"
		"  index OrderedIndex(!a, b, !c, d, ) primary,\n"
		"  index OrderedIndex(!a, b, !c, d, ) secondary,\n"
		"}"
	;
	if (UT_ASSERT(tt->print() == expect)) {
		printf("---Expected:---\n%s\n", expect);
		printf("---Received:---\n%s\n", tt->print().c_str());
		printf("---\n");
		fflush(stdout);
	}

	// make a table, some rows, and check the order
	Autoref<Unit> unit = new Unit("u");
	Autoref<Table> t = tt->makeTable(unit, "t");

	FdataVec dv;

	uint8_t myv_uint8[2];
	int32_t myv_int32[2];
	int64_t myv_int64[2];
	double myv_float64[2];

	// each type gets exercised with 3 values and a NULL
	{
		mkfdataArray(dv);
		myv_uint8[0] = 11;
		myv_uint8[1] = 12;
		dv[0].setPtr(true, myv_uint8, sizeof(uint8_t) * 2);
		Rowref r1(rt1,  dv);
		t->insertRow(r1);
	}
	{
		mkfdataArray(dv);
		myv_uint8[0] = 12;
		dv[0].setPtr(true, myv_uint8, sizeof(uint8_t) * 1);
		Rowref r1(rt1,  dv);
		t->insertRow(r1);
	}
	{
		mkfdataArray(dv);
		myv_uint8[0] = 11;
		dv[0].setPtr(true, myv_uint8, sizeof(uint8_t) * 1);
		Rowref r1(rt1,  dv);
		t->insertRow(r1);
	}
	{
		mkfdataArray(dv);
		dv[0].setNull();
		Rowref r1(rt1,  dv);
		t->insertRow(r1);
	}

	{
		mkfdataArray(dv);
		myv_int32[0] = 21;
		myv_int32[1] = 22;
		dv[1].setPtr(true, myv_int32, sizeof(int32_t) * 2);
		Rowref r1(rt1,  dv);
		t->insertRow(r1);
	}
	{
		mkfdataArray(dv);
		myv_int32[0] = 21;
		dv[1].setPtr(true, myv_int32, sizeof(int32_t) * 1);
		Rowref r1(rt1,  dv);
		t->insertRow(r1);
	}
	{
		mkfdataArray(dv);
		myv_int32[0] = 22;
		dv[1].setPtr(true, myv_int32, sizeof(int32_t) * 1);
		Rowref r1(rt1,  dv);
		t->insertRow(r1);
	}
	{
		mkfdataArray(dv);
		dv[1].setNull();
		Rowref r1(rt1,  dv);
		t->insertRow(r1);
	}

	{
		mkfdataArray(dv);
		myv_int64[0] = 31;
		myv_int64[1] = 32;
		dv[2].setPtr(true, myv_int64, sizeof(int64_t) * 2);
		Rowref r1(rt1,  dv);
		t->insertRow(r1);
	}
	{
		mkfdataArray(dv);
		myv_int64[0] = 31;
		dv[2].setPtr(true, myv_int64, sizeof(int64_t) * 1);
		Rowref r1(rt1,  dv);
		t->insertRow(r1);
	}
	{
		mkfdataArray(dv);
		myv_int64[0] = 32;
		dv[2].setPtr(true, myv_int64, sizeof(int64_t) * 1);
		Rowref r1(rt1,  dv);
		t->insertRow(r1);
	}
	{
		mkfdataArray(dv);
		dv[2].setNull();
		Rowref r1(rt1,  dv);
		t->insertRow(r1);
	}

	{
		mkfdataArray(dv);
		myv_float64[0] = 41.;
		myv_float64[1] = 42.;
		dv[3].setPtr(true, myv_float64, sizeof(double) * 2);
		Rowref r1(rt1,  dv);
		t->insertRow(r1);
	}
	{
		mkfdataArray(dv);
		myv_float64[0] = 41.;
		dv[3].setPtr(true, myv_float64, sizeof(double) * 1);
		Rowref r1(rt1,  dv);
		t->insertRow(r1);
	}
	{
		mkfdataArray(dv);
		myv_float64[0] = 42.;
		dv[3].setPtr(true, myv_float64, sizeof(double) * 1);
		Rowref r1(rt1,  dv);
		t->insertRow(r1);
	}
	{
		mkfdataArray(dv);
		dv[3].setNull();
		Rowref r1(rt1,  dv);
		t->insertRow(r1);
	}

	// re-insert one value, to make sure that the row gets replaced in the table
	// (i.e. the equality comparison works)
	{
		mkfdataArray(dv);
		myv_uint8[0] = 12;
		dv[0].setPtr(true, myv_uint8, sizeof(uint8_t) * 1);
		Rowref r1(rt1,  dv);
		t->insertRow(r1);
	}

	UT_IS(t->size(), 16);
	RowHandle *iter = t->begin();

	// stock field 0 {
	
	// field 0 "a" goes backwards

	UT_IS(rt1->getArraySize(iter->getRow(), 0), 10); // includes \0 at the end 
	UT_IS((int)rt1->getUint8(iter->getRow(), 0, 0), 49); 
	UT_IS(rt1->getArraySize(iter->getRow(), 1), 0); 

	iter = t->next(iter);
	UT_IS(rt1->getArraySize(iter->getRow(), 0), 10); 
	UT_IS((int)rt1->getUint8(iter->getRow(), 0, 0), 49); 
	UT_IS(rt1->getArraySize(iter->getRow(), 1), 1); 
	UT_IS(rt1->getInt32(iter->getRow(), 1, 0), 21); 

	iter = t->next(iter);
	UT_IS(rt1->getArraySize(iter->getRow(), 0), 10); 
	UT_IS((int)rt1->getUint8(iter->getRow(), 0, 0), 49); 
	UT_IS(rt1->getArraySize(iter->getRow(), 1), 2); 
	UT_IS(rt1->getInt32(iter->getRow(), 1, 0), 21); 
	UT_IS(rt1->getInt32(iter->getRow(), 1, 1), 22); 

	iter = t->next(iter);
	UT_IS(rt1->getArraySize(iter->getRow(), 0), 10); 
	UT_IS((int)rt1->getUint8(iter->getRow(), 0, 0), 49); 
	UT_IS(rt1->getArraySize(iter->getRow(), 1), 1); 
	UT_IS(rt1->getInt32(iter->getRow(), 1, 0), 22); 

	// stock field 1 {
	// stock field 2 {

	// field 2 "c" goes backwards

	iter = t->next(iter);
	UT_IS(rt1->getArraySize(iter->getRow(), 0), 10); 
	UT_IS((int)rt1->getUint8(iter->getRow(), 0, 0), 49); 
	UT_IS(rt1->getArraySize(iter->getRow(), 1), 2); 
	UT_IS(rt1->getInt32(iter->getRow(), 1, 0), 1234); 
	UT_IS(rt1->getInt32(iter->getRow(), 1, 1), 2345); 

	UT_IS(rt1->getArraySize(iter->getRow(), 2), 2); 
	UT_IS(rt1->getInt64(iter->getRow(), 2, 0), 0xdeadbeefc00c);
	UT_IS(rt1->getArraySize(iter->getRow(), 3), 0); 

	iter = t->next(iter);
	UT_IS(rt1->getArraySize(iter->getRow(), 0), 10); 
	UT_IS((int)rt1->getUint8(iter->getRow(), 0, 0), 49); 
	UT_IS(rt1->getArraySize(iter->getRow(), 1), 2); 
	UT_IS(rt1->getInt32(iter->getRow(), 1, 0), 1234); 
	UT_IS(rt1->getArraySize(iter->getRow(), 2), 2); 
	UT_IS(rt1->getInt64(iter->getRow(), 2, 0), 0xdeadbeefc00c);
	UT_IS(rt1->getArraySize(iter->getRow(), 3), 1); 
	UT_IS(rt1->getFloat64(iter->getRow(), 3, 0), 41.);

	iter = t->next(iter);
	UT_IS(rt1->getArraySize(iter->getRow(), 0), 10); 
	UT_IS((int)rt1->getUint8(iter->getRow(), 0, 0), 49); 
	UT_IS(rt1->getArraySize(iter->getRow(), 1), 2); 
	UT_IS(rt1->getInt32(iter->getRow(), 1, 0), 1234); 
	UT_IS(rt1->getArraySize(iter->getRow(), 2), 2); 
	UT_IS(rt1->getInt64(iter->getRow(), 2, 0), 0xdeadbeefc00c);
	UT_IS(rt1->getArraySize(iter->getRow(), 3), 2); 
	UT_IS(rt1->getFloat64(iter->getRow(), 3, 0), 41.);
	UT_IS(rt1->getFloat64(iter->getRow(), 3, 1), 42.);

	iter = t->next(iter);
	UT_IS(rt1->getArraySize(iter->getRow(), 0), 10); 
	UT_IS((int)rt1->getUint8(iter->getRow(), 0, 0), 49); 
	UT_IS(rt1->getArraySize(iter->getRow(), 1), 2); 
	UT_IS(rt1->getInt32(iter->getRow(), 1, 0), 1234); 
	UT_IS(rt1->getArraySize(iter->getRow(), 2), 2); 
	UT_IS(rt1->getInt64(iter->getRow(), 2, 0), 0xdeadbeefc00c);
	UT_IS(rt1->getArraySize(iter->getRow(), 3), 1); 
	UT_IS(rt1->getFloat64(iter->getRow(), 3, 0), 42.);

	iter = t->next(iter);
	UT_IS(rt1->getArraySize(iter->getRow(), 0), 10); 
	UT_IS((int)rt1->getUint8(iter->getRow(), 0, 0), 49); 
	UT_IS(rt1->getArraySize(iter->getRow(), 1), 2); 
	UT_IS(rt1->getInt32(iter->getRow(), 1, 0), 1234); 
	UT_IS(rt1->getArraySize(iter->getRow(), 2), 1); 
	UT_IS(rt1->getInt64(iter->getRow(), 2, 0), 32);
	UT_IS(rt1->getArraySize(iter->getRow(), 3), 2); 
	UT_IS(rt1->getFloat64(iter->getRow(), 3, 0), 9.99e99);
	UT_IS(rt1->getFloat64(iter->getRow(), 3, 1), 1.11e11);
	// just for something completely different, also iterate
	// the array differently
	{
		const double *v;
		intptr_t sz;
		bool notNull = rt1->getArrayField(iter->getRow(), 3, v, sz); 
		UT_ASSERT(notNull);
		UT_IS(sz, 2); 
		UT_IS(getUnaligned(v + 0), 9.99e99); 
		UT_IS(getUnaligned(v + 1), 1.11e11); 
	}

	iter = t->next(iter);
	UT_IS(rt1->getArraySize(iter->getRow(), 0), 10); 
	UT_IS((int)rt1->getUint8(iter->getRow(), 0, 0), 49); 
	UT_IS(rt1->getArraySize(iter->getRow(), 1), 2); 
	UT_IS(rt1->getInt32(iter->getRow(), 1, 0), 1234); 
	UT_IS(rt1->getArraySize(iter->getRow(), 2), 2); 
	UT_IS(rt1->getInt64(iter->getRow(), 2, 0), 31);
	UT_IS(rt1->getInt64(iter->getRow(), 2, 1), 32);

	iter = t->next(iter);
	UT_IS(rt1->getArraySize(iter->getRow(), 0), 10); 
	UT_IS((int)rt1->getUint8(iter->getRow(), 0, 0), 49); 
	UT_IS(rt1->getArraySize(iter->getRow(), 1), 2); 
	UT_IS(rt1->getInt32(iter->getRow(), 1, 0), 1234); 
	UT_IS(rt1->getArraySize(iter->getRow(), 2), 1); 
	UT_IS(rt1->getInt64(iter->getRow(), 2, 0), 31);

	iter = t->next(iter);
	UT_IS(rt1->getArraySize(iter->getRow(), 0), 10); 
	UT_IS((int)rt1->getUint8(iter->getRow(), 0, 0), 49); 
	UT_IS(rt1->getArraySize(iter->getRow(), 1), 2); 
	UT_IS(rt1->getInt32(iter->getRow(), 1, 0), 1234); 
	UT_IS(rt1->getArraySize(iter->getRow(), 2), 0); 

	// stock field 2 }
	// stock field 1 }
	// stock field 0 }

	iter = t->next(iter);
	UT_IS(rt1->getArraySize(iter->getRow(), 0), 1); 
	UT_IS((int)rt1->getUint8(iter->getRow(), 0, 0), 12); 

	iter = t->next(iter);
	UT_IS(rt1->getArraySize(iter->getRow(), 0), 2); 
	UT_IS((int)rt1->getUint8(iter->getRow(), 0, 0), 11); 
	UT_IS((int)rt1->getUint8(iter->getRow(), 0, 1), 12); 

	iter = t->next(iter);
	UT_IS(rt1->getArraySize(iter->getRow(), 0), 1); 
	UT_IS((int)rt1->getUint8(iter->getRow(), 0, 0), 11); 

	iter = t->next(iter);
	UT_IS(rt1->getArraySize(iter->getRow(), 0), 0); 

}

