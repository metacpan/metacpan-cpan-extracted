//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
// The main file including all the parts of Triceps XS interface.

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "TricepsPerl.h"
#include <app/Sigusr2.h>

#include "const-c.inc"

#ifdef __cplusplus
extern "C" {
#endif
XS(boot_Triceps__Label); 
XS(boot_Triceps__Row); 
XS(boot_Triceps__Rowop); 
XS(boot_Triceps__RowHandle); 
XS(boot_Triceps__RowType); 
XS(boot_Triceps__IndexType); 
XS(boot_Triceps__TableType); 
XS(boot_Triceps__Tray); 
XS(boot_Triceps__Unit); 
XS(boot_Triceps__UnitTracer); 
XS(boot_Triceps__Table); 
XS(boot_Triceps__AggregatorType); 
XS(boot_Triceps__AggregatorContext); 
XS(boot_Triceps__FrameMark); 
XS(boot_Triceps__FnReturn); 
XS(boot_Triceps__FnBinding); 
XS(boot_Triceps__AutoFnBind); 
XS(boot_Triceps__App); 
XS(boot_Triceps__Triead); 
XS(boot_Triceps__TrieadOwner); 
XS(boot_Triceps__Facet); 
XS(boot_Triceps__Nexus); 
XS(boot_Triceps__AutoDrain); 
XS(boot_Triceps__PerlValue); 
XS(boot_Triceps__TrackedFile); 
#ifdef __cplusplus
};
#endif

MODULE = Triceps		PACKAGE = Triceps

