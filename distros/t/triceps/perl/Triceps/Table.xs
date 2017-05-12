//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
// The wrapper for Table.

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "TricepsPerl.h"

namespace TRICEPS_NS
{
namespace TricepsPerl 
{

// Parse the argument as either a RowHandle (then return it directly)
// or a Row (then create a RowHandle from it).
// On errors throws an Exception.
// @patab tab - table where the handle will be used
// @param funcName - calling function name, for error messages
// @param arg - the incoming argument
// @return - a RowHandle; put it into Rhref because handle may be just created!!!
RowHandle *parseRowOrHandle(Table *tab, const char *funcName, SV *arg)
{
	if( sv_isobject(arg) && (SvTYPE(SvRV(arg)) == SVt_PVMG) ) {
		WrapRowHandle *wrh = (WrapRowHandle *)SvIV((SV*)SvRV( arg ));
		if (wrh == 0) {
			throw Exception::f("%s: row argument is NULL and not a valid SV reference to Row or RowHandle", funcName);
		}
		if (!wrh->badMagic()) {
			if (wrh->ref_.getTable() != tab) {
				throw Exception::f("%s: row argument is a RowHandle in a wrong table %s",
					funcName, wrh->ref_.getTable()->getName().c_str());
			}
			RowHandle *rh = wrh->get();
			if (rh == NULL) {
				throw Exception::f("%s: RowHandle is NULL", funcName);
			}
			return rh;
		}
		WrapRow *wr = (WrapRow *)wrh;
		if (wr->badMagic()) {
			throw Exception::f("%s: row argument has an incorrect magic for Row or RowHandle", funcName);
		}

		Row *r = wr->get();
		const RowType *rt = wr->ref_.getType();

		if (!rt->match(tab->getRowType())) {
			string msg = strprintf("%s: table and row types are not equal, in table: ", funcName);
			tab->getRowType()->printTo(msg, NOINDENT);
			msg.append(", in row: ");
			rt->printTo(msg, NOINDENT);

			throw Exception(msg, false);
		}
		return tab->makeRowHandle(r);
	} else{
		throw Exception::f("%s: row argument is not a blessed SV reference to Row or RowHandle", funcName);
	}
}

}; // Triceps::TricepsPerl
}; // Triceps

MODULE = Triceps::Table		PACKAGE = Triceps::Table
###################################################################################

int
CLONE_SKIP(...)
	CODE:
		RETVAL = 1;
	OUTPUT:
		RETVAL

void
DESTROY(WrapTable *self)
	CODE:
		// warn("Table destroyed!");
		delete self;


#// The table gets created by Unit::makeTable

WrapLabel *
getInputLabel(WrapTable *self)
	CODE:
		// for casting of return value
		static char CLASS[] = "Triceps::Label";

		clearErrMsg();
		Table *t = self->get();
		RETVAL = new WrapLabel(t->getInputLabel());
	OUTPUT:
		RETVAL

#// since the C++ inheritance doesn't propagate to Perl, the inherited call getLabel()
#// becomes an explicit getOutputLabel()
WrapLabel *
getOutputLabel(WrapTable *self)
	CODE:
		// for casting of return value
		static char CLASS[] = "Triceps::Label";

		clearErrMsg();
		Table *t = self->get();
		RETVAL = new WrapLabel(t->getLabel());
	OUTPUT:
		RETVAL

WrapLabel *
getPreLabel(WrapTable *self)
	CODE:
		// for casting of return value
		static char CLASS[] = "Triceps::Label";

		clearErrMsg();
		Table *t = self->get();
		RETVAL = new WrapLabel(t->getPreLabel());
	OUTPUT:
		RETVAL

WrapLabel *
getDumpLabel(WrapTable *self)
	CODE:
		// for casting of return value
		static char CLASS[] = "Triceps::Label";

		clearErrMsg();
		Table *t = self->get();
		RETVAL = new WrapLabel(t->getDumpLabel());
	OUTPUT:
		RETVAL

