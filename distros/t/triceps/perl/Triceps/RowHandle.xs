//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
// The wrapper for RowHandle.

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "TricepsPerl.h"

MODULE = Triceps::RowHandle		PACKAGE = Triceps::RowHandle
###################################################################################

int
CLONE_SKIP(...)
	CODE:
		RETVAL = 1;
	OUTPUT:
		RETVAL

void
DESTROY(WrapRowHandle *self)
	CODE:
		// warn("RowHandle destroyed!");
		delete self;

#// check whether both refs point to the same object
int
same(WrapRowHandle *self, WrapRowHandle *other)
	CODE:
		clearErrMsg();
		RowHandle *r1 = self->get();
		RowHandle *r2 = other->get();
		RETVAL = (r1 == r2);
	OUTPUT:
		RETVAL

#// A special thing about WrapRowHandles is that for the convenience of comparing
#// iterators, they may contain the NULL pointers. So wherever they are used, must
#// check for NULL.

WrapRow *
getRow(WrapRowHandle *self)
	CODE:
		// for casting of return value
		static char CLASS[] = "Triceps::Row";
		clearErrMsg();
		RowHandle *rh = self->get();

		try { do {
			if (rh == NULL) {
				throw Exception::f("Triceps::RowHandle::getRow: RowHandle is NULL");
			}
		} while(0); } TRICEPS_CATCH_CROAK;

		// XXX Should it check for row being NULL? C++ code can create that...
		RETVAL = new WrapRow(const_cast<RowType *>(self->ref_.getTable()->getRowType()), const_cast<Row *>(rh->getRow()));
	OUTPUT:
		RETVAL

WrapRow *
getRowSafe(WrapRowHandle *self)
	CODE:
		// for casting of return value
		static char CLASS[] = "Triceps::Row";
		clearErrMsg();
		RowHandle *rh = self->get();

		if (rh == NULL) {
			XSRETURN_UNDEF; // not a croak!
		}

		// XXX Should it check for row being NULL? C++ code can create that...
		RETVAL = new WrapRow(const_cast<RowType *>(self->ref_.getTable()->getRowType()), const_cast<Row *>(rh->getRow()));
	OUTPUT:
		RETVAL

int
isInTable(WrapRowHandle *self)
	CODE:
		clearErrMsg();
		RowHandle *rh = self->get();

		if (rh == NULL)
			RETVAL = 0;
		else
			RETVAL = rh->isInTable();
	OUTPUT:
		RETVAL

#// check for NULL, which means the end() iterator
int
isNull(WrapRowHandle *self)
	CODE:
		clearErrMsg();
		RowHandle *rh = self->get();
		RETVAL = (rh == NULL);
	OUTPUT:
		RETVAL

#// methods that duplicate the table's navigation, done more straightforward:
#// with the table reference taken from the WrapRowHandle

WrapRowHandle *
next(WrapRowHandle *self)
	CODE:
		static char CLASS[] = "Triceps::RowHandle";

		clearErrMsg();
		Table *t = self->ref_.getTable();
		RowHandle *cur = self->get(); // NULL is OK

		RETVAL = new WrapRowHandle(t, t->next(cur));
	OUTPUT:
		RETVAL
		
WrapRowHandle *
nextIdx(WrapRowHandle *self, WrapIndexType *widx)
	CODE:
		static char CLASS[] = "Triceps::RowHandle";
		static char funcName[] =  "Triceps::RowHandle::nextIdx";

		RETVAL = NULL; // shut up the warning
		try { do {
			clearErrMsg();
			Table *t = self->ref_.getTable();
			IndexType *idx = widx->get();
			RowHandle *cur = self->get(); // NULL is OK

			if (idx->getTabtype() != t->getType()) {
				throw TRICEPS_NS::Exception(strprintf("%s: indexType argument does not belong to table's type", funcName), false);
			}

			RETVAL = new WrapRowHandle(t, t->nextIdx(idx, cur));
		} while(0); } TRICEPS_CATCH_CROAK;
	OUTPUT:
		RETVAL
		
WrapRowHandle *
firstOfGroupIdx(WrapRowHandle *self, WrapIndexType *widx)
	CODE:
		static char CLASS[] = "Triceps::RowHandle";
		static char funcName[] =  "Triceps::RowHandle::firstOfGroupIdx";

		RETVAL = NULL; // shut up the warning
		try { do {
			clearErrMsg();
			Table *t = self->ref_.getTable();
			IndexType *idx = widx->get();
			RowHandle *cur = self->get(); // NULL is OK

			if (idx->getTabtype() != t->getType()) {
				throw TRICEPS_NS::Exception(strprintf("%s: indexType argument does not belong to table's type", funcName), false);
			}

			RETVAL = new WrapRowHandle(t, t->firstOfGroupIdx(idx, cur));
		} while(0); } TRICEPS_CATCH_CROAK;
	OUTPUT:
		RETVAL
		
WrapRowHandle *
nextGroupIdx(WrapRowHandle *self, WrapIndexType *widx)
	CODE:
		static char CLASS[] = "Triceps::RowHandle";
		static char funcName[] =  "Triceps::RowHandle::nextGroupIdx";

		RETVAL = NULL; // shut up the warning
		try { do {
			clearErrMsg();
			Table *t = self->ref_.getTable();
			IndexType *idx = widx->get();
			RowHandle *cur = self->get(); // NULL is OK

			if (idx->getTabtype() != t->getType()) {
				throw TRICEPS_NS::Exception(strprintf("%s: indexType argument does not belong to table's type", funcName), false);
			}

			RETVAL = new WrapRowHandle(t, t->nextGroupIdx(idx, cur));
		} while(0); } TRICEPS_CATCH_CROAK;
	OUTPUT:
		RETVAL
		
#// tested in Table.t
