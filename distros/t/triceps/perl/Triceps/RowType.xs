//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
// The wrapper for RowType.

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "TricepsPerl.h"

MODULE = Triceps::RowType		PACKAGE = Triceps::RowType
###################################################################################

BOOT:
// fprintf(stderr, "DEBUG RowType items=%d sp=%p mark=%p\n", items, sp, mark);

int
CLONE_SKIP(...)
	CODE:
		RETVAL = 1;
	OUTPUT:
		RETVAL

WrapRowType *
Triceps::RowType::new(...)
	CODE:
		static char funcName[] =  "Triceps::RowType::new";
		RETVAL = NULL; // shut up the warning
		try { do {
			RowType::FieldVec fld;
			RowType::Field add;

			clearErrMsg();
			if (items < 3 || items % 2 != 1) {
				throw Exception::f("Usage: %s(CLASS, fieldName, fieldType, ...), names and types must go in pairs", funcName);
			}
			for (int i = 1; i < items; i += 2) {
				const char *fname = (const char *)SvPV_nolen(ST(i));
				STRLEN ftlen;
				char *ftype = (char *)SvPV(ST(i+1), ftlen);
				if (ftlen >= 2 && ftype[ftlen-1] == ']' && ftype[ftlen-2] == '[') {
					ftype[ftlen-2] = 0;
					add.assign(fname, Type::findSimpleType(ftype), RowType::Field::AR_VARIABLE);
					ftype[ftlen-2] = '[';
				} else {
					add.assign(fname, Type::findSimpleType(ftype));
				}
				if (add.type_.isNull()) {
					throw Exception::f("%s: field '%s' has an unknown type '%s'", funcName, fname, ftype);
				}
				if (add.arsz_ != RowType::Field::AR_SCALAR && add.type_->getTypeId() == Type::TT_STRING) {
					throw Exception::f("%s: field '%s' string array type is not supported", funcName, fname);
				}
				fld.push_back(add);
			}
			Onceref<RowType> rt = new CompactRowType(fld);
			Erref err = rt->getErrors();
			if (err->hasError()) {
				throw Exception::f(err, "Triceps::RowType::new: incorrect specification:");
			}

			RETVAL = new WrapRowType(rt);
		} while(0); } 
		// the custom version of TRICEPS_CATCH_CROAK
		catch (Exception e) {
			Erref err = e.getErrors();
			Erref spec = new Errors(true);

			for (int i = 1; i < items; i += 2) {
				const char *fname = (const char *)SvPV_nolen(ST(i));
				const char *ftype = i+1 < items ? (const char *)SvPV_nolen(ST(i+1)) : "";

				spec.f("%s => %s", fname, ftype);
			}

			err->append("Triceps::RowType::new: The specification was: {", spec);
			err->appendMsg(true, "}");
			setCroakMsg(err->print());
			croakIfSet();
		}
	OUTPUT:
		RETVAL

void
DESTROY(WrapRowType *self)
	CODE:
		// warn("RowType destroyed!");
		delete self;

#// get back the type definition
SV *
getdef(WrapRowType *self)
	PPCODE:
		clearErrMsg();
		RowType *rt = self->get();

		const RowType::FieldVec &fld = rt->fields();
		int nf = fld.size();
		for (int i = 0; i < nf; i++) {
			XPUSHs(sv_2mortal(newSVpvn(fld[i].name_.c_str(), fld[i].name_.size())));
			string t = fld[i].type_->print();
			if (fld[i].arsz_ >= 0)
				t.append("[]");
			XPUSHs(sv_2mortal(newSVpvn(t.c_str(), t.size())));
		}

#// the following methods break up the type definitions for the convenience
#// of row type manipulation from Perl

#// get back the field names only (left side of the definition)
SV *
getFieldNames(WrapRowType *self)
	PPCODE:
		clearErrMsg();
		RowType *rt = self->get();

		const RowType::FieldVec &fld = rt->fields();
		int nf = fld.size();
		for (int i = 0; i < nf; i++) {
			XPUSHs(sv_2mortal(newSVpvn(fld[i].name_.c_str(), fld[i].name_.size())));
		}

#// get back the field types only (right side of the definition)
SV *
getFieldTypes(WrapRowType *self)
	PPCODE:
		clearErrMsg();
		RowType *rt = self->get();

		const RowType::FieldVec &fld = rt->fields();
		int nf = fld.size();
		for (int i = 0; i < nf; i++) {
			string t = fld[i].type_->print();
			if (fld[i].arsz_ >= 0)
				t.append("[]");
			XPUSHs(sv_2mortal(newSVpvn(t.c_str(), t.size())));
		}

