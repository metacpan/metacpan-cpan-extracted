//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// An example of some simple sorted index.

#include <utest/Utest.h>
#include <string.h>

#include <type/AllTypes.h>
#include <sched/AggregatorGadget.h>
#include <common/StringUtil.h>
#include <common/Exception.h>
#include <table/Table.h>
#include <mem/Rhref.h>

// Make fields of all simple types
void mkfields(RowType::FieldVec &fields)
{
	fields.clear();
	fields.push_back(RowType::Field("a", Type::r_uint8, 10));
	// unlike the other tests, "b" is a scalar here
	fields.push_back(RowType::Field("b", Type::r_int32));
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

// Sort by a field that is an int32.
class Int32SortCondition : public SortedIndexCondition
{
public:
	// @param idx - index of field to use for comparison (starting from 0)
	Int32SortCondition(int idx) :
		idx_(idx)
	{ }

	Int32SortCondition(const Int32SortCondition *other, Table *t) :
		SortedIndexCondition(other, t),
		idx_(other->idx_)
	{ }

	virtual SortedIndexCondition *copy() const
	{
		return new Int32SortCondition(*this);
	}

	virtual TreeIndexType::Less *tableCopy(Table *t) const
	{
		return new Int32SortCondition(this, t);
	}

	virtual void initialize(Erref &errors, TableType *tabtype, SortedIndexType *indtype)
	{
		SortedIndexCondition::initialize(errors, tabtype, indtype);
		if (idx_ < 0)
			errors.f("The index must not be negative.");
		if (rt_->fieldCount() <= idx_)
			errors.f("The row type must contain at least %d fields.", idx_+1);

		if (!errors->hasError()) { // can be checked only if index is within range
			const RowType::Field &fld = rt_->fields()[idx_];
			if (fld.type_->getTypeId() != Type::TT_INT32)
				errors.f("The field at index %d must be an int32.", idx_);
			if (fld.arsz_ != RowType::Field::AR_SCALAR)
				errors.f("The field at index %d must not be an array.", idx_);
		}
	}

	virtual bool equals(const SortedIndexCondition *sc) const
	{
		// the cast is safe to do because the caller has checked the typeid
		Int32SortCondition *other = (Int32SortCondition *)sc;
		return idx_ == other->idx_;
	}

	virtual bool match(const SortedIndexCondition *sc) const
	{
		return equals(sc);
	}

	virtual void printTo(string &res, const string &indent = "", const string &subindent = "  ") const
	{
		res.append(strprintf("Int32Sort(%d)", idx_));
	}

	virtual bool operator() (const RowHandle *rh1, const RowHandle *rh2) const
	{
		const Row *row1 = rh1->getRow();
		const Row *row2 = rh2->getRow();
		{
			bool v1 = rt_->isFieldNull(row1, idx_);
			bool v2 = rt_->isFieldNull(row2, idx_);
			if (v1 > v2) // isNull at true goes first, so the direction is opposite
				return true;
			if (v1 < v2)
				return false;
		}
		{
			int32_t v1 = rt_->getInt32(row1, idx_);
			int32_t v2 = rt_->getInt32(row2, idx_);
			return (v1 < v2);
		}
	}

	int idx_;
};

UTESTCASE sortedIndexInt32(Utest *utest)
{
	RowType::FieldVec fld;
	mkfields(fld);

	Autoref<RowType> rt1 = new CompactRowType(fld);
	UT_ASSERT(rt1->getErrors().isNull());

	Autoref<IndexType> it = new SortedIndexType(new Int32SortCondition(1));
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
		"    uint8[10] a,\n"
		"    int32 b,\n"
		"    int64 c,\n"
		"    float64 d,\n"
		"    string e,\n"
		"  }\n"
		") {\n"
		"  index Int32Sort(1) primary,\n"
		"  index Int32Sort(1) secondary,\n"
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
	mkfdata(dv);
	
	int32_t data32;

	{
		data32 = 5;
		dv[1].data_ = (char *)&data32;
		Rowref r1(rt1,  dv);
		t->insertRow(r1);
	}
	{
		data32 = 0;
		dv[1].data_ = (char *)&data32;
		Rowref r1(rt1,  dv);
		t->insertRow(r1);
	}
	{
		data32 = -5;
		dv[1].data_ = (char *)&data32;
		Rowref r1(rt1,  dv);
		t->insertRow(r1);
	}
	{
		dv[1].notNull_ = false;
		Rowref r1(rt1,  dv);
		t->insertRow(r1);
	}

	UT_IS(t->size(), 4);
	RowHandle *iter = t->begin();
	UT_ASSERT(rt1->isFieldNull(iter->getRow(), 1));
	UT_IS(rt1->getInt32(iter->getRow(), 1), 0); 
	iter = t->next(iter);
	UT_IS(rt1->getInt32(iter->getRow(), 1), -5); 
	iter = t->next(iter);
	UT_ASSERT(!rt1->isFieldNull(iter->getRow(), 1));
	UT_IS(rt1->getInt32(iter->getRow(), 1), 0); 
	iter = t->next(iter);
	UT_IS(rt1->getInt32(iter->getRow(), 1), 5); 
}

// Sort by the named int32 fields, return getKey().
class MultiInt32SortCondition : public SortedIndexCondition
{
public:
	// @param key - the key fields specification
	MultiInt32SortCondition(NameSet *key):
		key_(key)
	{ }

	MultiInt32SortCondition(const MultiInt32SortCondition *other, Table *t) :
		SortedIndexCondition(other, t),
		idxs_(other->idxs_),
		key_(other->key_)
	{ }

	virtual SortedIndexCondition *copy() const
	{
		return new MultiInt32SortCondition(*this);
	}

	virtual TreeIndexType::Less *tableCopy(Table *t) const
	{
		return new MultiInt32SortCondition(this, t);
	}

	virtual void initialize(Erref &errors, TableType *tabtype, SortedIndexType *indtype)
	{
		SortedIndexCondition::initialize(errors, tabtype, indtype);
		idxs_.clear();

		for (int i = 0; i < key_->size(); i++) {
			const string &s = (*key_)[i];
			int n = rt_->findIdx(s);
			if (n < 0) {
				errors.f("No such field '%s'.", s.c_str());
				continue;
			}
			const RowType::Field &fld = rt_->fields()[n];
			if (fld.type_->getTypeId() != Type::TT_INT32) {
				errors.f("The field '%s' must be an int32.", s.c_str());
				continue;
			}
			if (fld.arsz_ != RowType::Field::AR_SCALAR) {
				errors.f("The field '%s' must not be an array.", s.c_str());
				continue;
			}
			idxs_.push_back(n);
		}
	}

	virtual bool equals(const SortedIndexCondition *sc) const
	{
		// the cast is safe to do because the caller has checked the typeid
		MultiInt32SortCondition *other = (MultiInt32SortCondition *)sc;

		// names must be the same
		if (!key_->equals(other->key_))
			return false;

		// and if initialized, the indexs must be the same too
		if (!rt_.isNull()) {
			if (idxs_.size() != other->idxs_.size())
				return false;

			for (int i = 0; i < idxs_.size(); i++) {
				if (idxs_[i] != other->idxs_[i])
					return false;
			}
		}

		return true;
	}

	virtual bool match(const SortedIndexCondition *sc) const
	{
		MultiInt32SortCondition *other = (MultiInt32SortCondition *)sc;
		if (rt_.isNull()) {
			// not initialized, check by names
			return key_->equals(other->key_);
		} else {
			// initialized, check by indexes
			if (idxs_.size() != other->idxs_.size())
				return false;

			for (int i = 0; i < idxs_.size(); i++) {
				if (idxs_[i] != other->idxs_[i])
					return false;
			}
			return true;
		}
	}

	virtual void printTo(string &res, const string &indent = "", const string &subindent = "  ") const
	{
		res.append("MultiInt32Sort(");
		for (NameSet::iterator i = key_->begin(); i != key_->end(); ++i) {
			res.append(*i);
			res.append(", "); // extra comma after last field doesn't hurt
		}
		res.append(")");
	}

	virtual const NameSet *getKey() const
	{
		return key_;
	}

	virtual bool operator() (const RowHandle *rh1, const RowHandle *rh2) const
	{
		const Row *row1 = rh1->getRow();
		const Row *row2 = rh2->getRow();

		int sz = idxs_.size();
		for (int i = 0; i < sz; i++) {
			int idx = idxs_[i];
			{
				bool v1 = rt_->isFieldNull(row1, idx);
				bool v2 = rt_->isFieldNull(row2, idx);
				if (v1 > v2) // isNull at true goes first, so the direction is opposite
					return true;
				if (v1 < v2)
					return false;
			}
			{
				int32_t v1 = rt_->getInt32(row1, idx);
				int32_t v2 = rt_->getInt32(row2, idx);
				if (v1 < v2)
					return true;
				if (v1 > v2)
					return false;
			}
		}
		return false; // falls through on equality, which is not less
	}

	vector<int> idxs_;
	Autoref<NameSet> key_;
};

UTESTCASE sortedIndexMultiInt32(Utest *utest)
{
	RowType::FieldVec fld;
	mkfields(fld);
	fld[2].type_ = Type::r_int32;

	Autoref<RowType> rt1 = new CompactRowType(fld);
	UT_ASSERT(rt1->getErrors().isNull());

	Autoref<IndexType> it = new SortedIndexType(new MultiInt32SortCondition(
		NameSet::make()->add("b")->add("c")
	));
	UT_ASSERT(it);
	Autoref<IndexType> itcopy = it->copy();
	UT_ASSERT(itcopy);
	UT_ASSERT(it != itcopy);
	UT_ASSERT(it->equals(itcopy));
	UT_ASSERT(it->match(itcopy));

	Autoref<TableType> tt = (new TableType(rt1))
		->addSubIndex("primary", it
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
		"    uint8[10] a,\n"
		"    int32 b,\n"
		"    int32 c,\n"
		"    float64 d,\n"
		"    string e,\n"
		"  }\n"
		") {\n"
		"  index MultiInt32Sort(b, c, ) primary,\n"
		"}"
	;
	if (UT_ASSERT(tt->print() == expect)) {
		printf("---Expected:---\n%s\n", expect);
		printf("---Received:---\n%s\n", tt->print().c_str());
		printf("---\n");
		fflush(stdout);
	}

	const NameSet *key = it->getKey();
	UT_ASSERT(key != NULL);
	UT_IS(key->size(), 2);
	UT_IS(key->at(0), "b");
	UT_IS(key->at(1), "c");

	// make a table, some rows, and check the order
	Autoref<Unit> unit = new Unit("u");
	Autoref<Table> t = tt->makeTable(unit, "t");

	FdataVec dv;
	mkfdata(dv);
	
	int32_t data32;

	{
		data32 = 5;
		dv[1].data_ = (char *)&data32;
		Rowref r1(rt1,  dv);
		t->insertRow(r1);
	}
	{
		data32 = 0;
		dv[1].data_ = (char *)&data32;
		Rowref r1(rt1,  dv);
		t->insertRow(r1);
	}
	{
		data32 = -5;
		dv[1].data_ = (char *)&data32;
		Rowref r1(rt1,  dv);
		t->insertRow(r1);
	}
	{
		dv[1].notNull_ = false;
		Rowref r1(rt1,  dv);
		t->insertRow(r1);

		dv[2].notNull_ = false;
		Rowref r2(rt1,  dv);
		t->insertRow(r2);
	}

	UT_IS(t->size(), 5);
	RowHandle *iter = t->begin();

	UT_ASSERT(rt1->isFieldNull(iter->getRow(), 1));
	UT_ASSERT(rt1->isFieldNull(iter->getRow(), 2));

	iter = t->next(iter);
	UT_ASSERT(rt1->isFieldNull(iter->getRow(), 1));
	UT_IS(rt1->getInt32(iter->getRow(), 1), 0); 
	UT_ASSERT(!rt1->isFieldNull(iter->getRow(), 2));

	iter = t->next(iter);
	UT_IS(rt1->getInt32(iter->getRow(), 1), -5); 

	iter = t->next(iter);
	UT_ASSERT(!rt1->isFieldNull(iter->getRow(), 1));
	UT_IS(rt1->getInt32(iter->getRow(), 1), 0); 

	iter = t->next(iter);
	UT_IS(rt1->getInt32(iter->getRow(), 1), 5); 
}

// Sort by a generated sequence value.
class SeqSortCondition : public SortedIndexCondition
{
protected:
	class SeqRhSection : public TreeIndexType::BasicRhSection
	{
	public:
		SeqRhSection(int64_t val) :
			seq_(val)
		{ }

		int64_t seq_; // the sequence number of this row handle
	};

public:
	SeqSortCondition() :
		seq_(0)
	{ }

	SeqSortCondition(const SeqSortCondition *other, Table *t) :
		SortedIndexCondition(other, t),
		seq_(other->seq_)
	{ }

	virtual SortedIndexCondition *copy() const
	{
		return new SeqSortCondition(*this);
	}

	virtual TreeIndexType::Less *tableCopy(Table *t) const
	{
		return new SeqSortCondition(this, t);
	}

	virtual void initialize(Erref &errors, TableType *tabtype, SortedIndexType *indtype)
	{
		SortedIndexCondition::initialize(errors, tabtype, indtype);
		seq_ = 0;
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
		res.append("Sequenced");
	}

	virtual size_t sizeOfRhSection() const
	{
		return sizeof(SeqRhSection);
	}

	virtual void initRowHandleSection(RowHandle *rh) const
	{
		// initialize the Seq part, the general Sorted index
		// will initialize the iterator
	    SeqRhSection *rs = rh->get<SeqRhSection>(rhOffset_);
	    new(rs) SeqRhSection(seq_++);
	}
	
	virtual void clearRowHandleSection(RowHandle *rh) const
	{ 
	    // clear the iterator by calling its destructor
	    SeqRhSection *rs = rh->get<SeqRhSection>(rhOffset_);
	    rs->~SeqRhSection();
	}
	
	virtual void copyRowHandleSection(RowHandle *rh, const RowHandle *fromrh) const
	{
	    SeqRhSection *rs = rh->get<SeqRhSection>(rhOffset_);
	    SeqRhSection *fromrs = fromrh->get<SeqRhSection>(rhOffset_);
	    
	    // initialize the iterator by calling its copy constructor inside the placement,
		// the sequence number gets copied too
	    new(rs) SeqRhSection(*fromrs);
	}
	
	// Helper method to read the sequence from the row handle,
	// can also be used by the end-user. The row handle must as usual
	// belong to a table of this type.
	int64_t getSeq(const RowHandle *rh) const
	{
	    return rh->get<SeqRhSection>(rhOffset_)->seq_;
	}

	// Helper method to set the sequence in the row handle.
	// May be used only on the rows that are not in a table.
	void setSeq(const RowHandle *rh, int64_t val) const
	{
		if (rh->isInTable()) {
			throw Exception("Attempted to change the sequence on a row in table.", true);
		}
	    rh->get<SeqRhSection>(rhOffset_)->seq_ = val;
	}

	virtual bool operator() (const RowHandle *rh1, const RowHandle *rh2) const
	{
		return getSeq(rh1) < getSeq(rh2);
	}

	mutable int64_t seq_; // the next sequence number to assign
};

UTESTCASE sortedIndexSeq(Utest *utest)
{
	RowType::FieldVec fld;
	mkfields(fld);

	Autoref<RowType> rt1 = new CompactRowType(fld);
	UT_ASSERT(rt1->getErrors().isNull());

	Autoref<IndexType> it = new SortedIndexType(new SeqSortCondition());
	UT_ASSERT(it);
	Autoref<IndexType> itcopy = it->copy();
	UT_ASSERT(itcopy);
	UT_ASSERT(it != itcopy);
	UT_ASSERT(it->equals(itcopy));
	UT_ASSERT(it->match(itcopy));

	Autoref<TableType> tt = (new TableType(rt1))
		->addSubIndex("primary", it
		);

	UT_ASSERT(tt);
	tt->initialize();
	if (UT_ASSERT(tt->getErrors().isNull())) {
		printf("errors: %s\n", tt->getErrors()->print().c_str());
		fflush(stdout);
	}

	Autoref<SortedIndexType> ixt = dynamic_cast<SortedIndexType *>(tt->findSubIndex("primary"));
	UT_ASSERT(ixt);
	Autoref<SeqSortCondition> sc = dynamic_cast<SeqSortCondition *>(ixt->getCondition());
	UT_ASSERT(sc);

	const char *expect =
		"table (\n"
		"  row {\n"
		"    uint8[10] a,\n"
		"    int32 b,\n"
		"    int64 c,\n"
		"    float64 d,\n"
		"    string e,\n"
		"  }\n"
		") {\n"
		"  index Sequenced primary,\n"
		"}"
	;
	if (UT_ASSERT(tt->print() == expect)) {
		printf("---Expected:---\n%s\n", expect);
		printf("---Received:---\n%s\n", tt->print().c_str());
		printf("---\n");
		fflush(stdout);
	}

	const NameSet *key = it->getKey();
	UT_ASSERT(key == NULL);

	// make a table, some rows, and check the order
	Autoref<Unit> unit = new Unit("u");
	Autoref<Table> t = tt->makeTable(unit, "t");

	FdataVec dv;
	mkfdata(dv);
	
	int32_t data32;

	{
		data32 = 5;
		dv[1].data_ = (char *)&data32;
		Rowref r1(rt1,  dv);
		t->insertRow(r1);
	}
	{
		data32 = 0;
		dv[1].data_ = (char *)&data32;
		Rowref r1(rt1,  dv);
		t->insertRow(r1);
	}
	{
		data32 = -5;
		dv[1].data_ = (char *)&data32;
		Rowref r1(rt1,  dv);
		Rhref rh1(t, r1);
		// In reality should never set the sequence number for insert;
		// that would risk the duplication. This is intended for
		// searching or deleting the pre-existing records with 
		// pre-existing sequence numbers.
		sc->setSeq(rh1, 99);
		t->insert(rh1);
	}
	{
		dv[1].notNull_ = false;
		Rowref r1(rt1,  dv);
		t->insertRow(r1);
	}

	UT_IS(t->size(), 4);
	RowHandle *iter = t->begin();

	UT_IS(rt1->getInt32(iter->getRow(), 1), 5); 
	UT_IS(sc->getSeq(iter), 0); 

	iter = t->next(iter);
	UT_ASSERT(!rt1->isFieldNull(iter->getRow(), 1));
	UT_IS(rt1->getInt32(iter->getRow(), 1), 0); 
	UT_IS(sc->getSeq(iter), 1); 

	iter = t->next(iter);
	UT_ASSERT(rt1->isFieldNull(iter->getRow(), 1));
	UT_IS(sc->getSeq(iter), 3); 

	iter = t->next(iter);
	UT_IS(rt1->getInt32(iter->getRow(), 1), -5); 
	UT_IS(sc->getSeq(iter), 99); 
}

