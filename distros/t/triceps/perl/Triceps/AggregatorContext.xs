//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
// The context for an aggregator handler call.

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "TricepsPerl.h"
#include "WrapAggregatorContext.h"

// The idea here is to combine multiple C++ structures that are used only in
// an aggregator handler call into a insgle Perl object, thus simplifying the
// API for the Perl aggregators.

namespace TRICEPS_NS
{
namespace TricepsPerl 
{

WrapMagic magicWrapAggregatorContext = { "AggCtx" };

}; // Triceps::TricepsPerl
}; // Triceps

MODULE = Triceps::AggregatorContext		PACKAGE = Triceps::AggregatorContext
###################################################################################

int
CLONE_SKIP(...)
	CODE:
		RETVAL = 1;
	OUTPUT:
		RETVAL

#// can not use the common typemap, because the destruction can be legally
#// called on an invalidated object, which would not pass the typemap
void
DESTROY(SV *selfsv)
	CODE:
		WrapAggregatorContext *self;

		if( sv_isobject(selfsv) && (SvTYPE(SvRV(selfsv)) == SVt_PVMG) ) {
			self = (WrapAggregatorContext *)SvIV((SV*)SvRV( selfsv ));
			if (self == 0 || self->badMagic()) {
				warn( "Triceps::AggregatorContext::DESTROY: self has an incorrect magic for WrapAggregatorContext" );
				XSRETURN_UNDEF; // just an early return
			}
		} else{
			warn( "Triceps::AggregatorContext::DESTROY: self is not a blessed SV reference to WrapAggregatorContext" );
			XSRETURN_UNDEF; // just an early return
		}
		// warn("AggregatorContext %p destroyed!", self);
		delete self;

#// get the number of rows in the group
int
groupSize(WrapAggregatorContext *self)
	CODE:
		clearErrMsg();
		RETVAL = self->getParentIdxType()->groupSize(self->getGroupHandle());
	OUTPUT:
		RETVAL

#// get the row type of the result
WrapRowType *
resultType(WrapAggregatorContext *self)
	CODE:
		clearErrMsg();

		// for casting of return value
		static char CLASS[] = "Triceps::RowType";
		RETVAL = new WrapRowType(const_cast<RowType *>(self->getGadget()->getLabel()->getType()));
	OUTPUT:
		RETVAL


#// iteration on the group
#// RowHandle with NULL pointer in it is used for the end-iterator

WrapRowHandle *
begin(WrapAggregatorContext *self)
	CODE:
		static char CLASS[] = "Triceps::RowHandle";

		clearErrMsg();
		Table *t = self->getTable();
		Index *idx = self->getIndex();
		RETVAL = new WrapRowHandle(t, idx->begin());
	OUTPUT:
		RETVAL
		
WrapRowHandle *
next(WrapAggregatorContext *self, WrapRowHandle *wcur)
	CODE:
		static char CLASS[] = "Triceps::RowHandle";

		RETVAL = NULL; // shut up the warning
		try { do {
			clearErrMsg();
			Table *t = self->getTable();
			Index *idx = self->getIndex();
			RowHandle *cur = wcur->get(); // NULL is OK

			static char funcName[] =  "Triceps::AggregatorContext::next";
			if (wcur->ref_.getTable() != t) {
				throw TRICEPS_NS::Exception(strprintf("%s: row argument is a RowHandle in a wrong table %s",
					funcName, wcur->ref_.getTable()->getName().c_str()), false);
			}

			RETVAL = new WrapRowHandle(t, idx->next(cur));
		} while(0); } TRICEPS_CATCH_CROAK;
	OUTPUT:
		RETVAL
		
WrapRowHandle *
last(WrapAggregatorContext *self)
	CODE:
		static char CLASS[] = "Triceps::RowHandle";

		clearErrMsg();
		Table *t = self->getTable();
		Index *idx = self->getIndex();
		RETVAL = new WrapRowHandle(t, idx->last());
	OUTPUT:
		RETVAL
		
