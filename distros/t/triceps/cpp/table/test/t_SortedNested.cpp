//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Test of table creation with a sorted index.

#include <utest/Utest.h>
#include <string.h>

#include <type/AllTypes.h>
#include <common/StringUtil.h>
#include <table/Table.h>
#include <type/BasicAggregatorType.h>
#include <table/BasicAggregator.h>
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

Onceref<TableType> mktabtype(Onceref<RowType> rt)
{
	return TableType::make(rt)
		->addSubIndex("primary", SortedIndexType::make(
				new MySortB()
			)->addSubIndex("level2", SortedIndexType::make(
					new MySortC()
				)
			)
		);
}

UTESTCASE primaryIndex(Utest *utest)
{
	RowType::FieldVec fld;
	mkfields(fld);

	Autoref<Unit> unit = new Unit("u");
	Autoref<RowType> rt1 = new CompactRowType(fld);
	UT_ASSERT(rt1->getErrors().isNull());

	Autoref<TableType> tt = mktabtype(rt1);

	UT_ASSERT(tt);
	tt->initialize();
	UT_ASSERT(tt->getErrors().isNull());
	UT_ASSERT(!tt->getErrors()->hasError());

	Autoref<Table> t = tt->makeTable(unit, "t");
	UT_ASSERT(!t.isNull());
}

UTESTCASE uninitialized(Utest *utest)
{
	RowType::FieldVec fld;
	mkfields(fld);

	Autoref<Unit> unit = new Unit("u");
	Autoref<RowType> rt1 = new CompactRowType(fld);
	UT_ASSERT(rt1->getErrors().isNull());

	Autoref<TableType> tt = mktabtype(rt1);

	UT_ASSERT(tt);

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

	Autoref<TableType> tt = mktabtype(rt1);

	UT_ASSERT(tt);
	tt->initialize();
	UT_ASSERT(tt->getErrors().isNull());
	UT_ASSERT(!tt->getErrors()->hasError());

	Autoref<Table> t = tt->makeTable(unit, "t");
	UT_ASSERT(!t.isNull());

	IndexType *prim = tt->findSubIndex("primary");
	UT_ASSERT(prim != NULL);

	IndexType *sec = prim->findSubIndex("level2");
	UT_ASSERT(sec != NULL);

	// above here was a copy of primaryIndex()

	// create a matrix of records, across both axes of indexing

	RowHandle *iter, *iter2, *iter3;
	Fdata v1, v2;
	FdataVec dv;
	mkfdata(dv);

	int32_t one32 = 1, two32 = 2;
	int64_t one64 = 1, two64 = 2;

	dv[1].data_ = (char *)&one32; dv[2].data_ = (char *)&one64;
	Rowref r11(rt1,  rt1->makeRow(dv));
	Rhref rh11(t, t->makeRowHandle(r11));

	dv[1].data_ = (char *)&one32; dv[2].data_ = (char *)&two64;
	Rowref r12(rt1,  rt1->makeRow(dv));
	Rhref rh12(t, t->makeRowHandle(r12));

	dv[1].data_ = (char *)&two32; dv[2].data_ = (char *)&one64;
	Rowref r21(rt1,  rt1->makeRow(dv));
	Rhref rh21(t, t->makeRowHandle(r21));

	dv[1].data_ = (char *)&two32; dv[2].data_ = (char *)&two64;
	Rowref r22(rt1,  rt1->makeRow(dv));
	Rhref rh22(t, t->makeRowHandle(r22));

	// so far the table must be empty
	iter = t->begin();
	UT_IS(iter, NULL);

	// basic insertion
	UT_ASSERT(t->insert(rh11));
	UT_ASSERT(t->insert(rh22));
	UT_ASSERT(t->insert(rh12));
	UT_ASSERT(t->insert(rh21));

	// see that they can be found by index
	iter = t->findIdx(sec, rh11);
	UT_IS(iter, rh11);
	iter = t->findIdx(sec, rh12);
	UT_IS(iter, rh12);
	iter = t->findIdx(sec, rh21);
	UT_IS(iter, rh21);
	iter = t->findIdx(sec, rh22);
	UT_IS(iter, rh22);

	// now must have 4 records, grouped by field b, sorted
	iter = t->begin();
	UT_IS(iter, rh11);
	iter = t->next(iter);
	UT_IS(iter, rh12);

	iter = t->next(iter);
	UT_IS(iter, rh21);
	iter = t->next(iter);
	UT_IS(iter, rh22);

	iter = t->next(iter);
	UT_IS(iter, NULL);

	// this should replace the row with an identical one but with auto-created handle
	UT_ASSERT(t->insertRow(r11));
	// check that the old record is replaced but the rest stay
	iter = t->begin();
	UT_ASSERT(iter != rh11);
	UT_IS(iter->getRow(), r11);
	iter2 = iter;

	iter = t->next(iter);
	UT_IS(iter, rh12);

	iter = t->next(iter);
	UT_IS(iter, rh21);
	iter = t->next(iter);
	UT_IS(iter, rh22);

	iter = t->next(iter);
	UT_IS(iter, NULL);

	// check that the newly inserted record can be found by find on the same key
	iter = t->findIdx(sec, rh11);
	UT_IS(iter, iter2);

	// check that search on a non-leaf index returns the start of group
	iter = t->findIdx(prim, rh11);
	UT_IS(iter, iter2);
	// find the end of the group
	iter3 = t->nextGroupIdx(sec, iter);
	UT_IS(iter3, rh21);

	// another start of group...
	iter = t->findIdx(prim, rh22);
	UT_IS(iter, rh21);
	iter3 = t->nextGroupIdx(sec, iter);
	UT_IS(iter3, NULL);

	// check that iteration with NULL doesn't crash
	UT_ASSERT(t->next(NULL) == NULL);

	// and remove the remembered copy
	t->remove(iter2);

	// check that the record is not there any more
	iter = t->findIdx(sec, rh11);
	UT_ASSERT(iter == NULL);

	// check that now have 3 records
	iter = t->begin();
	UT_IS(iter, rh12);

	iter = t->next(iter);
	UT_IS(iter, rh21);
	iter = t->next(iter);
	UT_IS(iter, rh22);

	iter = t->next(iter);
	UT_IS(iter, NULL);

	// remove the 2nd record from the same group
	t->remove(rh12);
	
	// check that now have 2 records
	iter = t->begin();
	UT_IS(iter, rh21);
	iter = t->next(iter);
	UT_IS(iter, rh22);

	iter = t->next(iter);
	UT_IS(iter, NULL);
}

