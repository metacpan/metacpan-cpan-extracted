//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Test of table creation with a sorted index.

#include <utest/Utest.h>
#include <string.h>

#include <common/Common.h>
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

// make the exceptions catchable
void make_catchable()
{
	Exception::abort_ = false; // make them catchable
	Exception::enableBacktrace_ = false; // make the error messages predictable
}

// restore the exceptions back to the uncatchable state
void restore_uncatchable()
{
	Exception::abort_ = true;
	Exception::enableBacktrace_ = true;
}

// sort by field "b"
class MySortB : public SortedIndexCondition
{
public:
	// no internal configuration, all copies are the same
	MySortB()
	{ }
	MySortB(const MySortB *other, Table *t) :
		SortedIndexCondition(other, t)
	{ }
	virtual TreeIndexType::Less *tableCopy(Table *t) const
	{
		return new MySortB(this, t);
	}
	virtual bool equals(const SortedIndexCondition *sc) const
	{
		return true;
	}
	virtual bool match(const SortedIndexCondition *sc) const
	{
		return true;
	}
	virtual void printTo(string &res, const string &indent = "", const string &subindent = "  ") const
	{
		res.append("MySortB()");
	}
	virtual SortedIndexCondition *copy() const
	{
		return new MySortB(*this);
	}

	virtual bool operator() (const RowHandle *r1, const RowHandle *r2) const
	{
		int32_t a = rt_->getInt32(r1->getRow(), 1);
		int32_t b = rt_->getInt32(r2->getRow(), 1);
		return (a < b);
	}
};

// sort by field "c"
class MySortC : public SortedIndexCondition
{
public:
	// no internal configuration, all copies are the same
	MySortC()
	{ }
	MySortC(const MySortC *other, Table *t) :
		SortedIndexCondition(other, t)
	{ }
	virtual TreeIndexType::Less *tableCopy(Table *t) const
	{
		return new MySortC(this, t);
	}
	virtual bool equals(const SortedIndexCondition *sc) const
	{
		return true;
	}
	virtual bool match(const SortedIndexCondition *sc) const
	{
		return true;
	}
	virtual void printTo(string &res, const string &indent = "", const string &subindent = "  ") const
	{
		res.append("MySortC()");
	}
	virtual SortedIndexCondition *copy() const
	{
		return new MySortC(*this);
	}

	virtual bool operator() (const RowHandle *r1, const RowHandle *r2) const
	{
		int64_t a = rt_->getInt64(r1->getRow(), 2);
		int64_t b = rt_->getInt64(r2->getRow(), 2);
		return (a < b);
	}
};

