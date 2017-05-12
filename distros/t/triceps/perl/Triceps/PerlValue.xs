//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
// Representation of the Perl values that can be passed to the other threads.
//
// The XS part is really here for testing, though it might have some uses in the future.

// ###################################################################################

#include <typeinfo>
#include <map>
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "TricepsPerl.h"
#include "PerlValue.h"


using namespace TRICEPS_NS;

namespace TRICEPS_NS
{
namespace TricepsPerl 
{

WrapMagic magicWrapPerlValue = { "PlValue" };

PerlValue::PerlValue():
	choice_(UNDEF)
{ }

Erref PerlValue::parse(SV *v)
{
	static char msg[] = "to allow passing between the threads, the value must be one of undef, int, float, string, RowType, or an array or hash thereof";
	WrapRowType *wrt;
	WrapRow *wr;

	if (choice_ != UNDEF)
		return new Errors("Internal error: trying to parse another value into the same PerlValue.");

	if (!SvOK(v)) {
		// nothing to do, already an UNDEF
	} else if (SvIOK(v)) {
		choice_ = INT;
		i_ = SvIV(v);
	} else if (SvNOK(v)) {
		choice_ = FLOAT;
		f_ = SvNV(v);
	} else if (SvPOK(v)) {
		choice_ = STRING;
		STRLEN len;
		char *sv = SvPV(v, len);
		s_.assign(sv, len);
	} else if (SvROK(v)) {
		SV *ref = SvRV(v);
		if (SvTYPE(ref) == SVt_PVAV) {
			choice_ = ARRAY;
			AV *arr = (AV*)ref;
			int len = av_len(arr)+1; // av_len returns the index of last element
			v_.resize(len);
			for (int i = 0; i < len; i++) {
				v_[i] = new PerlValue;
				Erref e = v_[i]->parse(*av_fetch(arr, i, 0));
				if (e->hasError())
					return new Errors(strprintf("invalid value at array index %d:", i), e); 
			}
		} else if (SvTYPE(ref) == SVt_PVHV) {
			choice_ = HASH;
			HV *hash = (HV*)ref;
			hv_iterinit(hash);
			char *key;
			I32 keylen;
			SV *val;
			while ((val = hv_iternextsv(hash, &key, &keylen)) != NULL) {
				Autoref<PerlValue> pv = new PerlValue;

				Erref e = pv->parse(val);
				if (e->hasError())
					return new Errors(strprintf("invalid value at hash key '%s':", key), e); 

				k_.push_back(string(key, keylen));
				v_.push_back(pv);
			}
		} else if (sv_isobject(v) && SvTYPE(ref) == SVt_PVMG
		&& (wrt = (WrapRowType *)SvIV(ref)) != NULL && !wrt->badMagic()) {
			choice_ = ROW_TYPE;
			rowType_ = wrt->get();
		} else if (sv_isobject(v) && SvTYPE(ref) == SVt_PVMG
		&& (wr = (WrapRow *)SvIV(ref)) != NULL && !wr->badMagic()) {
			choice_ = ROW;
			row_ = wr->ref_;
		} else {
			return new Errors(msg);
		}
	} else {
		return new Errors(msg);
	}
	return NULL;
}

SV *PerlValue::restore(HoldRowTypes *holder) const
{
	switch(choice_) {
	case UNDEF:
	default:
		return newSV(0);
		break;
	case INT:
		return newSViv(i_);
		break;
	case FLOAT:
		return newSVnv(f_);
		break;
	case STRING:
		return newSVpv(s_.c_str(), s_.size());
		break;
	case ARRAY:
		{
			AV *arr = newAV();
			int len = v_.size();
			for (int i = 0; i < len; i++) {
				SV *elem = v_[i]->restore(holder);
				av_push(arr, elem); // this consumes the reference
			}
			return newRV_noinc((SV *)arr); // the reference gets consumed
		}
		break;
	case HASH:
		{
			HV *hash = newHV();
			int len = v_.size();
			for (int i = 0; i < len; i++) {
				SV *elem = v_[i]->restore(holder);
				const string &key = k_[i];
				hv_store(hash, key.c_str(), key.size(), elem, 0); // this consumes the reference
			}
			return newRV_noinc((SV *)hash); // the reference gets consumed
		}
		break;
	case ROW_TYPE:
		{
			SV *val = newSV(0);
			sv_setref_pv(val, "Triceps::RowType", new WrapRowType(holder->copy(rowType_)));
			return val;
		}
		break;
	case ROW:
		{
			SV *val = newSV(0);
			sv_setref_pv(val, "Triceps::Row", new WrapRow(holder->copy(row_.getType()), row_.get()));
			return val;
		}
		break;
	}
}

bool PerlValue::equals(const PerlValue *other) const
{
	if (this == other)
		return true;

	if (choice_ != other->choice_)
		return false;

	switch(choice_) {
	case UNDEF:
		return true;
		break;
	case INT:
		return (i_ == other->i_);
		break;
	case FLOAT:
		return (f_ == other->f_);
		break;
	case STRING:
		return (s_ == other->s_);
		break;
	case ARRAY:
		{
			if (v_.size() != other->v_.size())
				return false;

			int len = v_.size();
			for (int i = 0; i < len; i++) {
				if (!v_[i]->equals(other->v_[i]))
					return false;
			}
			return true;
		}
		break;
	case HASH:
		{
			if (v_.size() != other->v_.size())
				return false;

			int len = v_.size();

			// this is tricky: the keys may go in any order, so have to map them together
			typedef map<string, int> Kmap;
			Kmap kmap;
			for (int i = 0; i < len; i++) {
				kmap[k_[i]] = i;
			}

			for (int i = 0; i < len; i++) {
				Kmap::iterator it = kmap.find(other->k_[i]);
				if (it == kmap.end())
					return false; // no such key
				int j = it->second;
				if (k_[j] != other->k_[i] || !v_[j]->equals(other->v_[i]))
					return false;
			}
			return true;
		}
		break;
	case ROW_TYPE:
		return rowType_->equals(other->rowType_);
		break;
	case ROW:
		if (!row_.getType()->equals(other->row_.getType()))
			return false;
		return row_.getType()->equalRows(row_.get(), other->row_.get());
		break;
	}
	return false; // should never happen
}

PerlValue *PerlValue::make(SV *v)
{
	PerlValue *pv = new PerlValue();
	Erref e = pv->parse(v);
	if (e->hasError()) {
		delete pv;
		throw Exception(e.get(), false);
	}
	return pv;
}

}; // Triceps::TricepsPerl
}; // Triceps

