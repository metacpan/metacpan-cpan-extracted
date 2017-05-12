//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
// The encapsulation of Perl compare function for the sorted index.

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "TricepsPerl.h"
#include "PerlCallback.h"
#include "PerlSortCondition.h"

namespace TRICEPS_NS
{
namespace TricepsPerl 
{

PerlSortCondition::PerlSortCondition(const char *sortName, Onceref<PerlCallback> cbInit, Onceref<PerlCallback> cbCompare) :
	cbInitialize_(cbInit), 
	cbCompare_(cbCompare),
	initialized_(false),
	svRowType_(NULL),
	tabType_(NULL),
	name_(sortName)
{ }

// always makes an uninitialized copy!
PerlSortCondition::PerlSortCondition(const PerlSortCondition &other) :
	cbInitialize_(other.cbInitialize_), 
	cbCompare_(other.cbCompare_),
	initialized_(false),
	svRowType_(NULL),
	tabType_(NULL),
	name_(other.name_) // name stays the same!
{ }

PerlSortCondition::PerlSortCondition(const PerlSortCondition &other, HoldRowTypes *holder) :
	cbInitialize_(other.cbInitialize_->deepCopy()), 
	cbCompare_(other.cbCompare_->deepCopy()),
	initialized_(false),
	svRowType_(NULL),
	tabType_(NULL),
	name_(other.name_), // name stays the same!
	hrt_(holder)
{ }

PerlSortCondition::PerlSortCondition(const PerlSortCondition *other, Table *t) :
	SortedIndexCondition(other, t),
	cbInitialize_(other->cbInitialize_), 
	cbCompare_(other->cbCompare_),
	initialized_(other->initialized_),
	svRowType_(other->svRowType_),
	tabType_(other->tabType_),
	name_(other->name_)
{
	if (svRowType_ != NULL)
		SvREFCNT_inc(svRowType_);
}

PerlSortCondition::~PerlSortCondition()
{
	if (svRowType_ != NULL)
		SvREFCNT_dec(svRowType_);
}


bool PerlSortCondition::equals(const SortedIndexCondition *sc) const
{
	const PerlSortCondition *psc = dynamic_cast<const PerlSortCondition *>(sc);

	// XXX this means that it may differ before and after initialization
	return name_ == psc->name_
		&& callbackEquals(cbInitialize_, psc->cbInitialize_)
		&& callbackEquals(cbCompare_, psc->cbCompare_);
}

bool PerlSortCondition::match(const SortedIndexCondition *sc) const
{
	const PerlSortCondition *psc = dynamic_cast<const PerlSortCondition *>(sc);

	// XXX this means that it may differ before and after initialization
	return callbackEquals(cbInitialize_, psc->cbInitialize_)
		&& callbackEquals(cbCompare_, psc->cbCompare_);
}

void PerlSortCondition::printTo(string &res, const string &indent, const string &subindent) const
{
	res.append("PerlSortedIndex(");
	res.append(name_);
	res.append(")");
}

SortedIndexCondition *PerlSortCondition::copy() const
{
	return new PerlSortCondition(*this);
}

SortedIndexCondition *PerlSortCondition::deepCopy(HoldRowTypes *holder) const
{
	return new PerlSortCondition(*this, holder);
}

TreeIndexType::Less *PerlSortCondition::tableCopy(Table *t) const
{
	return new PerlSortCondition(this, t);
}

bool PerlSortCondition::operator() (const RowHandle *r1, const RowHandle *r2) const
{
	dSP;

	if (cbCompare_.isNull())
		return false; // should never happen but just in case

	// the rows are passed to Perl as Rows, not RowHandles, because
	// wrapping the RowHandle requires a table pointer which is not available
	WrapRow *wr1 = new WrapRow(rt_, const_cast<Row *>(r1->getRow()));
	SV *svr1 = newSV(0);
	sv_setref_pv(svr1, "Triceps::Row", (void *)wr1);

	WrapRow *wr2 = new WrapRow(rt_, const_cast<Row *>(r2->getRow()));
	SV *svr2 = newSV(0);
	sv_setref_pv(svr2, "Triceps::Row", (void *)wr2);

	PerlCallbackStartCall(cbCompare_);
	XPUSHs(svr1);
	XPUSHs(svr2);

	SV *svrcode = NULL;
	PerlCallbackDoCallScalar(cbCompare_, svrcode);

	SvREFCNT_dec(svr1);
	SvREFCNT_dec(svr2);

	bool result = false; // the safe default, collapses all keys into one

	if (SvTRUE(ERRSV)) {
		Erref err;
		err.f("Error in PerlSortedIndex(%s) comparator: %s", 
			name_.c_str(), SvPV_nolen(ERRSV));
		// XXX print the source code of comparator is available
		table_->setStickyError(err);
	} else if (svrcode == NULL) {
		Erref err;
		err.f("Error in PerlSortedIndex(%s) comparator: comparator returned no value", 
			name_.c_str());
		// XXX print the source code of comparator is available
		table_->setStickyError(err);
	} else if (!SvIOK(svrcode)) {
		Erref err;
		err.f("Error in PerlSortedIndex(%s) comparator: comparator returned a non-integer value '%s'", 
			name_.c_str(), SvPV_nolen(svrcode));
		// XXX print the source code of comparator is available
		table_->setStickyError(err);
	} else {
		result = (SvIV(svrcode) < 0); // the Less
	}

	if (svrcode != NULL)
		SvREFCNT_dec(svrcode);
	return result;
}

void PerlSortCondition::initialize(Erref &errors, TableType *tabtype, SortedIndexType *indtype)
{
	if (initialized_)
		return; // skip the second initialization

	dSP;

	tabType_ = tabtype;

	// save the wrapped row type in any case
	if (svRowType_ != NULL)
		SvREFCNT_dec(svRowType_);
	WrapRowType *wrowt = new WrapRowType(const_cast<RowType *>(rt_.get()));
	svRowType_ = newSV(0);
	sv_setref_pv(svRowType_, "Triceps::RowType", (void *)wrowt);

	Erref errInit, errComp;

	if (!cbInitialize_.isNull()) {
		cbInitialize_->initialize(hrt_);
		errInit = cbInitialize_->getErrors();
		errors.fAppend(errInit, "PerlSortedIndex(%s) initialize function is not compatible with multithreading:", name_.c_str());
	}
	if (!cbCompare_.isNull()) {
		cbCompare_->initialize(hrt_);
		errComp = cbCompare_->getErrors();
		errors.fAppend(errComp, "PerlSortedIndex(%s) compare function is not compatible with multithreading:", name_.c_str());
	}

	if (errInit->hasError() ||  errComp->hasError()) {
		return; // no point in going further
	}

	if (!cbInitialize_.isNull()) {
		WrapTableType *wtabt = new WrapTableType(tabtype);
		SV *svtabt = newSV(0);
		sv_setref_pv(svtabt, "Triceps::TableType", (void *)wtabt);

		WrapIndexType *widxt = new WrapIndexType(indtype);
		SV *svidxt = newSV(0);
		sv_setref_pv(svidxt, "Triceps::IndexType", (void *)widxt);

		PerlCallbackStartCall(cbInitialize_);
		XPUSHs(svtabt);
		XPUSHs(svidxt);
		XPUSHs(svRowType_);

		SV *sverrmsg = NULL;
		PerlCallbackDoCallScalar(cbInitialize_, sverrmsg);

		// this calls the DELETE methods on wrappers
		SvREFCNT_dec(svtabt);
		SvREFCNT_dec(svidxt);

		if (sverrmsg != NULL && SvTRUE(sverrmsg)) {
			errors->appendMultiline(true, SvPV_nolen(sverrmsg));
			return;
		}

		if (SvTRUE(ERRSV)) {
			errors->appendMultiline(true, SvPV_nolen(ERRSV));
			return;
		}
	}

	// the comparator must be set by now, or it's an error
	if (cbCompare_.isNull()) {
		errors->appendMsg(true, "the mandatory comparator Perl function is not set by PerlSortedIndex(" + name_ + ")");
	}

	hrt_ = NULL; // its work is done
	initialized_ = true;
}

bool PerlSortCondition::setComparator(Onceref<PerlCallback> cbComparator)
{
	if (initialized_)
		return false;
	cbCompare_ = cbComparator;
	return true;
}


}; // Triceps::TricepsPerl
}; // Triceps