WrapLabel *
getAggregatorLabel(WrapTable *self, char *aggname)
	CODE:
		static char funcName[] =  "Triceps::Table::getAggregatorLabel";
		// for casting of return value
		static char CLASS[] = "Triceps::Label";

		clearErrMsg();
		Table *t = self->get();
		Label *lab = t->getAggregatorLabel(aggname);

		try { do {
			if (lab == NULL)
				throw Exception::f("%s: aggregator '%s' is not defined on table '%s'", funcName, aggname, t->getName().c_str());
		} while(0); } TRICEPS_CATCH_CROAK;
		RETVAL = new WrapLabel(lab);
	OUTPUT:
		RETVAL

WrapTableType *
getType(WrapTable *self)
	CODE:
		// for casting of return value
		static char CLASS[] = "Triceps::TableType";

		clearErrMsg();
		Table *t = self->get();
		RETVAL = new WrapTableType(const_cast<TableType *>(t->getType()));
	OUTPUT:
		RETVAL

WrapUnit*
getUnit(WrapTable *self)
	CODE:
		clearErrMsg();
		Table *tab = self->get();

		// for casting of return value
		static char CLASS[] = "Triceps::Unit";
		RETVAL = new WrapUnit(tab->getUnit());
	OUTPUT:
		RETVAL

#// check whether both refs point to the same type object
int
same(WrapTable *self, WrapTable *other)
	CODE:
		clearErrMsg();
		Table *t = self->get();
		Table *ot = other->get();
		RETVAL = (t == ot);
	OUTPUT:
		RETVAL

WrapRowType *
getRowType(WrapTable *self)
	CODE:
		clearErrMsg();
		Table *tab = self->get();

		// for casting of return value
		static char CLASS[] = "Triceps::RowType";
		RETVAL = new WrapRowType(const_cast<RowType *>(tab->getRowType()));
	OUTPUT:
		RETVAL

char *
getName(WrapTable *self)
	CODE:
		clearErrMsg();
		Table *t = self->get();
		RETVAL = (char *)t->getName().c_str();
	OUTPUT:
		RETVAL

#// this may be 64-bit, and IV is guaranteed to be pointer-sized
IV
size(WrapTable *self)
	CODE:
		clearErrMsg();
		Table *t = self->get();
		RETVAL = t->size();
	OUTPUT:
		RETVAL

WrapFnReturn *
fnReturn(WrapTable *self)
	CODE:
		static char funcName[] =  "Triceps::Table::fnReturn";
		// for casting of return value
		static char CLASS[] = "Triceps::FnReturn";
		RETVAL = NULL; // shut up the warning

		clearErrMsg();
		Table *t = self->get();

		try { do {
			RETVAL = new WrapFnReturn(t->fnReturn());
		} while(0); } TRICEPS_CATCH_CROAK;
	OUTPUT:
		RETVAL

WrapRowHandle *
makeRowHandle(WrapTable *self, WrapRow *row)
	CODE:
		static char funcName[] =  "Triceps::Table::makeRowHandle";
		// for casting of return value
		static char CLASS[] = "Triceps::RowHandle";

		clearErrMsg();
		Table *t = self->get();
		Row *r = row->get();
		const RowType *rt = row->ref_.getType();

		try { do {
			if (!rt->match(t->getRowType())) {
				string msg = strprintf("%s: table and row types are not equal, in table: ", funcName);
				t->getRowType()->printTo(msg, NOINDENT);
				msg.append(", in row: ");
				rt->printTo(msg, NOINDENT);

				throw Exception(msg, false);
			}
		} while(0); } TRICEPS_CATCH_CROAK;

		RETVAL = new WrapRowHandle(t, t->makeRowHandle(r));
	OUTPUT:
		RETVAL

#// I'm not sure if there is much use for it, but just in case...
WrapRowHandle *
makeNullRowHandle(WrapTable *self)
	CODE:
		// for casting of return value
		static char CLASS[] = "Triceps::RowHandle";

		clearErrMsg();
		Table *t = self->get();

		RETVAL = new WrapRowHandle(t, NULL);
	OUTPUT:
		RETVAL