MODULE = Triceps::PerlValue		PACKAGE = Triceps::PerlValue
###################################################################################

int
CLONE_SKIP(...)
	CODE:
		RETVAL = 1;
	OUTPUT:
		RETVAL

void
DESTROY(WrapPerlValue *self)
	CODE:
		PerlValue *pv = self->get();
		// warn("Perlvalue %p wrap %p destroyed!", pv, self);
		delete self;


WrapPerlValue *
Triceps::PerlValue::new(SV *arg)
	CODE:
		clearErrMsg();

		RETVAL = NULL;
		try {
			PerlValue *pv = PerlValue::make(arg);
			RETVAL = new WrapPerlValue(pv);
		} TRICEPS_CATCH_CROAK;
	OUTPUT:
		RETVAL

SV *
get(WrapPerlValue *self)
	CODE:
		clearErrMsg();

		RETVAL = NULL;
		try {
			// XS takes care of calling sv_2mortal()
			Autoref<HoldRowTypes> hrt = new HoldRowTypes();
			RETVAL = self->get()->restore(hrt);
		} TRICEPS_CATCH_CROAK;
	OUTPUT:
		RETVAL

#// check whether both refs point to the same object
int
same(WrapPerlValue *self, WrapPerlValue *other)
	CODE:
		clearErrMsg();
		RETVAL = (self->get() == other->get());
	OUTPUT:
		RETVAL

#// check whether both values are equal
int
equals(WrapPerlValue *self, WrapPerlValue *other)
	CODE:
		clearErrMsg();
		RETVAL = self->get()->equals(other->get());
	OUTPUT:
		RETVAL

