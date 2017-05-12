//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
// The wrapper for Label.

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "TricepsPerl.h"
#include "PerlCallback.h"

MODULE = Triceps::Label		PACKAGE = Triceps::Label

###################################################################################

BOOT:
// fprintf(stderr, "DEBUG Label items=%d sp=%p mark=%p\n", items, sp, mark);

int
CLONE_SKIP(...)
	CODE:
		RETVAL = 1;
	OUTPUT:
		RETVAL

void
DESTROY(WrapLabel *self)
	CODE:
		// warn("Label destroyed!");
		delete self;

WrapRowType*
getType(WrapLabel *self)
	CODE:
		clearErrMsg();
		Label *lab = self->get();

		// for casting of return value
		static char CLASS[] = "Triceps::RowType";
		RETVAL = new WrapRowType(const_cast<RowType *>(lab->getType()));
	OUTPUT:
		RETVAL

#// a complete synonym of getType(), with the name more consistent
#// with the other objects' similar methods
WrapRowType*
getRowType(WrapLabel *self)
	CODE:
		clearErrMsg();
		Label *lab = self->get();

		// for casting of return value
		static char CLASS[] = "Triceps::RowType";
		RETVAL = new WrapRowType(const_cast<RowType *>(lab->getType()));
	OUTPUT:
		RETVAL

WrapUnit*
getUnit(WrapLabel *self)
	CODE:
		// for casting of return value
		static char CLASS[] = "Triceps::Unit";
		clearErrMsg();
		RETVAL = NULL; // shut up the compiler

		try { do {
			Label *lab = self->get();
			Unit *unit = lab->getUnitPtr();

			if (unit == NULL)
				throw Exception::f("Triceps::Label::getUnit: label has been already cleared");

			RETVAL = new WrapUnit(unit);
		} while(0); } TRICEPS_CATCH_CROAK;
	OUTPUT:
		RETVAL

#// returns 1 on success, undef on error
int
chain(WrapLabel *self, WrapLabel *other)
	CODE:
		clearErrMsg();
		Label *lab = self->get();
		Label *olab = other->get();

		try { do {
			Erref err = lab->chain(olab);
			if (err->hasError())
				throw Exception::f(err, "Triceps::Label::chain: failed");
		} while(0); } TRICEPS_CATCH_CROAK;
		RETVAL = 1;
	OUTPUT:
		RETVAL

#// put a label at the front of the chain;
#// returns 1 on success, undef on error
int
chainFront(WrapLabel *self, WrapLabel *other)
	CODE:
		clearErrMsg();
		Label *lab = self->get();
		Label *olab = other->get();

		try { do {
			Erref err = lab->chain(olab, true);
			if (err->hasError())
				throw Exception::f(err, "Triceps::Label::chainFront: failed");
		} while(0); } TRICEPS_CATCH_CROAK;
		RETVAL = 1;
	OUTPUT:
		RETVAL

void
clearChained(WrapLabel *self)
	CODE:
		clearErrMsg();
		Label *lab = self->get();
		lab->clearChained();

#// returns an array of references to chained objects
SV *
getChain(WrapLabel *self)
	PPCODE:
		clearErrMsg();
		Label *lab = self->get();

		// for casting of return value
		static char CLASS[] = "Triceps::Label";

		const Label::ChainedVec &cv = lab->getChain();
		int nf = cv.size();
		for (int i = 0; i < nf; i++) {
			WrapLabel *cl = new WrapLabel(cv[i].get());

			SV *sv = newSV(0);
			sv_setref_pv( sv, CLASS, (void*)cl );
			XPUSHs(sv_2mortal(sv));
		}

int
hasChained(WrapLabel *self)
	CODE:
		clearErrMsg();
		Label *lab = self->get();

		RETVAL = lab->hasChained()? 1 : 0;
	OUTPUT:
		RETVAL

char *
getName(WrapLabel *self)
	CODE:
		clearErrMsg();
		Label *lab = self->get();

		RETVAL = (char *)lab->getName().c_str();
	OUTPUT:
		RETVAL

#// Set the non-reentrant flag.
void
setNonReentrant(WrapLabel *self)
	CODE:
		clearErrMsg();
		Label *lab = self->get();
		lab->setNonReentrant();