#// returns: 1 on success, 0 if the policy didn't allow the insert, undef on an error
int
insert(WrapTable *self, SV *rowarg)
	CODE:
		RETVAL = 0; // shut up the warning
		static char funcName[] =  "Triceps::Table::insert";
		try { do {
			clearErrMsg();
			Table *t = self->get();

			Rhref rhr(t,  parseRowOrHandle(t, funcName, rowarg)); // may throw

			RETVAL = t->insert(rhr.get());
		} while(0); } TRICEPS_CATCH_CROAK;
	OUTPUT:
		RETVAL

#// returns 1 normally, or undef on incorrect arguments
int
remove(WrapTable *self, WrapRowHandle *wrh)
	CODE:
		try { do {
			static char funcName[] =  "Triceps::Table::remove";

			clearErrMsg();
			Table *t = self->get();
			RowHandle *rh = wrh->get();

			if (rh == NULL) {
				throw Exception::f("%s: RowHandle is NULL", funcName);
			}

			if (wrh->ref_.getTable() != t) {
				throw Exception::f("%s: row argument is a RowHandle in a wrong table %s",
					funcName, wrh->ref_.getTable()->getName().c_str());
			}

			t->remove(rh);
		} while(0); } TRICEPS_CATCH_CROAK;
		RETVAL = 1;
	OUTPUT:
		RETVAL

#// version that takes a Row as an argument and acts as a combination of find/remove
#// returns 1 if deleted, 0 if not found, undef on incorrect arguments
int
deleteRow(WrapTable *self, WrapRow *wr)
	CODE:
		RETVAL = 0; // shut up the warning
		try { do {
			static char funcName[] =  "Triceps::Table::deleteRow";

			clearErrMsg();
			Table *t = self->get();
			Row *r = wr->get();
			const RowType *rt = wr->ref_.getType();

			if (!rt->match(t->getRowType())) {
				string msg = strprintf("%s: table and row types are not equal, in table: ", funcName);
				t->getRowType()->printTo(msg, NOINDENT);
				msg.append(", in row: ");
				rt->printTo(msg, NOINDENT);

				throw TRICEPS_NS::Exception(msg, false);
			}

			// pretty much a copy of C++ Table::InputLabel::execute()
			RETVAL = t->deleteRow(r)? 1 : 0;
		} while(0); } TRICEPS_CATCH_CROAK;
	OUTPUT:
		RETVAL

#// RowHandle with NULL pointer in it is used for the end-iterator

WrapRowHandle *
begin(WrapTable *self)
	CODE:
		static char CLASS[] = "Triceps::RowHandle";

		clearErrMsg();
		Table *t = self->get();
		RETVAL = new WrapRowHandle(t, t->begin());
	OUTPUT:
		RETVAL
		
WrapRowHandle *
beginIdx(WrapTable *self, WrapIndexType *widx)
	CODE:
		static char CLASS[] = "Triceps::RowHandle";

		RETVAL = NULL; // shut up the warning
		try { do {
			clearErrMsg();
			Table *t = self->get();
			IndexType *idx = widx->get();

			static char funcName[] =  "Triceps::Table::beginIdx";
			if (idx->getTabtype() != t->getType()) {
				throw TRICEPS_NS::Exception(strprintf("%s: indexType argument does not belong to table's type", funcName), false);
			}

			RETVAL = new WrapRowHandle(t, t->beginIdx(idx));
		} while(0); } TRICEPS_CATCH_CROAK;
	OUTPUT:
		RETVAL

WrapRowHandle *
next(WrapTable *self, WrapRowHandle *wcur)
	CODE:
		static char CLASS[] = "Triceps::RowHandle";

		RETVAL = NULL; // shut up the warning
		try { do {
			clearErrMsg();
			Table *t = self->get();
			RowHandle *cur = wcur->get(); // NULL is OK

			static char funcName[] =  "Triceps::Table::next";
			if (wcur->ref_.getTable() != t) {
				throw TRICEPS_NS::Exception(strprintf("%s: row argument is a RowHandle in a wrong table %s",
					funcName, wcur->ref_.getTable()->getName().c_str()), false);
			}

			RETVAL = new WrapRowHandle(t, t->next(cur));
		} while(0); } TRICEPS_CATCH_CROAK;
	OUTPUT:
		RETVAL
		
