//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
// The wrapper for TableType.

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "TricepsPerl.h"
#include <type/HoldRowTypes.h>

MODULE = Triceps::TableType		PACKAGE = Triceps::TableType
###################################################################################

int
CLONE_SKIP(...)
	CODE:
		RETVAL = 1;
	OUTPUT:
		RETVAL

void
DESTROY(WrapTableType *self)
	CODE:
		// warn("TableType destroyed!");
		delete self;

WrapTableType *
Triceps::TableType::new(WrapRowType *wrt)
	CODE:
		clearErrMsg();

		RETVAL = new WrapTableType(new TableType(wrt->get()));
	OUTPUT:
		RETVAL

#// print(self, [ indent, [ subindent ] ])
#//   indent - default "", undef means "print everything in a signle line"
#//   subindent - default "  "
SV *
print(WrapTableType *self, ...)
	PPCODE:
		GEN_PRINT_METHOD(TableType)

#// type comparisons
int
equals(WrapTableType *self, WrapTableType *other)
	CODE:
		clearErrMsg();
		TableType *tbself = self->get();
		TableType *tbother = other->get();
		RETVAL = tbself->equals(tbother);
	OUTPUT:
		RETVAL

int
match(WrapTableType *self, WrapTableType *other)
	CODE:
		clearErrMsg();
		TableType *tbself = self->get();
		TableType *tbother = other->get();
		RETVAL = tbself->match(tbother);
	OUTPUT:
		RETVAL

int
same(WrapTableType *self, WrapTableType *other)
	CODE:
		clearErrMsg();
		TableType *tbself = self->get();
		TableType *tbother = other->get();
		RETVAL = (tbself == tbother);
	OUTPUT:
		RETVAL

#// add an index
#// XXX accept multiple subname-sub pairs as arguments
WrapTableType *
addSubIndex(WrapTableType *self, char *subname, WrapIndexType *sub)
	CODE:
		static char funcName[] =  "Triceps::TableType::addSubIndex";
		// for casting of return value
		static char CLASS[] = "Triceps::TableType";

		clearErrMsg();
		TableType *tbt = self->get();

		try { do {
			if (tbt->isInitialized())
				throw Exception::f("%s: table is already initialized, can not add indexes any more", funcName);
		} while(0); } TRICEPS_CATCH_CROAK;

		IndexType *ixsub = sub->get();
		// can't just return self because it will upset the refcount
		RETVAL = new WrapTableType(tbt->addSubIndex(subname, ixsub));
	OUTPUT:
		RETVAL

#// find a nested index by name
WrapIndexType *
findSubIndex(WrapTableType *self, char *subname)
	CODE:
		static char funcName[] =  "Triceps::TableType::findSubIndex";
		// for casting of return value
		static char CLASS[] = "Triceps::IndexType";

		clearErrMsg();
		TableType *tbt = self->get();
		IndexType *ixsub = tbt->findSubIndex(subname);
		try { do {
			if (ixsub == NULL) 
				throw Exception::f("%s: unknown nested index '%s'", funcName, subname);
		} while(0); } TRICEPS_CATCH_CROAK;
		RETVAL = new WrapIndexType(ixsub);
	OUTPUT:
		RETVAL

#// find a nested index by name, on failure just return undef
WrapIndexType *
findSubIndexSafe(WrapTableType *self, char *subname)
	CODE:
		static char funcName[] =  "Triceps::TableType::findSubIndex";
		// for casting of return value
		static char CLASS[] = "Triceps::IndexType";

		clearErrMsg();
		TableType *tbt = self->get();
		IndexType *ixsub = tbt->findSubIndex(subname);
		if (ixsub == NULL) 
			XSRETURN_UNDEF; // not croak!
		RETVAL = new WrapIndexType(ixsub);
	OUTPUT:
		RETVAL