BOOT:
	// the exceptions will be caught and backtraced in Perl
	TRICEPS_NS::Exception::abort_ = false;
	TRICEPS_NS::Exception::enableBacktrace_ = false;
	//
	// boot sub-packages that are compiled separately
	//
	// fprintf(stderr, "DEBUG Triceps items=%d sp=%p mark=%p\n", items, sp, mark);
	PUSHMARK(SP); if (items >= 2) { XPUSHs(ST(0)); XPUSHs(ST(1)); } PUTBACK; 
	boot_Triceps__Label(aTHX_ cv); 
	SPAGAIN; POPs;
	//
	// fprintf(stderr, "DEBUG Triceps items=%d sp=%p mark=%p\n", items, sp, mark);
	PUSHMARK(SP); if (items >= 2) { XPUSHs(ST(0)); XPUSHs(ST(1)); } PUTBACK; 
	boot_Triceps__Row(aTHX_ cv); 
	SPAGAIN; POPs;
	//
	PUSHMARK(SP); if (items >= 2) { XPUSHs(ST(0)); XPUSHs(ST(1)); } PUTBACK; 
	boot_Triceps__Rowop(aTHX_ cv); 
	SPAGAIN; POPs;
	//
	PUSHMARK(SP); if (items >= 2) { XPUSHs(ST(0)); XPUSHs(ST(1)); } PUTBACK; 
	boot_Triceps__RowHandle(aTHX_ cv); 
	SPAGAIN; POPs;
	//
	// fprintf(stderr, "DEBUG Triceps items=%d sp=%p mark=%p\n", items, sp, mark);
	PUSHMARK(SP); if (items >= 2) { XPUSHs(ST(0)); XPUSHs(ST(1)); } PUTBACK; 
	boot_Triceps__RowType(aTHX_ cv); 
	SPAGAIN; POPs;
	//
	PUSHMARK(SP); if (items >= 2) { XPUSHs(ST(0)); XPUSHs(ST(1)); } PUTBACK; 
	boot_Triceps__IndexType(aTHX_ cv); 
	SPAGAIN; POPs;
	//
	PUSHMARK(SP); if (items >= 2) { XPUSHs(ST(0)); XPUSHs(ST(1)); } PUTBACK; 
	boot_Triceps__TableType(aTHX_ cv); 
	SPAGAIN; POPs;
	//
	PUSHMARK(SP); if (items >= 2) { XPUSHs(ST(0)); XPUSHs(ST(1)); } PUTBACK; 
	boot_Triceps__Tray(aTHX_ cv); 
	SPAGAIN; POPs;
	//
	PUSHMARK(SP); if (items >= 2) { XPUSHs(ST(0)); XPUSHs(ST(1)); } PUTBACK; 
	boot_Triceps__Unit(aTHX_ cv); 
	SPAGAIN; POPs;
	//
	PUSHMARK(SP); if (items >= 2) { XPUSHs(ST(0)); XPUSHs(ST(1)); } PUTBACK; 
	boot_Triceps__UnitTracer(aTHX_ cv); 
	SPAGAIN; POPs;
	//
	PUSHMARK(SP); if (items >= 2) { XPUSHs(ST(0)); XPUSHs(ST(1)); } PUTBACK; 
	boot_Triceps__Table(aTHX_ cv); 
	SPAGAIN; POPs;
	//
	PUSHMARK(SP); if (items >= 2) { XPUSHs(ST(0)); XPUSHs(ST(1)); } PUTBACK; 
	boot_Triceps__AggregatorType(aTHX_ cv); 
	SPAGAIN; POPs;
	//
	PUSHMARK(SP); if (items >= 2) { XPUSHs(ST(0)); XPUSHs(ST(1)); } PUTBACK; 
	boot_Triceps__AggregatorContext(aTHX_ cv); 
	SPAGAIN; POPs;
	//
	PUSHMARK(SP); if (items >= 2) { XPUSHs(ST(0)); XPUSHs(ST(1)); } PUTBACK; 
	boot_Triceps__FrameMark(aTHX_ cv); 
	SPAGAIN; POPs;
	//
	PUSHMARK(SP); if (items >= 2) { XPUSHs(ST(0)); XPUSHs(ST(1)); } PUTBACK; 
	boot_Triceps__FnReturn(aTHX_ cv); 
	SPAGAIN; POPs;
	//
	PUSHMARK(SP); if (items >= 2) { XPUSHs(ST(0)); XPUSHs(ST(1)); } PUTBACK; 
	boot_Triceps__FnBinding(aTHX_ cv); 
	SPAGAIN; POPs;
	//
	PUSHMARK(SP); if (items >= 2) { XPUSHs(ST(0)); XPUSHs(ST(1)); } PUTBACK; 
	boot_Triceps__AutoFnBind(aTHX_ cv); 
	SPAGAIN; POPs;
	//
	PUSHMARK(SP); if (items >= 2) { XPUSHs(ST(0)); XPUSHs(ST(1)); } PUTBACK; 
	boot_Triceps__App(aTHX_ cv); 
	SPAGAIN; POPs;
	//
	PUSHMARK(SP); if (items >= 2) { XPUSHs(ST(0)); XPUSHs(ST(1)); } PUTBACK; 
	boot_Triceps__Triead(aTHX_ cv); 
	SPAGAIN; POPs;
	//
	PUSHMARK(SP); if (items >= 2) { XPUSHs(ST(0)); XPUSHs(ST(1)); } PUTBACK; 
	boot_Triceps__TrieadOwner(aTHX_ cv); 
	SPAGAIN; POPs;
	//
	PUSHMARK(SP); if (items >= 2) { XPUSHs(ST(0)); XPUSHs(ST(1)); } PUTBACK; 
	boot_Triceps__Facet(aTHX_ cv); 
	SPAGAIN; POPs;
	//
	PUSHMARK(SP); if (items >= 2) { XPUSHs(ST(0)); XPUSHs(ST(1)); } PUTBACK; 
	boot_Triceps__Nexus(aTHX_ cv); 
	SPAGAIN; POPs;
	//
	PUSHMARK(SP); if (items >= 2) { XPUSHs(ST(0)); XPUSHs(ST(1)); } PUTBACK; 
	boot_Triceps__AutoDrain(aTHX_ cv); 
	SPAGAIN; POPs;
	//
	PUSHMARK(SP); if (items >= 2) { XPUSHs(ST(0)); XPUSHs(ST(1)); } PUTBACK; 
	boot_Triceps__PerlValue(aTHX_ cv); 
	SPAGAIN; POPs;
	//
	PUSHMARK(SP); if (items >= 2) { XPUSHs(ST(0)); XPUSHs(ST(1)); } PUTBACK; 
	boot_Triceps__TrackedFile(aTHX_ cv); 
	SPAGAIN; POPs;
	//
	// fprintf(stderr, "DEBUG Triceps items=%d sp=%p mark=%p\n", items, sp, mark);