WrapRowHandle *
nextIdx(WrapTable *self, WrapIndexType *widx, WrapRowHandle *wcur)
	CODE:
		static char CLASS[] = "Triceps::RowHandle";

		RETVAL = NULL; // shut up the warning
		try { do {
			clearErrMsg();
			Table *t = self->get();
			IndexType *idx = widx->get();
			RowHandle *cur = wcur->get(); // NULL is OK

			static char funcName[] =  "Triceps::Table::nextIdx";
			if (idx->getTabtype() != t->getType()) {
				throw TRICEPS_NS::Exception(strprintf("%s: indexType argument does not belong to table's type", funcName), false);
			}
			if (wcur->ref_.getTable() != t) {
				throw TRICEPS_NS::Exception(strprintf("%s: row argument is a RowHandle in a wrong table %s",
					funcName, wcur->ref_.getTable()->getName().c_str()), false);
			}

			RETVAL = new WrapRowHandle(t, t->nextIdx(idx, cur));
		} while(0); } TRICEPS_CATCH_CROAK;
	OUTPUT:
		RETVAL
		
WrapRowHandle *
firstOfGroupIdx(WrapTable *self, WrapIndexType *widx, WrapRowHandle *wcur)
	CODE:
		static char CLASS[] = "Triceps::RowHandle";

		RETVAL = NULL; // shut up the warning
		try { do {
			clearErrMsg();
			Table *t = self->get();
			IndexType *idx = widx->get();
			RowHandle *cur = wcur->get(); // NULL is OK

			static char funcName[] =  "Triceps::Table::firstOfGroupIdx";
			if (idx->getTabtype() != t->getType()) {
				throw TRICEPS_NS::Exception(strprintf("%s: indexType argument does not belong to table's type", funcName), false);
			}
			if (wcur->ref_.getTable() != t) {
				throw TRICEPS_NS::Exception(strprintf("%s: row argument is a RowHandle in a wrong table %s",
					funcName, wcur->ref_.getTable()->getName().c_str()), false);
			}

			RETVAL = new WrapRowHandle(t, t->firstOfGroupIdx(idx, cur));
		} while(0); } TRICEPS_CATCH_CROAK;
	OUTPUT:
		RETVAL
		
WrapRowHandle *
nextGroupIdx(WrapTable *self, WrapIndexType *widx, WrapRowHandle *wcur)
	CODE:
		static char CLASS[] = "Triceps::RowHandle";

		RETVAL = NULL; // shut up the warning
		try { do {
			clearErrMsg();
			Table *t = self->get();
			IndexType *idx = widx->get();
			RowHandle *cur = wcur->get(); // NULL is OK

			static char funcName[] =  "Triceps::Table::nextGroupIdx";
			if (idx->getTabtype() != t->getType()) {
				throw TRICEPS_NS::Exception(strprintf("%s: indexType argument does not belong to table's type", funcName), false);
			}
			if (wcur->ref_.getTable() != t) {
				throw TRICEPS_NS::Exception(strprintf("%s: row argument is a RowHandle in a wrong table %s",
					funcName, wcur->ref_.getTable()->getName().c_str()), false);
			}

			RETVAL = new WrapRowHandle(t, t->nextGroupIdx(idx, cur));
		} while(0); } TRICEPS_CATCH_CROAK;
	OUTPUT:
		RETVAL
		
WrapRowHandle *
find(WrapTable *self, SV *rowarg)
	CODE:
		static char CLASS[] = "Triceps::RowHandle";
		static char funcName[] =  "Triceps::Table::find";

		RETVAL = NULL; // shut up the warning
		try { do {
			clearErrMsg();
			Table *t = self->get();

			Rhref rhr(t,  parseRowOrHandle(t, funcName, rowarg)); // may throw

			RETVAL = new WrapRowHandle(t, t->find(rhr.get()));
		} while(0); } TRICEPS_CATCH_CROAK;
	OUTPUT:
		RETVAL