#// find a nested index by type id
WrapIndexType *
findSubIndexById(WrapTableType *self, SV *idarg)
	CODE:
		static char funcName[] =  "Triceps::TableType::findSubIndexById";
		// for casting of return value
		static char CLASS[] = "Triceps::IndexType";
		RETVAL = NULL; // shut up the warning

		try { do {
			clearErrMsg();
			TableType *tbt = self->get();

			IndexType::IndexId id = parseIndexId(funcName, idarg); // may throw

			IndexType *ixsub = tbt->findSubIndexById(id);
			if (ixsub == NULL)
				throw Exception::f("%s: no nested index with type id '%s' (%d)", funcName, IndexType::indexIdString(id), id);
			RETVAL = new WrapIndexType(ixsub);
		} while(0); } TRICEPS_CATCH_CROAK;
	OUTPUT:
		RETVAL

#// returns an array of paired values (name => type)
SV *
getSubIndexes(WrapTableType *self)
	PPCODE:
		// for casting of return value
		static char CLASS[] = "Triceps::IndexType";

		clearErrMsg();
		TableType *tbt = self->get();

		const IndexTypeVec &nested = tbt->getSubIndexes();
		for (IndexTypeVec::const_iterator it = nested.begin(); it != nested.end(); ++it) {
			const IndexTypeRef &ref = *it;
			
			XPUSHs(sv_2mortal(newSVpvn(ref.name_.c_str(), ref.name_.size())));
			SV *sub = newSV(0);
			sv_setref_pv( sub, CLASS, (void*)(new WrapIndexType(ref.index_.get())) );
			XPUSHs(sv_2mortal(sub));
		}

#// get the first leaf sub-index
WrapIndexType *
getFirstLeaf(WrapTableType *self)
	CODE:
		static char funcName[] =  "Triceps::TableType::getFirstLeaf";
		// for casting of return value
		static char CLASS[] = "Triceps::IndexType";

		clearErrMsg();
		TableType *tbt = self->get();
		IndexType *leaf = tbt->getFirstLeaf();
		try { do {
			if (leaf == NULL)
				throw Exception::f("%s: table type has no indexes defined", funcName);
		} while(0); } TRICEPS_CATCH_CROAK;
		RETVAL = new WrapIndexType(leaf);
	OUTPUT:
		RETVAL

#// check if the type has been initialized
int
isInitialized(WrapTableType *self)
	CODE:
		clearErrMsg();
		TableType *tbt = self->get();
		RETVAL = tbt->isInitialized();
	OUTPUT:
		RETVAL

#// initialize, returns 1 on success, undef on error
int
initialize(WrapTableType *self)
	CODE:
		clearErrMsg();
		TableType *tbt = self->get();
		tbt->initialize();
		Erref err = tbt->getErrors();
		RETVAL = 1;
		try { do {
			if (err->hasError())
				throw Exception(err, false);
		} while(0); } TRICEPS_CATCH_CROAK;
	OUTPUT:
		RETVAL

#// get back the row type
WrapRowType *
rowType(WrapTableType *self)
	CODE:
		// for casting of return value
		static char CLASS[] = "Triceps::RowType";

		clearErrMsg();
		TableType *tbt = self->get();
		RETVAL = new WrapRowType(const_cast<RowType *>(tbt->rowType()));
	OUTPUT:
		RETVAL

#// get back the row type, with a consistent name
WrapRowType *
getRowType(WrapTableType *self)
	CODE:
		// for casting of return value
		static char CLASS[] = "Triceps::RowType";

		clearErrMsg();
		TableType *tbt = self->get();
		RETVAL = new WrapRowType(const_cast<RowType *>(tbt->rowType()));
	OUTPUT:
		RETVAL

#// copy the row type, the result is un-initialized
WrapTableType *
copy(WrapTableType *self)
	CODE:
		// for casting of return value
		static char CLASS[] = "Triceps::TableType";

		clearErrMsg();
		TableType *tbt = self->get();
		RETVAL = new WrapTableType(tbt->copy());
	OUTPUT:
		RETVAL

#// this one is exported to Perl for testing, and thus left undocumented
WrapTableType *
deepCopy(WrapTableType *self)
	CODE:
		// for casting of return value
		static char CLASS[] = "Triceps::TableType";

		clearErrMsg();
		TableType *tbt = self->get();
		Autoref<HoldRowTypes> holder = new HoldRowTypes;
		RETVAL = new WrapTableType(tbt->deepCopy(holder));
	OUTPUT:
		RETVAL