INCLUDE: const-xs.inc

############## static functions from Rowop, in perl they move to Triceps:: ###########

int
isInsert(int op)
	CODE:
		clearErrMsg();
		RETVAL = Rowop::isInsert(op);
	OUTPUT:
		RETVAL

int
isDelete(int op)
	CODE:
		clearErrMsg();
		RETVAL = Rowop::isDelete(op);
	OUTPUT:
		RETVAL

int
isNop(int op)
	CODE:
		clearErrMsg();
		RETVAL = Rowop::isNop(op);
	OUTPUT:
		RETVAL

############ conversions of strings to enum constants #############################
#// (this duplicates the Triceps:: constant definitions but comes useful once in a while
#// the error values are converted to undefs
#// The *Safe functions return an undef if can not convert, normal ones croak.

int
stringOpcode(char *val)
	CODE:
		clearErrMsg();
		int res = Rowop::stringOpcode(val);
		try { do {
			if (res == Rowop::OP_BAD)
				throw Exception::f("Triceps::stringOpcode: bad opcode string '%s'", val);
		} while(0); } TRICEPS_CATCH_CROAK;
		RETVAL = res;
	OUTPUT:
		RETVAL

int
stringOpcodeSafe(char *val)
	CODE:
		clearErrMsg();
		int res = Rowop::stringOpcode(val);
		if (res == Rowop::OP_BAD)
			XSRETURN_UNDEF; // not a croak
		RETVAL = res;
	OUTPUT:
		RETVAL

int
stringOcf(char *val)
	CODE:
		clearErrMsg();
		int res = Rowop::stringOcf(val);
		try { do {
			if (res == -1)
				throw Exception::f("Triceps::stringOcf: bad opcode flag string '%s'", val);
		} while(0); } TRICEPS_CATCH_CROAK;
		RETVAL = res;
	OUTPUT:
		RETVAL

int
stringOcfSafe(char *val)
	CODE:
		clearErrMsg();
		int res = Rowop::stringOcf(val);
		if (res == -1)
			XSRETURN_UNDEF; // not a croak
		RETVAL = res;
	OUTPUT:
		RETVAL

int
stringEm(char *val)
	CODE:
		clearErrMsg();
		int res = Gadget::stringEm(val);
		try { do {
			if (res == -1)
				throw Exception::f("Triceps::stringEm: bad enqueueing mode string '%s'", val);
		} while(0); } TRICEPS_CATCH_CROAK;
		RETVAL = res;
	OUTPUT:
		RETVAL

int
stringEmSafe(char *val)
	CODE:
		clearErrMsg();
		int res = Gadget::stringEm(val);
		if (res == -1)
			XSRETURN_UNDEF; // not a croak
		RETVAL = res;
	OUTPUT:
		RETVAL

int
stringTracerWhen(char *val)
	CODE:
		clearErrMsg();
		int res = Unit::stringTracerWhen(val);
		try { do {
			if (res == -1)
				throw Exception::f("Triceps::stringTracerWhen: bad TracerWhen string '%s'", val);
		} while(0); } TRICEPS_CATCH_CROAK;
		RETVAL = res;
	OUTPUT:
		RETVAL

int
stringTracerWhenSafe(char *val)
	CODE:
		clearErrMsg();
		int res = Unit::stringTracerWhen(val);
		if (res == -1)
			XSRETURN_UNDEF; // not a croak
		RETVAL = res;
	OUTPUT:
		RETVAL

