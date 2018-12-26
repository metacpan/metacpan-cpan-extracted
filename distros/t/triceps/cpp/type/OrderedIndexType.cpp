//
// (C) Copyright 2011-2018 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// An index that implements a unique primary key with explicit order.

#include <type/OrderedIndexType.h>
#include <type/TableType.h>
#include <table/TreeIndex.h>
#include <table/TreeNestedIndex.h>
#include <table/Table.h>
#include <string.h>

namespace TRICEPS_NS {

//////////////////////////// OrderedIndexType::Less  /////////////////////////

OrderedIndexType::Less::Less(const RowType *rt, intptr_t rhOffset, const vector<int32_t> &keyFld, const vector<bool> &asc)  :
	TreeIndexType::Less(rt),
	keyFld_(keyFld),
	asc_(asc),
	rhOffset_(rhOffset)
{
	assert(keyFld_.size() == asc_.size());
}

OrderedIndexType::Less::Less(const Less *other, Table *t) :
	TreeIndexType::Less(other, t),
	keyFld_(other->keyFld_),
	asc_(other->asc_),
	rhOffset_(other->rhOffset_)
{ }

TreeIndexType::Less *OrderedIndexType::Less::tableCopy(Table *t) const
{
	return new Less(this, t);
}

bool OrderedIndexType::Less::operator() (const RowHandle *r1, const RowHandle *r2) const 
{
	int nf = keyFld_.size();
	for (int i = 0; i < nf; i++) {
		int idx = keyFld_[i];
		bool notNull1, notNull2;
		const char *v1, *v2;
		intptr_t len1, len2;

		notNull1 = rt_->getField(r1->getRow(), idx, v1, len1);
		notNull2 = rt_->getField(r2->getRow(), idx, v2, len2);

		// check for nulls
		if (!notNull1){
			if (notNull2)
				return asc_[i];
		} else {
			if (!notNull2)
				return !asc_[i];
		}

		const RowType::Field *fld = &rt_->fields()[idx];
		const SimpleType *ft = static_cast<const SimpleType*>(fld->type_.get());

		if (fld->arsz_ == RowType::Field::AR_SCALAR) {
			int result = ft->cmpValue(v1, len1, v2, len2);
			if (result != 0) {
				if (result < 0)
					return asc_[i];
				else
					return !asc_[i];
			}
		} else {
			intptr_t step = ft->getSize();
			while (len1 > 0 && len2 > 0) { // assume that the lengths are correct
				int result = ft->cmpValue(v1, len1, v2, len2);
				if (result != 0) {
					if (result < 0)
						return asc_[i];
					else
						return !asc_[i];
				}

				len1 -= step; v1 += step;
				len2 -= step; v2 += step;
			}
			if (len1 != len2) {
				if (len1 < len2)
					return asc_[i];
				else
					return !asc_[i];
			}
		}
	}

	return false; // gets here only on equal values
}

//////////////////////////// OrderedIndexType /////////////////////////

OrderedIndexType::OrderedIndexType(NameSet *key) :
	TreeIndexType(IT_ORDERED)
{
	setKey(key);
}

OrderedIndexType::OrderedIndexType(const OrderedIndexType &orig, bool flat) :
	TreeIndexType(orig, flat),
	asc_(orig.asc_)
{
	if (!orig.key_.isNull()) {
		key_ = new NameSet(*orig.key_);
	}
	if (!orig.fullKey_.isNull()) {
		fullKey_ = new NameSet(*orig.fullKey_);
	}
}

OrderedIndexType::OrderedIndexType(const OrderedIndexType &orig, HoldRowTypes *holder) :
	TreeIndexType(orig, holder),
	asc_(orig.asc_)
{
	if (!orig.key_.isNull()) {
		key_ = new NameSet(*orig.key_);
	}
	if (!orig.fullKey_.isNull()) {
		fullKey_ = new NameSet(*orig.fullKey_);
	}
}

OrderedIndexType *OrderedIndexType::setKey(NameSet *key)
{
	if (initialized_) {
		Autoref<OrderedIndexType> cleaner = this;
		throw Exception::fTrace("Attempted to set the key on an initialized Ordered index type");
	}
	fullKey_ = key;
	// Generate the list of field names in the key.
	key_ = new NameSet;
	asc_.clear();
	for (size_t i = 0; i < fullKey_->size(); ++i) {
		const string &s = (*fullKey_)[i];
		if (s[0] == '!') {
			key_->push_back(s.substr(1));
			asc_.push_back(false);
		} else {
			key_->push_back(s);
			asc_.push_back(true);
		}
	}
	return this;
}

const NameSet *OrderedIndexType::getKey() const
{
	return key_;
}

const NameSet *OrderedIndexType::getKeyExpr() const
{
	return fullKey_;
}

bool OrderedIndexType::equals(const Type *t) const
{
	if (this == t)
		return true; // self-comparison, shortcut

	if (!IndexType::equals(t))
		return false;
	
	const OrderedIndexType *pit = static_cast<const OrderedIndexType *>(t);
	if ( (!fullKey_.isNull() && pit->fullKey_.isNull())
	|| (fullKey_.isNull() && !pit->fullKey_.isNull()) )
		return false;

	if (!fullKey_->equals(pit->fullKey_))
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

bool OrderedIndexType::match(const Type *t) const
{
	if (this == t)
		return true; // self-comparison, shortcut

	if (!IndexType::match(t))
		return false;
	
	const OrderedIndexType *pit = static_cast<const OrderedIndexType *>(t);
	if ( (!fullKey_.isNull() && pit->fullKey_.isNull())
	|| (fullKey_.isNull() && !pit->fullKey_.isNull()) )
		return false;

	if (fullKey_->size() != pit->fullKey_->size())
		return false;

	const TableType *tt1 = getTabtype();
	const TableType *tt2 = pit->getTabtype();

	if (tt1 == NULL || tt2 == NULL)
		// without the table type, the row type is not known, so use an exact match
		return fullKey_->equals(pit->fullKey_);

	// the following works only for the initialized types, since the table types
	// become connected during initialization
	
	const RowType *rt1 = tt1->rowType();
	const RowType *rt2 = tt2->rowType();
	if (rt1 == NULL || rt2 == NULL)
		// without the row type use an exact match
		return fullKey_->equals(pit->fullKey_);

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

void OrderedIndexType::printTo(string &res, const string &indent, const string &subindent) const
{
	res.append("index OrderedIndex(");
	if (fullKey_) {
		for (NameSet::iterator i = fullKey_->begin(); i != fullKey_->end(); ++i) {
			res.append(*i);
			res.append(", "); // extra comma after last field doesn't hurt
		}
	}
	res.append(")");
	printSubelementsTo(res, indent, subindent);
}

IndexType *OrderedIndexType::copy(bool flat) const
{
	return new OrderedIndexType(*this, flat);
}

IndexType *OrderedIndexType::deepCopy(HoldRowTypes *holder) const
{
	return new OrderedIndexType(*this, holder);
}

void OrderedIndexType::initialize()
{
	if (isInitialized())
		return; // nothing to do
	initialized_ = true;

	errors_ = new Errors;

	rhOffset_ = tabtype_->rhType()->allocate(sizeof(BasicRhSection));

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
	// XXX if non-simple-type fields will be allowed, need some smarter handling or at least a check
	
	less_ = new Less(tabtype_->rowType(), rhOffset_, keyFld_, asc_);
}

Index *OrderedIndexType::makeIndex(const TableType *tabtype, Table *table) const
{
	if (!isInitialized() 
	|| errors_.hasError())
		return NULL; 
	// no need to report the errors, so can just use the same less_,
	// without creating a copy with the table pointer
	if (nested_.empty())
		return new TreeIndex(tabtype, table, this, less_);
	else
		return new TreeNestedIndex(tabtype, table, this, less_);
}

void OrderedIndexType::initRowHandleSection(RowHandle *rh) const
{
	BasicRhSection *rs = rh->get<BasicRhSection>(rhOffset_);
	// initialize the iterator by calling its constructor
	new(rs) BasicRhSection;
}

void OrderedIndexType::clearRowHandleSection(RowHandle *rh) const
{ 
	// clear the iterator by calling its destructor
	BasicRhSection *rs = rh->get<BasicRhSection>(rhOffset_);
	rs->~BasicRhSection();
}

void OrderedIndexType::copyRowHandleSection(RowHandle *rh, const RowHandle *fromrh) const
{
	BasicRhSection *rs = rh->get<BasicRhSection>(rhOffset_);
	BasicRhSection *fromrs = fromrh->get<BasicRhSection>(rhOffset_);
	
	// initialize the iterator by calling its constructor inside BasicRhSection constructor
	new(rs) BasicRhSection(*fromrs);
}

}; // TRICEPS_NS
