//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// An index that implements a unique primary key with an unpredictable order.

#include <type/HashedIndexType.h>
#include <type/TableType.h>
#include <table/TreeIndex.h>
#include <table/TreeNestedIndex.h>
#include <table/Table.h>
#include <string.h>

namespace TRICEPS_NS {

//////////////////////////// HashedIndexType::Less  /////////////////////////

HashedIndexType::Less::Less(const RowType *rt, intptr_t rhOffset, const vector<int32_t> &keyFld)  :
	TreeIndexType::Less(rt),
	keyFld_(keyFld),
	rhOffset_(rhOffset)
{ }

HashedIndexType::Less::Less(const Less *other, Table *t) :
	TreeIndexType::Less(other, t),
	keyFld_(other->keyFld_),
	rhOffset_(other->rhOffset_)
{ }

TreeIndexType::Less *HashedIndexType::Less::tableCopy(Table *t) const
{
	return new Less(this, t);
}

bool HashedIndexType::Less::operator() (const RowHandle *r1, const RowHandle *r2) const 
{
	RhSection *rs1 = r1->get<RhSection>(rhOffset_);
	RhSection *rs2 = r2->get<RhSection>(rhOffset_);

	{
		Hash::SValue h1 = rs1->hash_;
		Hash::SValue h2= rs2->hash_;
		if (h1 < h2)
			return true;
		if (h1 > h2)
			return false;
	}

	// if the hashes match, do the full comparison
	int nf = keyFld_.size();
	for (int i = 0; i < nf; i++) {
		int idx = keyFld_[i];
		bool notNull1, notNull2;
		const char *v1, *v2;
		intptr_t len1, len2;

		notNull1 = rt_->getField(r1->getRow(), idx, v1, len1);
		notNull2 = rt_->getField(r2->getRow(), idx, v2, len2);

		// another shortcut
		if (len1 < len2)
			return true;
		if (len1 > len2)
			return false;

		if (len1 != 0) {
			int df = memcmp(v1, v2, len1);
			if (df < 0)
				return true;
			if (df > 0)
				return false;
		}

		// finally check for nulls if all else equal
		if (!notNull1){
			if (notNull2)
				return true;
		} else {
			if (!notNull2)
				return false;
		}
	}

	return false; // gets here only on equal values
}

//////////////////////////// HashedIndexType /////////////////////////

HashedIndexType::HashedIndexType(NameSet *key) :
	TreeIndexType(IT_HASHED),
	key_(key)
{
}

HashedIndexType::HashedIndexType(const HashedIndexType &orig, bool flat) :
	TreeIndexType(orig, flat)
{
	if (!orig.key_.isNull()) {
		key_ = new NameSet(*orig.key_);
	}
}

HashedIndexType::HashedIndexType(const HashedIndexType &orig, HoldRowTypes *holder) :
	TreeIndexType(orig, holder)
{
	if (!orig.key_.isNull()) {
		key_ = new NameSet(*orig.key_);
	}
}

HashedIndexType *HashedIndexType::setKey(NameSet *key)
{
	if (initialized_) {
		Autoref<HashedIndexType> cleaner = this;
		throw Exception::fTrace("Attempted to set the key on an initialized Hashed index type");
	}
	key_ = key;
	return this;
}

const NameSet *HashedIndexType::getKey() const
{
	return key_;
}

bool HashedIndexType::equals(const Type *t) const
{
	if (this == t)
		return true; // self-comparison, shortcut

	if (!IndexType::equals(t))
		return false;
	
	const HashedIndexType *pit = static_cast<const HashedIndexType *>(t);
	if ( (!key_.isNull() && pit->key_.isNull())
	|| (key_.isNull() && !pit->key_.isNull()) )
		return false;

	if (!key_->equals(pit->key_))
		return false;

	// if initialized, check the translation of key to field indexes
	const TableType *tt1 = getTabtype();
	const TableType *tt2 = pit->getTabtype();
	if (tt1 == NULL || tt2 == NULL)
		return true; // good enough

	const RowType *rt1 = tt1->rowType();
	const RowType *rt2 = tt2->rowType();
	if (rt1 == NULL || rt2 == NULL)
		return true; // good enough

	// check that the key matches the same fields by index
	int nf = key_->size();
	for (int i = 0; i < nf; i++) {
		int trans1 = rt1->findIdx((*key_)[i]);
		int trans2 = rt2->findIdx((*pit->key_)[i]);
		if (trans1 != trans2 || trans1 < 0)
			return false;
	}
	return true;
}

bool HashedIndexType::match(const Type *t) const
{
	if (this == t)
		return true; // self-comparison, shortcut

	if (!IndexType::match(t))
		return false;
	
	const HashedIndexType *pit = static_cast<const HashedIndexType *>(t);
	if ( (!key_.isNull() && pit->key_.isNull())
	|| (key_.isNull() && !pit->key_.isNull()) )
		return false;

	if (key_->size() != pit->key_->size())
		return false;

	const TableType *tt1 = getTabtype();
	const TableType *tt2 = pit->getTabtype();

	if (tt1 == NULL || tt2 == NULL)
		// without the table type, the row type is not known, so use an exact match
		return key_->equals(pit->key_);

	// the following works only for the initialized types, since the table types
	// become connected during initialization
	
	const RowType *rt1 = tt1->rowType();
	const RowType *rt2 = tt2->rowType();
	if (rt1 == NULL || rt2 == NULL)
		// without the row type use an exact match
		return key_->equals(pit->key_);

	// check that the key matches the same fields by index
	int nf = key_->size();
	for (int i = 0; i < nf; i++) {
		int trans1 = rt1->findIdx((*key_)[i]);
		int trans2 = rt2->findIdx((*pit->key_)[i]);
		if (trans1 != trans2 || trans1 < 0)
			return false;
	}
	return true;
}

void HashedIndexType::printTo(string &res, const string &indent, const string &subindent) const
{
	res.append("index HashedIndex(");
	if (key_) {
		for (NameSet::iterator i = key_->begin(); i != key_->end(); ++i) {
			res.append(*i);
			res.append(", "); // extra comma after last field doesn't hurt
		}
	}
	res.append(")");
	printSubelementsTo(res, indent, subindent);
}

IndexType *HashedIndexType::copy(bool flat) const
{
	return new HashedIndexType(*this, flat);
}

IndexType *HashedIndexType::deepCopy(HoldRowTypes *holder) const
{
	return new HashedIndexType(*this, holder);
}

void HashedIndexType::initialize()
{
	if (isInitialized())
		return; // nothing to do
	initialized_ = true;

	errors_ = new Errors;

	rhOffset_ = tabtype_->rhType()->allocate(sizeof(RhSection));

	// find the fields
	const RowType *rt = tabtype_->rowType();
	int n = key_->size();
	keyFld_.resize(n);
	for (int i = 0; i < n; i++) {
		int idx = rt->findIdx((*key_)[i]);
		if (idx < 0) {
			errors_.f("can not find the key field '%s'", (*key_)[i].c_str());
		}
		keyFld_[i] = idx;
	}
	// XXX should it check that the fields don't repeat?
	
	less_ = new Less(tabtype_->rowType(), rhOffset_, keyFld_);
}

Index *HashedIndexType::makeIndex(const TableType *tabtype, Table *table) const
{
	if (!isInitialized() 
	|| errors_->hasError())
		return NULL; 
	// no need to report the errors, so can just use the same less_,
	// without creating a copy with the table pointer
	if (nested_.empty())
		return new TreeIndex(tabtype, table, this, less_);
	else
		return new TreeNestedIndex(tabtype, table, this, less_);
}

void HashedIndexType::initRowHandleSection(RowHandle *rh) const
{
	Hash::Value hash = Hash::basis_;

	int nf = keyFld_.size();
	const RowType *rt = tabtype_->rowType();
	for (int i = 0; i < nf; i++) {
		int idx = keyFld_[i];
		const char *v;
		intptr_t len;

		rt->getField(rh->getRow(), idx, v, len);
		hash = Hash::append(hash, v, len);
	}

	RhSection *rs = rh->get<RhSection>(rhOffset_);
	// initialize the iterator by calling its constructor
	new(rs) RhSection;
	rs->hash_ = hash;
}

void HashedIndexType::clearRowHandleSection(RowHandle *rh) const
{ 
	// clear the iterator by calling its destructor
	RhSection *rs = rh->get<RhSection>(rhOffset_);
	rs->~RhSection();
}

void HashedIndexType::copyRowHandleSection(RowHandle *rh, const RowHandle *fromrh) const
{
	RhSection *rs = rh->get<RhSection>(rhOffset_);
	RhSection *fromrs = fromrh->get<RhSection>(rhOffset_);
	
	// initialize the iterator by calling its constructor inside RhSection constructor
	new(rs) RhSection(*fromrs);
}

}; // TRICEPS_NS