int
humanStringTracerWhen(char *val)
	CODE:
		clearErrMsg();
		int res = Unit::humanStringTracerWhen(val);
		try { do {
			if (res == -1)
				throw Exception::f("Triceps::humanStringTracerWhen: bad human-readable TracerWhen string '%s'", val);
		} while(0); } TRICEPS_CATCH_CROAK;
		RETVAL = res;
	OUTPUT:
		RETVAL

int
humanStringTracerWhenSafe(char *val)
	CODE:
		clearErrMsg();
		int res = Unit::humanStringTracerWhen(val);
		if (res == -1)
			XSRETURN_UNDEF; // not a croak
		RETVAL = res;
	OUTPUT:
		RETVAL

int
stringIndexId(char *val)
	CODE:
		clearErrMsg();
		int res = IndexType::stringIndexId(val);
		try { do {
			if (res == -1)
				throw Exception::f("Triceps::stringIndexId: bad index id string '%s'", val);
		} while(0); } TRICEPS_CATCH_CROAK;
		RETVAL = res;
	OUTPUT:
		RETVAL

int
stringIndexIdSafe(char *val)
	CODE:
		clearErrMsg();
		int res = IndexType::stringIndexId(val);
		if (res == -1)
			XSRETURN_UNDEF; // not a croak
		RETVAL = res;
	OUTPUT:
		RETVAL

int
stringAggOp(char *val)
	CODE:
		clearErrMsg();
		int res = Aggregator::stringAggOp(val);
		try { do {
			if (res == -1)
				throw Exception::f("Triceps::stringAggOp: bad aggregation opcode string '%s'", val);
		} while(0); } TRICEPS_CATCH_CROAK;
		RETVAL = res;
	OUTPUT:
		RETVAL

int
stringAggOpSafe(char *val)
	CODE:
		clearErrMsg();
		int res = Aggregator::stringAggOp(val);
		if (res == -1)
			XSRETURN_UNDEF; // not a croak
		RETVAL = res;
	OUTPUT:
		RETVAL


############ conversions of constants back to string #############################

char *
opcodeString(int val)
	CODE:
		clearErrMsg();
		const char *res = Rowop::opcodeString(val); // never returns NULL
		RETVAL = (char *)res;
	OUTPUT:
		RETVAL

#// exactly the same as opcodeString, just for the consistent naming
char *
opcodeStringSafe(int val)
	CODE:
		clearErrMsg();
		const char *res = Rowop::opcodeString(val); // never returns NULL
		RETVAL = (char *)res;
	OUTPUT:
		RETVAL

char *
ocfString(int val)
	CODE:
		clearErrMsg();
		const char *res = Rowop::ocfString(val, NULL);
		try { do {
			if (res == NULL)
				throw Exception::f("Triceps::ocfString: opcode flag value '%d' not defined in the enum", val);
		} while(0); } TRICEPS_CATCH_CROAK;
		RETVAL = (char *)res;
	OUTPUT:
		RETVAL

char *
ocfStringSafe(int val)
	CODE:
		clearErrMsg();
		const char *res = Rowop::ocfString(val, NULL);
		if (res == NULL)
			XSRETURN_UNDEF; // not a croak
		RETVAL = (char *)res;
	OUTPUT:
		RETVAL

char *
emString(int val)
	CODE:
		clearErrMsg();
		const char *res = Gadget::emString(val, NULL);
		try { do {
			if (res == NULL)
				throw Exception::f("Triceps::emString: enqueueing mode value '%d' not defined in the enum", val);
		} while(0); } TRICEPS_CATCH_CROAK;
		RETVAL = (char *)res;
	OUTPUT:
		RETVAL

char *
emStringSafe(int val)
	CODE:
		clearErrMsg();
		const char *res = Gadget::emString(val, NULL);
		if (res == NULL)
			XSRETURN_UNDEF; // not a croak
		RETVAL = (char *)res;
	OUTPUT:
		RETVAL

