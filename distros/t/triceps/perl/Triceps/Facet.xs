//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
// The wrapper for Facet.

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "TricepsPerl.h"
#include "app/Facet.h"

MODULE = Triceps::Facet		PACKAGE = Triceps::Facet
###################################################################################

int
CLONE_SKIP(...)
	CODE:
		RETVAL = 1;
	OUTPUT:
		RETVAL

void
DESTROY(WrapFacet *self)
	CODE:
		// Facet *fa = self->get();
		// warn("Facet %s %p wrap %p destroyed!", fa->getFullName().c_str(), to, self);
		delete self;

# check whether both refs point to the same object
int
same(WrapFacet *self, WrapFacet *other)
	CODE:
		clearErrMsg();
		Facet *fa1 = self->get();
		Facet *fa2 = other->get();
		RETVAL = (fa1 == fa2);
	OUTPUT:
		RETVAL

char *
getShortName(WrapFacet *self)
	CODE:
		clearErrMsg();
		Facet *fa = self->get();
		RETVAL = (char *)fa->getShortName().c_str();
	OUTPUT:
		RETVAL

char *
getFullName(WrapFacet *self)
	CODE:
		clearErrMsg();
		Facet *fa = self->get();
		RETVAL = (char *)fa->getFullName().c_str();
	OUTPUT:
		RETVAL

int
isWriter(WrapFacet *self)
	CODE:
		clearErrMsg();
		RETVAL = self->get()->isWriter();
	OUTPUT:
		RETVAL

int
isReverse(WrapFacet *self)
	CODE:
		clearErrMsg();
		RETVAL = self->get()->isReverse();
	OUTPUT:
		RETVAL

int
queueLimit(WrapFacet *self)
	CODE:
		clearErrMsg();
		RETVAL = self->get()->queueLimit();
	OUTPUT:
		RETVAL

#// the constant
int
DEFAULT_QUEUE_LIMIT()
	CODE:
		RETVAL = Facet::DEFAULT_QUEUE_LIMIT;
	OUTPUT:
		RETVAL

#// XXX propagate more of the FnReturn methods like getLabel()?
WrapFnReturn *
getFnReturn(WrapFacet *self)
	CODE:
		static char CLASS[] = "Triceps::FnReturn";
		clearErrMsg();
		RETVAL = new WrapFnReturn(self->get()->getFnReturn());
	OUTPUT:
		RETVAL

WrapNexus *
nexus(WrapFacet *self)
	CODE:
		static char CLASS[] = "Triceps::Nexus";
		clearErrMsg();
		RETVAL = new WrapNexus(self->get()->nexus());
	OUTPUT:
		RETVAL

int
beginIdx(WrapFacet *self)
	CODE:
		clearErrMsg();
		RETVAL = self->get()->beginIdx();
	OUTPUT:
		RETVAL

int
endIdx(WrapFacet *self)
	CODE:
		clearErrMsg();
		RETVAL = self->get()->endIdx();
	OUTPUT:
		RETVAL

#// Get a label by name. Confesses on the unknown names.
#// A convenience to skip over getting the FnReturn.
WrapLabel *
getLabel(WrapFacet *self, char *name)
	CODE:
		// for casting of return valus
		static char CLASS[] = "Triceps::Label";
		clearErrMsg();
		RETVAL = NULL;
		try {
			Facet *obj = self->get();
			Label *lb = obj->getFnReturn()->getLabel(name);
			if (lb == NULL)
				throw Exception::f("Triceps::Facet::getLabel: unknown label name '%s'.", name);
			RETVAL = new WrapLabel(lb);
		} TRICEPS_CATCH_CROAK;
	OUTPUT:
		RETVAL

#// renamed from rowTypes() to be consistent with FnReturn
#// "imp" stands for "import"
#// Unlike FnReturn, there is no order defined on the entries here, so no point
#// in methods that return separately the names and values.
SV *
impRowTypesHash(WrapFacet *self)
	PPCODE:
		// for casting of return value
		static char CLASS[] = "Triceps::RowType";
		clearErrMsg();
		Facet *fa = self->get();
		const Facet::RowTypeMap &m = fa->rowTypes();
		for (Facet::RowTypeMap::const_iterator it = m.begin(); it != m.end(); ++it) {
			XPUSHs(sv_2mortal(newSVpvn(it->first.c_str(), it->first.size())));

			SV *sub = newSV(0);
			sv_setref_pv( sub, CLASS, (void*)(new WrapRowType(it->second)) );
			XPUSHs(sv_2mortal(sub));
		}

WrapRowType *
impRowType(WrapFacet *self, char *name)
	CODE:
		// for casting of return valus
		static char CLASS[] = "Triceps::RowType";
		clearErrMsg();
		RETVAL = NULL;
		try {
			Facet *obj = self->get();
			RowType *rt = obj->impRowType(name);
			if (rt == NULL) // XXX add list of valid names in the error message?
				throw Exception::f("Triceps::Facet::impRowType: unknown row type name '%s'", name);
			RETVAL = new WrapRowType(rt);
		} TRICEPS_CATCH_CROAK;
	OUTPUT:
		RETVAL

#// renamed from tableTypes() to be consistent with FnReturn
#// "imp" stands for "import"
#// Unlike FnReturn, there is no order defined on the entries here, so no point
#// in methods that return separately the names and values.
SV *
impTableTypesHash(WrapFacet *self)
	PPCODE:
		// for casting of return value
		static char CLASS[] = "Triceps::TableType";
		clearErrMsg();
		Facet *fa = self->get();
		const Facet::TableTypeMap &m = fa->tableTypes();
		for (Facet::TableTypeMap::const_iterator it = m.begin(); it != m.end(); ++it) {
			XPUSHs(sv_2mortal(newSVpvn(it->first.c_str(), it->first.size())));

			SV *sub = newSV(0);
			sv_setref_pv( sub, CLASS, (void*)(new WrapTableType(it->second)) );
			XPUSHs(sv_2mortal(sub));
		}

WrapTableType *
impTableType(WrapFacet *self, char *name)
	CODE:
		// for casting of return valus
		static char CLASS[] = "Triceps::TableType";
		clearErrMsg();
		RETVAL = NULL;
		try {
			Facet *obj = self->get();
			TableType *tt = obj->impTableType(name);
			if (tt == NULL) // XXX add list of valid names in the error message?
				throw Exception::f("Triceps::Facet::impTableType: unknown table type name '%s'", name);
			RETVAL = new WrapTableType(tt);
		} TRICEPS_CATCH_CROAK;
	OUTPUT:
		RETVAL

int
flushWriter(WrapFacet *self)
	CODE:
		clearErrMsg();
		RETVAL = 0;
		try {
			RETVAL = self->get()->flushWriter();
		} TRICEPS_CATCH_CROAK;
	OUTPUT:
		RETVAL