#// translation to the group in another index: can be done in Perl
#// but more efficient and easier to push it into C++
WrapRowHandle *
beginIdx(WrapAggregatorContext *self, WrapIndexType *widx)
	CODE:
		static char CLASS[] = "Triceps::RowHandle";

		RETVAL = NULL; // shut up the warning
		try { do {
			clearErrMsg();
			Table *t = self->getTable();
			Index *myidx = self->getIndex();

			RowHandle *sample = myidx->begin();
			if (sample == NULL) {
				RETVAL = new WrapRowHandle(t, NULL);
			} else {
				IndexType *idx = widx->get();

				static char funcName[] =  "Triceps::AggregatorContext::beginIdx";
				if (idx->getTabtype() != t->getType()) {
					throw TRICEPS_NS::Exception(strprintf("%s: indexType argument does not belong to table's type", funcName), false);
				}
				RETVAL = new WrapRowHandle(t, t->firstOfGroupIdx(idx, sample));
			}
		} while(0); } TRICEPS_CATCH_CROAK;
	OUTPUT:
		RETVAL

#// translation to the group in another index: can be done in Perl
#// but more efficient and easier to push it into C++
WrapRowHandle *
endIdx(WrapAggregatorContext *self, WrapIndexType *widx)
	CODE:
		static char CLASS[] = "Triceps::RowHandle";

		RETVAL = NULL; // shut up the warning
		try { do {
			clearErrMsg();
			Table *t = self->getTable();
			Index *myidx = self->getIndex();

			RowHandle *sample = myidx->begin();
			if (sample == NULL) {
				RETVAL = new WrapRowHandle(t, NULL);
			} else {
				IndexType *idx = widx->get();

				static char funcName[] =  "Triceps::AggregatorContext::beginIdx";
				if (idx->getTabtype() != t->getType()) {
					throw TRICEPS_NS::Exception(strprintf("%s: indexType argument does not belong to table's type", funcName), false);
				}
				RETVAL = new WrapRowHandle(t, t->nextGroupIdx(idx, sample));
			}
		} while(0); } TRICEPS_CATCH_CROAK;
	OUTPUT:
		RETVAL

#// translation to the group in another index: can be done in Perl
#// but more efficient and easier to push it into C++
WrapRowHandle *
lastIdx(WrapAggregatorContext *self, WrapIndexType *widx)
	CODE:
		static char CLASS[] = "Triceps::RowHandle";

		RETVAL = NULL; // shut up the warning
		try { do {
			clearErrMsg();
			Table *t = self->getTable();
			Index *myidx = self->getIndex();

			RowHandle *sample = myidx->begin();
			if (sample == NULL) {
				RETVAL = new WrapRowHandle(t, NULL);
			} else {
				IndexType *idx = widx->get();

				static char funcName[] =  "Triceps::AggregatorContext::lastIdx";
				if (idx->getTabtype() != t->getType()) {
					throw TRICEPS_NS::Exception(strprintf("%s: indexType argument does not belong to table's type", funcName), false);
				}
				RETVAL = new WrapRowHandle(t, t->lastOfGroupIdx(idx, sample));
			}
		} while(0); } TRICEPS_CATCH_CROAK;
	OUTPUT:
		RETVAL

#// returns 1 on success, undef on error;
#// enqueueing mode is taken from the aggregator gadget
int
send(WrapAggregatorContext *self, SV *opcode, WrapRow *row)
	CODE:
		static char funcName[] =  "Triceps::AggregatorContext::send";

		try { do {
			clearErrMsg();
			Label *lab = self->getGadget()->getLabel();
			const RowType *lt = lab->getType();
			const RowType *rt = row->ref_.getType();
			Row *r = row->ref_.get();

			if ((lt != rt) && !lt->match(rt)) {
				throw TRICEPS_NS::Exception(
					strprintf("%s: row types do not match\n  Label:\n    ", funcName)
						+ lt->print("    ") + "\n  Row:\n    " + rt->print("    "),
					false
				);
			}

			Rowop::Opcode op = parseOpcode(funcName, opcode); // may throw

			self->getGadget()->sendDelayed(self->getDest(), r, op);
		} while(0); } TRICEPS_CATCH_CROAK;

		RETVAL = 1;
	OUTPUT:
		RETVAL
