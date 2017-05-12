//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
// The wrapper for AggregatorType.

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "TricepsPerl.h"
#include "PerlCallback.h"
#include "PerlAggregator.h"

MODULE = Triceps::AggregatorType		PACKAGE = Triceps::AggregatorType
###################################################################################

int
CLONE_SKIP(...)
	CODE:
		RETVAL = 1;
	OUTPUT:
		RETVAL

void
DESTROY(WrapAggregatorType *self)
	CODE:
		// warn("AggregatorType destroyed!");
		delete self;


#// The old-style constructor, with mandatory result row type and no initializer.
#// @param CLASS - name of type being constructed
#// @param wrt - row type of the aggregation result
#// @param name - name that will be used to create the aggregator gadget in the table
#// @param constructor - function reference, called to create the state of aggregator
#//        for each index (may be undef)
#// @param handler - function reference used to react to strings being added and removed
#// @param ... - extra args used for both constructor and handler
WrapAggregatorType *
new(char *CLASS, WrapRowType *wrt, char *name, SV *constructor, SV *handler, ...)
	CODE:
		static char funcName[] =  "Triceps::AggregatorType::new";
		RETVAL = NULL; // shut up the warning

		try { do {
			clearErrMsg();

			RowType *rt = wrt->get();

			Onceref<PerlCallback> cbconst; // defaults to NULL
			if (SvOK(constructor)) {
				cbconst = new PerlCallback(true);
				PerlCallbackInitializeSplit(cbconst, "Triceps::AggregatorType::new(constructor)", constructor, 5, items-5); // may throw
			}

			Onceref<PerlCallback> cbhand = new PerlCallback(true);
			PerlCallbackInitialize(cbhand, "Triceps::AggregatorType::new(handler)", 4, items-4); // may throw

			RETVAL = new WrapAggregatorType(new PerlAggregatorType(name, rt, NULL, cbconst, cbhand));
		} while(0); } TRICEPS_CATCH_CROAK;
	OUTPUT:
		RETVAL

#// The new-style constructor, with option-style arguments
#// Confesses on errors.
#//
#// Options:
#//   name => $name
#//   Name of the aggregator.
#//
#//   resultRowType => $rowType
#//   Type of the result if known. If not set, the init function may set it
#//   later. At least one of "resultRowType" and "init" must be present.
#//
#//   init => 'source code'
#//   init => $&code
#//   init => ['source code', @args]
#//   init => [$&code, @args]
#//   The init function. Will be called at the table initialization time.
#//        Args: AggregatorType aggtm TableType tabt, IndexType idxt, RowType tabrowt, RowType resrowt, @args
#//          aggt - link back to this object (used to set the constructor and handler
#//                 callbacks, result row type and such), DO NOT SAVE IT INSIDE THE
#//                 AGGREGATOR'S DATA OR IT WILL BE A CIRCULAR REFERENCE.
#//          tabt - table type that performs the initialization
#//          idxt - link back to the index type that contains the aggregator (can be used
#//                 to find the grouping, if possible with this index type)
#//          tabrowt - row type of the table, passed directly as a convenience
#//          resrowt - row type of the result as ik't known so far (may be undef if not set yet)
#//        Returns undef on success or an error message (may freely contain \n) on error.
#//   Optional, but at least one of "init" and "handler" must be present.
#//
#//   constructor => ... same value types as init...
#//   Group constructor function, called to create the state of aggregator for each index.
#//       Args: @args
#//   Optional. May be set later by the init function. If not set, the group state will be undef.
#//
#//   handler => ... same value types as init...
#//   Aggregation handler function, called on every change to the group.
#//       Args: Table tab, AggregatorContext ctx, int aggop, int opcode, RowHandle rh, state, @args
#//         tab - table owning this aggregator
#//         ctx - the context with the rest of properties
#//         aggop - the aggregation operation
#//         opcode - the opcode for the group result row of this operation
#//         rh - handle of the row that has been added or deleted for this operation
#//         state - the group state value as returned by the constructor function 
#//             (or undef if no constructor)
#//    Optional. May be set later by the init function. But must be set in either way
#//    or the table initialization will fail. At least one of "init" and "handler" must
#//    be present.
#//
#// XXX TODO:
#//   copyFrom => $aggrType
#//   Copy the contents from another type.
#// XXX implement
#// WrapAggregatorType *
#// make(...)

#// make an uninitialized copy
WrapAggregatorType *
copy(WrapAggregatorType *self)
	CODE:
		// for casting of return value
		static char CLASS[] = "Triceps::AggregatorType";

		clearErrMsg();
		PerlAggregatorType *agt = self->get();
		RETVAL = new WrapAggregatorType(static_cast<PerlAggregatorType *>( agt->copy() ));
	OUTPUT:
		RETVAL

int
same(WrapAggregatorType *self, WrapAggregatorType *other)
	CODE:
		clearErrMsg();
		PerlAggregatorType *agself = self->get();
		PerlAggregatorType *agother = other->get();
		RETVAL = (agself == agother);
	OUTPUT:
		RETVAL

#// get back the row type
WrapRowType *
getRowType(WrapAggregatorType *self)
	CODE:
		// for casting of return value
		static char CLASS[] = "Triceps::RowType";

		clearErrMsg();
		PerlAggregatorType *agself = self->get();
		RETVAL = new WrapRowType(const_cast<RowType *>(agself->getRowType()));
	OUTPUT:
		RETVAL

#// print(self, [ indent, [ subindent ] ])
#//   indent - default "", undef means "print everything in a signle line"
#//   subindent - default "  "
SV *
print(WrapAggregatorType *self, ...)
	PPCODE:
		GEN_PRINT_METHOD(PerlAggregatorType)

#// type comparisons
int
equals(WrapAggregatorType *self, WrapAggregatorType *other)
	CODE:
		clearErrMsg();
		PerlAggregatorType *agself = self->get();
		PerlAggregatorType *agother = other->get();
		RETVAL = agself->equals(agother);
	OUTPUT:
		RETVAL

int
match(WrapAggregatorType *self, WrapAggregatorType *other)
	CODE:
		clearErrMsg();
		PerlAggregatorType *agself = self->get();
		PerlAggregatorType *agother = other->get();
		RETVAL = agself->match(agother);
	OUTPUT:
		RETVAL

