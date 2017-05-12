//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// An index that implements a unique primary key with an explicit sort order.

#include <type/SortedIndexType.h>
#include <type/TableType.h>
#include <table/TreeIndex.h>
#include <table/TreeNestedIndex.h>
#include <table/Table.h>
#include <string.h>
#include <typeinfo>

namespace TRICEPS_NS {

//////////////////////////// SortedIndexCondition /////////////////////////

void SortedIndexCondition::initialize(Erref &errors, TableType *tabtype, SortedIndexType *indtype)
{ }

const NameSet *SortedIndexCondition::getKey() const
{
	return NULL; // no key, yet
}

size_t SortedIndexCondition::sizeOfRhSection() const
{
	return sizeof(TreeIndexType::BasicRhSection);
}

void SortedIndexCondition::initRowHandleSection(RowHandle *rh) const
{
	TreeIndexType::BasicRhSection *rs = rh->get<TreeIndexType::BasicRhSection>(rhOffset_);
	// initialize the iterator by calling its constructor in the placement
	// (at this point rh->getRow() can be used to get the row data)
	new(rs) TreeIndexType::BasicRhSection;
}

void SortedIndexCondition::clearRowHandleSection(RowHandle *rh) const
{
	// clear the iterator by calling its destructor
	typedef TreeIndexType::BasicRhSection RhSection; // to mate the ~ syntax for destructor work
	RhSection *rs = rh->get<RhSection>(rhOffset_);
	rs->~RhSection();
}

void SortedIndexCondition::copyRowHandleSection(RowHandle *rh, const RowHandle *fromrh) const
{
	TreeIndexType::BasicRhSection *rs = rh->get<TreeIndexType::BasicRhSection>(rhOffset_);
	TreeIndexType::BasicRhSection *fromrs = fromrh->get<TreeIndexType::BasicRhSection>(rhOffset_);
	// initialize the iterator by calling its copy constructor inside the placement
	new(rs) TreeIndexType::BasicRhSection(*fromrs);
}

SortedIndexCondition *SortedIndexCondition::deepCopy(HoldRowTypes *holder) const
{
	return copy();
}

//////////////////////////// SortedIndexType /////////////////////////

SortedIndexType::SortedIndexType(Onceref<SortedIndexCondition> sc) :
	TreeIndexType(IT_SORTED),
	sc_(sc)
{ 
	assert(sc_.get() != NULL);
}

SortedIndexType::SortedIndexType(const SortedIndexType &orig, bool flat) :
	TreeIndexType(orig, flat),
	sc_(orig.sc_->copy())
{ }

SortedIndexType::SortedIndexType(const SortedIndexType &orig, HoldRowTypes *holder) :
	TreeIndexType(orig, holder),
	sc_(orig.sc_->deepCopy(holder))
{ }

bool SortedIndexType::equals(const Type *t) const
{
	if (this == t)
		return true; // self-comparison, shortcut

	if (!IndexType::equals(t))
		return false;
	
	const SortedIndexType *pit = static_cast<const SortedIndexType *>(t);

	if (sc_ == pit->sc_)
		return true;
	if (typeid( *(sc_.get()) ) != typeid( *(pit->sc_.get()) ))
		return false;

	return sc_->equals(pit->sc_);
}

bool SortedIndexType::match(const Type *t) const
{
	if (this == t)
		return true; // self-comparison, shortcut

	if (!IndexType::match(t))
		return false;
	
	const SortedIndexType *pit = static_cast<const SortedIndexType *>(t);

	if (sc_ == pit->sc_)
		return true;
	if (typeid( *(sc_.get()) ) != typeid( *(pit->sc_.get()) ))
		return false;

	return sc_->match(pit->sc_);
}

void SortedIndexType::printTo(string &res, const string &indent, const string &subindent) const
{
	res.append("index ");
	sc_->printTo(res, indent, subindent);
	printSubelementsTo(res, indent, subindent);
}

const NameSet *SortedIndexType::getKey() const
{
	return sc_->getKey();
}

IndexType *SortedIndexType::copy(bool flat) const
{
	return new SortedIndexType(*this, flat);
}

IndexType *SortedIndexType::deepCopy(HoldRowTypes *holder) const
{
	return new SortedIndexType(*this, holder);
}

void SortedIndexType::initialize()
{
	if (isInitialized())
		return; // nothing to do
	initialized_ = true;

	errors_ = new Errors;

	// pass the buck to the sorting condition
	const RowType *rt = tabtype_->rowType();
	sc_->setRowType(rt);
	sc_->initialize(errors_, tabtype_, this);
	if (!errors_->hasError()) {
		rhOffset_ = tabtype_->rhType()->allocate(sc_->sizeOfRhSection());
		sc_->setRhOffset(rhOffset_);
	}
}

Index *SortedIndexType::makeIndex(const TableType *tabtype, Table *table) const
{
	if (!isInitialized() 
	|| errors_->hasError())
		return NULL; 

	// give the index a custom copy of the comparator that can report
	// errors to the table
	TreeIndexType::Less *less = sc_->tableCopy(table);
	if (nested_.empty())
		return new TreeIndex(tabtype, table, this, less);
	else
		return new TreeNestedIndex(tabtype, table, this, less);
}

void SortedIndexType::initRowHandleSection(RowHandle *rh) const
{
	sc_->initRowHandleSection(rh);
}

void SortedIndexType::clearRowHandleSection(RowHandle *rh) const
{ 
	sc_->clearRowHandleSection(rh);
}

void SortedIndexType::copyRowHandleSection(RowHandle *rh, const RowHandle *fromrh) const
{
	sc_->copyRowHandleSection(rh, fromrh);
}

}; // TRICEPS_NS
