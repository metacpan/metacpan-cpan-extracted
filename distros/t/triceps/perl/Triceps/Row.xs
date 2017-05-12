//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
// The wrapper for Row.

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "TricepsPerl.h"

MODULE = Triceps::Row		PACKAGE = Triceps::Row
###################################################################################

BOOT:
// fprintf(stderr, "DEBUG Row items=%d sp=%p mark=%p\n", items, sp, mark);

int
CLONE_SKIP(...)
	CODE:
		RETVAL = 1;
	OUTPUT:
		RETVAL

void
DESTROY(WrapRow *self)
	CODE:
		// warn("Row destroyed!");
		delete self;

#// for debugging, make a hex dump
char *
hexdump(WrapRow *self)
	CODE:
		clearErrMsg();
		string dump;
		const RowType *t = self->ref_.getType();
		Row *r = self->ref_.get();
		t->hexdumpRow(dump, r);
		RETVAL = (char *)dump.c_str();
	OUTPUT:
		RETVAL

#// convert to an array of name-value pairs, suitable for setting into a hash
SV *
toHash(WrapRow *self)
	PPCODE:
		clearErrMsg();
		const RowType *t = self->ref_.getType();
		Row *r = self->ref_.get();
		const RowType::FieldVec &fld = t->fields();
		int nf = fld.size();

		for (int i = 0; i < nf; i++) {
			XPUSHs(sv_2mortal(newSVpvn(fld[i].name_.c_str(), fld[i].name_.size())));
			
			const char *data;
			intptr_t dlen;
			bool notNull = t->getField(r, i, data, dlen);
			XPUSHs(sv_2mortal(bytesToVal(fld[i].type_->getTypeId(), fld[i].arsz_, notNull, data, dlen, fld[i].name_.c_str())));
		}

#// convert to an array of data values, like CSV
SV *
toArray(WrapRow *self)
	PPCODE:
		clearErrMsg();
		const RowType *t = self->ref_.getType();
		Row *r = self->ref_.get();
		const RowType::FieldVec &fld = t->fields();
		int nf = fld.size();

		for (int i = 0; i < nf; i++) {
			const char *data;
			intptr_t dlen;
			bool notNull = t->getField(r, i, data, dlen);
			XPUSHs(sv_2mortal(bytesToVal(fld[i].type_->getTypeId(), fld[i].arsz_, notNull, data, dlen, fld[i].name_.c_str())));
		}

#// copy the row and modify the specified fields when copying
WrapRow *
copymod(WrapRow *self, ...)
	CODE:
		static char funcName[] =  "Triceps::Row::copymod";
		// for casting of return value
		static char CLASS[] = "Triceps::Row";
		RETVAL = NULL; // shut up the warning
		try { do {
			clearErrMsg();
			const RowType *rt = self->ref_.getType();
			Row *r = self->ref_.get();

			// The arguments come in pairs fieldName => value;
			// the value may be either a simple value that will be
			// cast to the right type, or a reference to a list of values.
			// The uint8 and string are converted from Perl strings
			// (the difference for now is that string is 0-terminated)
			// and can not have lists.

			if (items % 2 != 1) {
				throw Exception::f("Usage: %s(RowType, [fieldName, fieldValue, ...]), names and types must go in pairs", funcName);
			}

			// parse data to create a copy
			FdataVec fields;
			rt->splitInto(r, fields);

			// now override the modified fields
			// this code is copied from RowType::makerow_hs
			vector<Autoref<EasyBuffer> > bufs;
			for (int i = 1; i < items; i += 2) {
				const char *fname = (const char *)SvPV_nolen(ST(i));
				int idx  = rt->findIdx(fname);
				if (idx < 0) {
					throw Exception::f("%s: attempting to set an unknown field '%s'", funcName, fname);
				}
				const RowType::Field &finfo = rt->fields()[idx];

				if (!SvOK(ST(i+1))) { // undef translates to null
					fields[idx].setNull();
				} else {
					if (SvROK(ST(i+1)) && finfo.arsz_ < 0) {
						throw Exception::f("%s: attempting to set an array into scalar field '%s'", funcName, fname);
					}
					EasyBuffer *d = valToBuf(finfo.type_->getTypeId(), ST(i+1), fname); // may throw
					bufs.push_back(d); // remember for cleaning

					fields[idx].setPtr(true, d->data_, d->size_);
				}
			}
			RETVAL = new WrapRow(rt, rt->makeRow(fields));
		} while(0); } TRICEPS_CATCH_CROAK;
	OUTPUT:
		RETVAL

#// get the value of one field by name
SV *
get(WrapRow *self, char *fname)
	PPCODE:
		static char funcName[] =  "Triceps::Row::get";
		try { do {
			clearErrMsg();
			const RowType *t = self->ref_.getType();
			Row *r = self->ref_.get();
			const RowType::FieldVec &fld = t->fields();

			int i = t->findIdx(fname);
			if ( i < 0 )
				throw Exception::f("%s: unknown field '%s'", funcName, fname);

			const char *data;
			intptr_t dlen;
			bool notNull = t->getField(r, i, data, dlen);
			XPUSHs(sv_2mortal(bytesToVal(fld[i].type_->getTypeId(), fld[i].arsz_, notNull, data, dlen, fld[i].name_.c_str())));
		} while(0); } TRICEPS_CATCH_CROAK;

#// get the type of the row
WrapRowType*
getType(WrapRow *self)
	CODE:
		clearErrMsg();
		const RowType *t = self->ref_.getType();

		// for casting of return value
		static char CLASS[] = "Triceps::RowType";
		RETVAL = new WrapRowType(const_cast<RowType *>(t));
	OUTPUT:
		RETVAL

#// check whether both refs point to the same object
int
same(WrapRow *self, WrapRow *other)
	CODE:
		clearErrMsg();
		Row *r1 = self->get();
		Row *r2 = other->get();
		RETVAL = (r1 == r2);
	OUTPUT:
		RETVAL

#// check if the row is empty (i.e. all fields are NULL)
int
isEmpty(WrapRow *self)
	CODE:
		clearErrMsg();
		RETVAL = self->ref_.getType()->isRowEmpty(self->ref_.get())? 1 : 0;
	OUTPUT:
		RETVAL