#// check whether both refs point to the same type object
int
same(WrapLabel *self, WrapLabel *other)
	CODE:
		clearErrMsg();
		Label *lab = self->get();
		Label *olab = other->get();
		RETVAL = (lab == olab);
	OUTPUT:
		RETVAL

#// factory for Rowops
WrapRowop *
makeRowop(WrapLabel *self, SV *opcode, WrapRow *row, ...)
	CODE:
		// for casting of return value
		static char CLASS[] = "Triceps::Rowop";

		static char funcName[] =  "Triceps::Label::makeRowop";

		clearErrMsg();
		RETVAL = NULL; // shut up the compiler

		try { do {
			Label *lab = self->get();
			const RowType *lt = lab->getType();
			const RowType *rt = row->ref_.getType();
			Row *r = row->ref_.get();

			if ((lt != rt) && !lt->match(rt)) {
				throw Exception(strprintf("%s: row types do not match\n  Label:\n    ", funcName)
						+ lt->print("    ") + "\n  Row:\n    " + rt->print("    "),
					false
				);
			}

			Rowop::Opcode op = parseOpcode(funcName, opcode); // may throw

			Autoref<Rowop> rop;
			if (items == 3) {
				rop = new Rowop(lab, op, r);
			} else if (items == 4) {
				Gadget::EnqMode em = parseEnqMode(funcName, ST(3)); // may throw
				rop = new Rowop(lab, op, r, em);
			} else {
				throw Exception::f("Usage: %s(label, opcode, row [, enqMode]), received too many arguments", funcName);
			}
			RETVAL = new WrapRowop(rop);
		} while(0); } TRICEPS_CATCH_CROAK;
	OUTPUT:
		RETVAL

#// adopt a rowop from another label (of a matching type) by making
#// a copy of it for this label
WrapRowop *
adopt(WrapLabel *self, WrapRowop *wrop)
	CODE:
		// for casting of return value
		static char CLASS[] = "Triceps::Rowop";

		static char funcName[] =  "Triceps::Label::adopt";

		clearErrMsg();
		RETVAL = NULL; // shut up the compiler

		try { do {
			Label *lab = self->get();
			Rowop *orop = wrop->get();
			const Label *olab = orop->getLabel();

			if (!lab->getType()->match(olab->getType())) {
				throw Exception(strprintf("%s: row types do not match\n  Label:\n    ", funcName)
						+ lab->getType()->print("    ") + "\n  Row:\n    " + olab->getType()->print("    "),
					false
				);
			}

			Autoref<Rowop> rop = new Rowop(lab, orop);
			RETVAL = new WrapRowop(rop);
		} while(0); } TRICEPS_CATCH_CROAK;
	OUTPUT:
		RETVAL


#// for PerlLabel, returns the reference to code
#// XXX should return code and all paremeters
SV *
getCode(WrapLabel *self)
	CODE:
		clearErrMsg();
		RETVAL = NULL; // shut up the compiler

		try { do {
			Label *lab = self->get();
			PerlLabel *plab = dynamic_cast<PerlLabel *>(lab);
			if (plab == NULL) {
				throw Exception::f("Triceps::Label::getCode: label is not a Perl Label, has no Perl code");
			}
			SV *code = plab->getCode();
			if (code == NULL)
				break; // sets the error in the function

			SV *ret = newSV(0);
			sv_setsv(ret, code);
			RETVAL = ret;
		} while(0); } TRICEPS_CATCH_CROAK;
	OUTPUT:
		RETVAL

#// clear the label, not to be taken lightly
void
clear(WrapLabel *self)
	CODE:
		clearErrMsg();
		Label *lab = self->get();
		lab->clear();

#// check if the label is cleared
int
isCleared(WrapLabel *self)
	CODE:
		clearErrMsg();
		Label *lab = self->get();
		RETVAL = lab->isCleared();
	OUTPUT:
		RETVAL

#// check if the label is non-reentrant
int
isNonReentrant(WrapLabel *self)
	CODE:
		clearErrMsg();
		Label *lab = self->get();
		RETVAL = lab->isNonReentrant();
	OUTPUT:
		RETVAL