UTESTCASE primaryIndex(Utest *utest)
{
	RowType::FieldVec fld;
	mkfields(fld);

	Autoref<Unit> unit = new Unit("u");
	Autoref<RowType> rt1 = new CompactRowType(fld);
	UT_ASSERT(rt1->getErrors().isNull());

	Autoref<TableType> tt = (new TableType(rt1))
		->addSubIndex("primary", new SortedIndexType(new MySortB())
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

UTESTCASE tableops(Utest *utest)
{
	RowType::FieldVec fld;
	mkfields(fld);

	Autoref<Unit> unit = new Unit("u");
	Autoref<RowType> rt1 = new CompactRowType(fld);
	UT_ASSERT(rt1->getErrors().isNull());

	Autoref<TableType> tt = (new TableType(rt1))
		->addSubIndex("primary", new SortedIndexType(new MySortB())
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
		->addSubIndex("primary", new SortedIndexType(new MySortB())
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
	int32_t one = 1;
	dv[1].setPtr(true, &one, sizeof(one));
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
	int32_t two = 2;
	dv[1].setPtr(true, &two, sizeof(two));
	Rowref r2(rt1, rt1->makeRow(dv));

	UT_ASSERT(t->insertRow(r2));

	// check that now have 2 records, in the right order
	iter = t->begin();
	if (UT_ASSERT(iter != NULL)) return;
	UT_ASSERT(iter->getRow() == r1);
	iter = t->next(iter);
	if (UT_ASSERT(iter != NULL)) return;
	UT_ASSERT(iter->getRow() == r2);
	iter = t->next(iter);
	UT_ASSERT(iter == NULL);

	// add 3rd record, in order before the first
	int32_t zero = 0;
	dv[1].setPtr(true, &zero, sizeof(zero));
	Rowref r3(rt1, rt1->makeRow(dv));

	UT_ASSERT(t->insertRow(r3));

	// check that now have 3 records, in the correct order
	iter = t->begin();
	if (UT_ASSERT(iter != NULL)) return;
	UT_ASSERT(iter->getRow() == r3);
	iter = t->next(iter);
	if (UT_ASSERT(iter != NULL)) return;
	UT_ASSERT(iter->getRow() == r1);
	iter = t->next(iter);
	if (UT_ASSERT(iter != NULL)) return;
	UT_ASSERT(iter->getRow() == r2);
	iter = t->next(iter);
	UT_ASSERT(iter == NULL);

	// find and remove the 1st record
	iter = t->findIdx(prim, rh1);
	UT_ASSERT(iter != NULL);
	t->remove(iter);

	// check that the record is not there any more
	iter = t->findIdx(prim, rh1);
	UT_ASSERT(iter == NULL);

	// check that now have 2 records, still in correct order
	iter = t->begin();
	if (UT_ASSERT(iter != NULL)) return;
	UT_ASSERT(iter->getRow() == r3);
	iter = t->next(iter);
	if (UT_ASSERT(iter != NULL)) return;
	UT_ASSERT(iter->getRow() == r2);
	iter = t->next(iter);
	UT_ASSERT(iter == NULL);

	// test deleteRow()
	UT_ASSERT(t->deleteRow(r3));
	UT_ASSERT(!t->deleteRow(r3)); // already removed, not found any more
}

bool sortFail = true; // controls whether the sorter fails
// set a sticky error on each call when sortFail is true, otherwise sort on "b"
class MySortError : public SortedIndexCondition
{
public:
	// no internal configuration, all copies are the same
	MySortError()
	{ }
	MySortError(const MySortError *other, Table *t) :
		SortedIndexCondition(other, t)
	{ }
	virtual TreeIndexType::Less *tableCopy(Table *t) const
	{
		return new MySortError(this, t);
	}
	virtual bool equals(const SortedIndexCondition *sc) const
	{
		return true;
	}
	virtual bool match(const SortedIndexCondition *sc) const
	{
		return true;
	}
	virtual void printTo(string &res, const string &indent = "", const string &subindent = "  ") const
	{
		res.append("MySortError()");
	}
	virtual SortedIndexCondition *copy() const
	{
		return new MySortError(*this);
	}

	virtual bool operator() (const RowHandle *r1, const RowHandle *r2) const
	{
		if (sortFail) {
			table_->setStickyError(new Errors("test error"));
			return false;
		}
		// like MySortB
		int32_t a = rt_->getInt32(r1->getRow(), 1);
		int32_t b = rt_->getInt32(r2->getRow(), 1);
		return (a < b);
	}
};

UTESTCASE tableops_exception(Utest *utest)
{
	make_catchable();

	RowType::FieldVec fld;
	mkfields(fld);

	Autoref<Unit> unit = new Unit("u");
	Autoref<RowType> rt1 = new CompactRowType(fld);
	UT_ASSERT(rt1->getErrors().isNull());

	Autoref<TableType> tt = (new TableType(rt1))
		->addSubIndex("primary", new SortedIndexType(new MySortError())
		);

	UT_ASSERT(tt);
	tt->initialize();
	UT_ASSERT(tt->getErrors().isNull());
	UT_ASSERT(!tt->getErrors()->hasError());

	IndexType *prim = tt->findSubIndex("primary");
	UT_ASSERT(prim != NULL);

	FdataVec dv;
	mkfdata(dv);
	int32_t one = 1, two = 2, three = 3;
	dv[1].setPtr(true, &one, sizeof(one));
	Rowref r1(rt1,  rt1->makeRow(dv));
	dv[1].setPtr(true, &two, sizeof(one));
	Rowref r2(rt1,  rt1->makeRow(dv));
	dv[1].setPtr(true, &three, sizeof(one));
	Rowref r3(rt1,  rt1->makeRow(dv));

	// just set and check the error manually
	{
		Autoref<Table> t = tt->makeTable(unit, "t");
		UT_ASSERT(!t.isNull());

		// no error yet
		UT_IS(t->getStickyError(), NULL);
		t->checkStickyError();

		// now add the error
		t->setStickyError(new Errors("error 1"));
		Erref err = t->getStickyError();
		UT_IS(err->print(), "error 1\n");

		{
			string msg;
			try {
				t->checkStickyError();
			} catch(Exception e) {
				msg = e.getErrors()->print();
			}
			UT_IS(msg, "Table is disabled due to the previous error:\n  error 1\n");
		}
	}

	// set the error on insert and test that everything stops after that
	{
		Autoref<Table> t = tt->makeTable(unit, "t");
		UT_ASSERT(!t.isNull());

		Rhref rh1(t, t->makeRowHandle(r1));
		Rhref rh2(t, t->makeRowHandle(r2));

		{
			string msg;
			try {
				// the first insert might involve no comparison, so do it
				// twice to cause the error for sure
				t->insert(rh1);
				t->insert(rh2);
			} catch(Exception e) {
				msg = e.getErrors()->print();
			}
			UT_IS(msg, "test error\n");
		}

		// making and destroying a row handle still works
		{
			Rhref rh3(t, t->makeRowHandle(r1));
		}

		// after that all the calls that involve an index return en error
		static char expect[] = "Table is disabled due to the previous error:\n  test error\n";
		{
			string msg;
			try {
				t->insert(rh1);
			} catch(Exception e) {
				msg = e.getErrors()->print();
			}
			UT_IS(msg, expect);
		}
		{
			string msg;
			try {
				t->insertRow(r1);
			} catch(Exception e) {
				msg = e.getErrors()->print();
			}
			UT_IS(msg, expect);
		}
		{
			string msg;
			try {
				t->remove(rh1);
			} catch(Exception e) {
				msg = e.getErrors()->print();
			}
			UT_IS(msg, expect);
		}
		{
			string msg;
			try {
				t->deleteRow(r1);
			} catch(Exception e) {
				msg = e.getErrors()->print();
			}
			UT_IS(msg, expect);
		}
		{
			string msg;
			try {
				t->begin();
			} catch(Exception e) {
				msg = e.getErrors()->print();
			}
			UT_IS(msg, expect);
		}
		{
			string msg;
			try {
				t->beginIdx(prim);
			} catch(Exception e) {
				msg = e.getErrors()->print();
			}
			UT_IS(msg, expect);
		}
		{
			string msg;
			try {
				t->next(NULL);
			} catch(Exception e) {
				msg = e.getErrors()->print();
			}
			UT_IS(msg, expect);
		}
		{
			string msg;
			try {
				t->nextIdx(prim, NULL);
			} catch(Exception e) {
				msg = e.getErrors()->print();
			}
			UT_IS(msg, expect);
		}
		{
			string msg;
			try {
				t->firstOfGroupIdx(prim, NULL);
			} catch(Exception e) {
				msg = e.getErrors()->print();
			}
			UT_IS(msg, expect);
		}
		{
			string msg;
			try {
				t->nextGroupIdx(prim, NULL);
			} catch(Exception e) {
				msg = e.getErrors()->print();
			}
			UT_IS(msg, expect);
		}
		{
			string msg;
			try {
				t->lastOfGroupIdx(prim, NULL);
			} catch(Exception e) {
				msg = e.getErrors()->print();
			}
			UT_IS(msg, expect);
		}
		{
			string msg;
			try {
				t->findIdx(prim, NULL);
			} catch(Exception e) {
				msg = e.getErrors()->print();
			}
			UT_IS(msg, expect);
		}
		{
			string msg;
			try {
				t->findRowIdx(prim, r1);
			} catch(Exception e) {
				msg = e.getErrors()->print();
			}
			UT_IS(msg, expect);
		}
		{
			string msg;
			try {
				t->groupSizeIdx(prim, NULL);
			} catch(Exception e) {
				msg = e.getErrors()->print();
			}
			UT_IS(msg, expect);
		}
		{
			string msg;
			try {
				t->groupSizeRowIdx(prim, r1);
			} catch(Exception e) {
				msg = e.getErrors()->print();
			}
			UT_IS(msg, expect);
		}
		{
			string msg;
			try {
				t->clear(0);
			} catch(Exception e) {
				msg = e.getErrors()->print();
			}
			UT_IS(msg, expect);
		}
		{
			string msg;
			try {
				t->dumpAll(Rowop::OP_INSERT);
			} catch(Exception e) {
				msg = e.getErrors()->print();
			}
			UT_IS(msg, expect);
		}
		{
			string msg;
			try {
				t->dumpAllIdx(prim, Rowop::OP_INSERT);
			} catch(Exception e) {
				msg = e.getErrors()->print();
			}
			UT_IS(msg, expect);
		}
	}

	// triggering an error on remove() seems impossible, so give up on that,
	// the same goes for firstOfGroupIdx(), nextGroupIdx(), lastOfGroupIdx()
	
	// error on deleteRow
	{
		Autoref<Table> t = tt->makeTable(unit, "t");
		UT_ASSERT(!t.isNull());

		Rhref rh1(t, t->makeRowHandle(r1));
		Rhref rh2(t, t->makeRowHandle(r2));
		Rhref rh3(t, t->makeRowHandle(r3));

		sortFail = false;
		t->insert(rh1);
		t->insert(rh2);
		t->insert(rh3);
		sortFail = true;

		{
			string msg;
			try {
				t->deleteRow(r1);
			} catch(Exception e) {
				msg = e.getErrors()->print();
			}
			UT_IS(msg, "test error\n");
		}
	}
	
	// error on findRowIdx() (propagated from findIdx())
	{
		Autoref<Table> t = tt->makeTable(unit, "t");
		UT_ASSERT(!t.isNull());

		Rhref rh1(t, t->makeRowHandle(r1));
		Rhref rh2(t, t->makeRowHandle(r2));
		Rhref rh3(t, t->makeRowHandle(r3));

		sortFail = false;
		t->insert(rh1);
		t->insert(rh2);
		t->insert(rh3);
		sortFail = true;

		{
			string msg;
			try {
				t->findRowIdx(prim, r2);
			} catch(Exception e) {
				msg = e.getErrors()->print();
			}
			UT_IS(msg, "test error\n");
		}
	}

	restore_uncatchable();
}