#// get back the mapping of field names to their indexes in row type
#// i.e. (field0 => 0, field1 => 1, ...)
SV *
getFieldMapping(WrapRowType *self)
	PPCODE:
		clearErrMsg();
		RowType *rt = self->get();

		const RowType::FieldVec &fld = rt->fields();
		int nf = fld.size();
		for (int i = 0; i < nf; i++) {
			XPUSHs(sv_2mortal(newSVpvn(fld[i].name_.c_str(), fld[i].name_.size())));
			XPUSHs(sv_2mortal(newSViv(i)));
		}


#// the row factory, from a hash-style name-value list
#// XXX add a version that ignores unknown fields, useful for row type conversions
WrapRow *
makeRowHash(WrapRowType *self, ...)
	CODE:
		// for casting of return value
		static char CLASS[] = "Triceps::Row";
		static char funcName[] =  "Triceps::RowType::makeRowHash";
		RETVAL = NULL; // shut up the warning
		try { do {
			clearErrMsg();
			RowType *rt = self->get();

			// The arguments come in pairs fieldName => value;
			// the value may be either a simple value that will be
			// cast to the right type, or a reference to a list of values.
			// The uint8 and string are converted from Perl strings
			// (the difference for now is that string is 0-terminated)
			// and can not have lists.

			if (items % 2 != 1) {
				throw Exception::f("Usage: %s(RowType, fieldName, fieldValue, ...), names and types must go in pairs", funcName);
			}

			int nf = rt->fieldCount();
			FdataVec fields(nf);
			for (int i = 0; i < nf; i++) {
				fields[i].setNull(); // default the fields to null
			}
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

#// the row factory, from an array of values in the exact order (like CSV files),
#// filling the missing values at the end with nulls
WrapRow *
makeRowArray(WrapRowType *self, ...)
	CODE:
		// for casting of return value
		static char CLASS[] = "Triceps::Row";
		static char funcName[] =  "Triceps::RowType::makeRowArray";
		RETVAL = NULL; // shut up the warning
		try { do {
			clearErrMsg();
			RowType *rt = self->get();

			int nf = rt->fieldCount();

			if (items > nf + 1) {
				string rtp;
				rt->printTo(rtp, NOINDENT);
				throw Exception::f("%s: %d args, only %d fields in %s", funcName, items-1, nf, rtp.c_str());
			}

			FdataVec fields(nf);
			for (int i = 0; i < nf; i++) {
				fields[i].setNull(); // default the fields to null
			}
			vector<Autoref<EasyBuffer> > bufs;
			for (int i = 1; i < items; i ++) {
				const RowType::Field &finfo = rt->fields()[i-1];
				const char *fname = finfo.name_.c_str();

				if (SvOK(ST(i))) { // undef translates to null, which is already set
					if (SvROK(ST(i)) && finfo.arsz_ < 0) {
						throw Exception::f("%s: attempting to set an array into scalar field '%s'", funcName, fname);
					}
					EasyBuffer *d = valToBuf(finfo.type_->getTypeId(), ST(i), fname); // may throw
					bufs.push_back(d); // remember for cleaning

					fields[i-1].setPtr(true, d->data_, d->size_);
				}
			}
			RETVAL = new WrapRow(rt, rt->makeRow(fields));
		} while(0); } TRICEPS_CATCH_CROAK;
	OUTPUT:
		RETVAL

#// check whether both refs point to the same type object
int
same(WrapRowType *self, WrapRowType *other)
	CODE:
		clearErrMsg();
		RowType *rt = self->get();
		RowType *ort = other->get();
		RETVAL = (rt == ort);
	OUTPUT:
		RETVAL

int
equals(WrapRowType *self, WrapRowType *other)
	CODE:
		clearErrMsg();
		RowType *rt = self->get();
		RowType *ort = other->get();
		RETVAL = rt->equals(ort);
	OUTPUT:
		RETVAL

int
match(WrapRowType *self, WrapRowType *other)
	CODE:
		clearErrMsg();
		RowType *rt = self->get();
		RowType *ort = other->get();
		RETVAL = rt->match(ort);
	OUTPUT:
		RETVAL

#// print(self, [ indent, [ subindent ] ])
#//   indent - default "", undef means "print everything in a signle line
#//   subindent - default "  "
SV *
print(WrapRowType *self, ...)
	PPCODE:
		GEN_PRINT_METHOD(RowType)