char *
tracerWhenString(int val)
	CODE:
		clearErrMsg();
		const char *res = Unit::tracerWhenString(val, NULL);
		try { do {
			if (res == NULL)
				throw Exception::f("Triceps::tracerWhenString: TracerWhen value '%d' not defined in the enum", val);
		} while(0); } TRICEPS_CATCH_CROAK;
		RETVAL = (char *)res;
	OUTPUT:
		RETVAL

char *
tracerWhenStringSafe(int val)
	CODE:
		clearErrMsg();
		const char *res = Unit::tracerWhenString(val, NULL);
		if (res == NULL)
			XSRETURN_UNDEF; // not a croak
		RETVAL = (char *)res;
	OUTPUT:
		RETVAL

char *
tracerWhenHumanString(int val)
	CODE:
		clearErrMsg();
		const char *res = Unit::tracerWhenHumanString(val, NULL);
		try { do {
			if (res == NULL)
				throw Exception::f("Triceps::tracerWhenHumanString: TracerWhen value '%d' not defined in the enum", val);
		} while(0); } TRICEPS_CATCH_CROAK;
		RETVAL = (char *)res;
	OUTPUT:
		RETVAL

char *
tracerWhenHumanStringSafe(int val)
	CODE:
		clearErrMsg();
		const char *res = Unit::tracerWhenHumanString(val, NULL);
		if (res == NULL)
			XSRETURN_UNDEF; // not a croak
		RETVAL = (char *)res;
	OUTPUT:
		RETVAL

char *
indexIdString(int val)
	CODE:
		clearErrMsg();
		const char *res = IndexType::indexIdString(val, NULL);
		try { do {
			if (res == NULL)
				throw Exception::f("Triceps::indexIdString: index id value '%d' not defined in the enum", val);
		} while(0); } TRICEPS_CATCH_CROAK;
		RETVAL = (char *)res;
	OUTPUT:
		RETVAL

char *
indexIdStringSafe(int val)
	CODE:
		clearErrMsg();
		const char *res = IndexType::indexIdString(val, NULL);
		if (res == NULL)
			XSRETURN_UNDEF; // not a croak
		RETVAL = (char *)res;
	OUTPUT:
		RETVAL

char *
aggOpString(int val)
	CODE:
		clearErrMsg();
		const char *res = Aggregator::aggOpString(val, NULL);
		try { do {
			if (res == NULL)
				throw Exception::f("Triceps::aggOpString: aggregation opcode value '%d' not defined in the enum", val);
		} while(0); } TRICEPS_CATCH_CROAK;
		RETVAL = (char *)res;
	OUTPUT:
		RETVAL

char *
aggOpStringSafe(int val)
	CODE:
		clearErrMsg();
		const char *res = Aggregator::aggOpString(val, NULL);
		if (res == NULL)
			XSRETURN_UNDEF; // not a croak
		RETVAL = (char *)res;
	OUTPUT:
		RETVAL

#// Works only on the constant, not on the string value.
int
tracerWhenIsBefore(int val)
	CODE:
		clearErrMsg();
		RETVAL = Unit::tracerWhenIsBefore(val);
	OUTPUT:
		RETVAL

#// Works only on the constant, not on the string value.
int
tracerWhenIsAfter(int val)
	CODE:
		clearErrMsg();
		RETVAL = Unit::tracerWhenIsAfter(val);
	OUTPUT:
		RETVAL

############ time in high resolution #############################################

# Get the current timestamp in high resolution.
double
now()
	CODE:
		timespec tm;
		clock_gettime(CLOCK_REALTIME, &tm);
		RETVAL = (double)tm.tv_sec + (double)tm.tv_nsec / 1000000000.;
	OUTPUT:
		RETVAL

############ sigusr2 handling ####################################################

#// Set up the dummy handler on SIGUSR2, overriding Perl's.
#// Otherwise the recent versions of Perl (like 5.19) crash when
#// they receive a signal at an inopportune time.
void
sigusr2_setup()
	CODE:
		Sigusr2::setup();