WrapRowHandle *
findIdx(WrapTable *self, WrapIndexType *widx, SV *rowarg)
	CODE:
		static char CLASS[] = "Triceps::RowHandle";
		static char funcName[] =  "Triceps::Table::findIdx";

		RETVAL = NULL; // shut up the warning
		try { do {
			clearErrMsg();
			Table *t = self->get();
			IndexType *idx = widx->get();

			if (idx->getTabtype() != t->getType()) {
				throw TRICEPS_NS::Exception(strprintf("%s: indexType argument does not belong to table's type", funcName), false);
			}

			Rhref rhr(t,  parseRowOrHandle(t, funcName, rowarg)); // may throw

			RETVAL = new WrapRowHandle(t, t->findIdx(idx, rhr.get()));
		} while(0); } TRICEPS_CATCH_CROAK;
	OUTPUT:
		RETVAL

int
groupSizeIdx(WrapTable *self, WrapIndexType *widx, SV *rowarg)
	CODE:
		static char CLASS[] = "Triceps::RowHandle";
		static char funcName[] =  "Triceps::Table::groupSizeIdx";

		RETVAL = NULL; // shut up the warning
		try { do {
			clearErrMsg();
			Table *t = self->get();
			IndexType *idx = widx->get();

			if (idx->getTabtype() != t->getType()) {
				throw TRICEPS_NS::Exception(strprintf("%s: indexType argument does not belong to table's type", funcName), false);
			}

			Rhref rhr(t,  parseRowOrHandle(t, funcName, rowarg)); // may throw

			RETVAL = t->groupSizeIdx(idx, rhr.get());
		} while(0); } TRICEPS_CATCH_CROAK;
	OUTPUT:
		RETVAL

#// Clear the table. If the limit is specified, will clear no more than
#// this many rows. The rows are removed in the order of the first leaf index.
#// @param limit - (int, optional) maximal number of rows to delete.
void
clear(WrapTable *self, ...)
	CODE:
		static char funcName[] =  "Triceps::Table::clear";

		try { do {
			clearErrMsg();
			Table *t = self->get();
			size_t arg;
			
			if (items == 1) {
				arg = 0;
			} else if (items == 2) {
				IV iarg = SvIV(ST(1));
				if (iarg < 0)
					throw TRICEPS_NS::Exception::f("%s: the limit argument must be >=0, got %lld", 
						funcName, (long long)iarg);
				arg = (size_t)iarg;
			} else {
				throw TRICEPS_NS::Exception::f("Usage: %s(self [, limit])", funcName);
			}

			t->clear(arg);
		} while(0); } TRICEPS_CATCH_CROAK;

void
dumpAll(WrapTable *self, ...)
	CODE:
		try { do {
			static char funcName[] =  "Triceps::Table::dumpAll";
			clearErrMsg();
			Table *t = self->get();
			Rowop::Opcode op;

			if (items == 1) {
				op = Rowop::OP_INSERT;
			} else if (items == 2) {
				op = parseOpcode(funcName, ST(1)); // may throw
			} else {
				throw TRICEPS_NS::Exception::f("Usage: %s(self [, opcode])", funcName);
			}

			t->dumpAll(op);
		} while(0); } TRICEPS_CATCH_CROAK;

void
dumpAllIdx(WrapTable *self, WrapIndexType *widx, ...)
	CODE:
		try { do {
			static char funcName[] =  "Triceps::Table::dumpAllIdx";
			clearErrMsg();
			Table *t = self->get();
			IndexType *idx = widx->get();
			Rowop::Opcode op;

			if (idx->getTabtype() != t->getType()) {
				throw TRICEPS_NS::Exception(strprintf("%s: indexType argument does not belong to table's type", funcName), false);
			}

			if (items <= 2) {
				op = Rowop::OP_INSERT;
			} else if (items == 3) {
				op = parseOpcode(funcName, ST(2)); // may throw
			} else {
				throw TRICEPS_NS::Exception::f("Usage: %s(self, widx [, opcode])", funcName);
			}

			t->dumpAllIdx(idx, op);
		} while(0); } TRICEPS_CATCH_CROAK;

