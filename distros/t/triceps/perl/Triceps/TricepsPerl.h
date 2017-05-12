//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
// Helper functions for Perl wrapper.

// ###################################################################################

#ifndef __TricepsPerl_TricepsPerl_h__
#define __TricepsPerl_TricepsPerl_h__

#include <string.h>
#include <wrap/Wrap.h>
#include <common/Conf.h>
#include <common/Strprintf.h>
#include <common/Exception.h>
#include <mem/EasyBuffer.h>

using namespace TRICEPS_NS;

namespace TRICEPS_NS
{
namespace TricepsPerl 
{
// To call Perl_croak() with arbitrary messages, the message must be in the
// memory that will be cleaned by Perl, since croak() does a longjmp and bypasses
// the destructors. It must also be per-thread. Since the Perl variables 
// are per-thread, the value get stored in a Perl variable, and then
// a pointer to that value gets passed to croak().
void setCroakMsg(const std::string &msg);
// Get back the croak message string. It it located in the variable Triceps::_CROAK_MSG.
const char *getCroakMsg();

// Check the contents of the croak message, and if it's set then croak.
// Make sure that no C++ objects requiring destruction are in scope
// when calling this, to avoid the memory leaks.
void croakIfSet();

// Unconditionally croak with the stack trace.
// The message must be a plain pointer to avoid the memory leaks.
// Make sure that no C++ objects requiring destruction are in scope
// when calling this, to avoid the memory leaks.
void croakWithMsg(const char *msg)
	__attribute__noreturn__;

// Clear the Triceps::_CROAK_MSG.
// CURRENTLY IT DOES NOTHING BUT THE CONVENTION IS STILL TO CALL IT 
// AT THE START OF EVERY XS FUNCTION, in case if the actual clearing
// would ever need to be enabled again.
inline void clearErrMsg()
{ }

// Copy a Perl scalar (numeric) SV value into a memory buffer.
// @param ti - field type selection
// @param val - SV to copy from
// @param bytes - memory buffer to copy to, must be large enough
// @return - true if set OK, false if value was non-numeric
bool svToBytes(Type::TypeId ti, SV *val, char *bytes);

// Convert a Perl value (scalar or list) to a buffer
// with raw bytes suitable for setting into a record.
// Does NOT check for undef, the caller must do that before.
// Also silently allows to set the arrays for the scalar fields
// and scalars into arrays.
//
// Checks for other conversion errors and throws an Exception.
// 
// @param ti - field type selection
// @param arg - value to post to, must be already checked for SvOK
// @param fname - field name, for error messages
// @return - new buffer (with size_ set)
EasyBuffer *valToBuf(Type::TypeId ti, SV *arg, const char *fname);

// Convert a byte buffer from a row to a Perl value.
// @param ti - id of the simple type
// @param arsz - array size, affects the resulting value:
//        Type::AR_SCALAR - returns a scalar
//        anything else - returns an array reference
//        (except that TT_STRING and TT_UINT8 are always returned as Perl scalar strings)
// @param notNull - if false, returns an undef (suiitable for putting in an array)
// @param data - the raw data buffer
// @param dlen - data buffer length
// @param fname - field name, for error messages
// @return - a new SV
SV *bytesToVal(Type::TypeId ti, int arsz, bool notNull, const char *data, intptr_t dlen, const char *fname);

// Parse an option value of reference to array into a NameSet
// On error throws an Exception.
// @param funcName - calling function name, for error messages
// @param optname - option name of the originating value, for error messages
// @param ref - option value (will be checked for being a reference to array)
// @return - the parsed NameSet
Onceref<NameSet> parseNameSet(const char *funcName, const char *optname, SV *optval);

// Parse an enqueuing mode as an integer or string constant to an enum.
// On error throws an Exception.
// @param funcName - calling function name, for error messages
// @param enqMode - SV containing the value to parse
// @return - the parsed value
Gadget::EnqMode parseEnqMode(const char *funcName, SV *enqMode);

// Parse an opcode as an integer or string constant to an enum.
// On error throws an Exception.
// @param funcName - calling function name, for error messages
// @param opcode - SV containing the value to parse
// @return - the parsed value
Rowop::Opcode parseOpcode(const char *funcName, SV *opcode);

// Parse an IndexId as an integer or string constant to an enum.
// On error throws an Exception.
// @param funcName - calling function name, for error messages
// @param idarg - SV containing the value to parse
// @return - the parsed value
IndexType::IndexId parseIndexId(const char *funcName, SV *idarg);

// Enqueue one argument in a unit. The argument may be either a Rowop or a Tray,
// detected automatically.
// On error throws an Exception.
// @param funcName - calling function name, for error messages
// @param u - unit where to enqueue
// @param mark - loop mark, if not NULL then used to fork at this frame and em 
//     is ignored
// @param em - enqueuing mode (used if mark is not NULL)
// @param arg - argument (should be Rowop or Tray reference)
// @param i - argument number, for error messages
void enqueueSv(char *funcName, Unit *u, FrameMark *mark, Gadget::EnqMode em, SV *arg, int i);

// The Unit::Tracer subclasses hierarchy is partially exposed to Perl. So an Unit::Tracer
// object can not be returned to Perl by a simple wrapping and blessing to a fixed class.
// Instead its recognised subclasses must be blessed to the correct Perl classes.
// This function returns the correct perl class for blessing.
// @param tr - tracer object (must not be NULL!!!)
// @return - perl class name, in a static string (which must be never modified!)
char *translateUnitTracerSubclass(const Unit::Tracer *tr);

// A common macro to print the contents of assorted objects.
// See RowType.xs for an example of usage
#define GEN_PRINT_METHOD(subtype)  \
		static char funcName[] =  "Triceps::" #subtype "::print"; \
		try { \
			clearErrMsg(); \
			subtype *rt = self->get(); \
			\
			if (items > 3) { \
				throw Exception::f("Usage: %s(self [, indent  [, subindent ] ])", funcName); \
			} \
			\
			string indent, subindent; \
			const string *indarg = &indent; \
			\
			if (items > 1) { /* parse indent */ \
				if (SvOK(ST(1))) { \
					const char *p; \
					STRLEN len; \
					p = SvPV(ST(1), len); \
					indent.assign(p, len); \
				} else { \
					indarg = &NOINDENT; \
				} \
			} \
			if (items > 2) { /* parse subindent */ \
				const char *p; \
				STRLEN len; \
				p = SvPV(ST(2), len); \
				subindent.assign(p, len); \
			} else { \
				subindent.assign("  "); \
			} \
			\
			string res; \
			rt->printTo(res, *indarg, subindent); \
			XPUSHs(sv_2mortal(newSVpvn(res.c_str(), res.size()))); \
		} TRICEPS_CATCH_CROAK;

// A common macro to catch the Triceps::Exception and convert it to a croak.
// Use:
//
// try {
//     ... some code ...
// } TRICEPS_CATCH_CROAK;
//
// Make sure to define all your C++ variables with destructors inside the try block!!!
#define TRICEPS_CATCH_CROAK \
	catch (Exception e) { \
		setCroakMsg(e.getErrors()->print()); \
		croakIfSet(); \
	}

// object parsing and conversion {

// Get the pointer to a Triceps class wrap object from a Perl SV value.
// Throws a Triceps::Exception if the value is incorrect.
//
// It is structured as two parts:
// * the macro that manipulates the class names, so that multiple versions
//   of them don't have to be specified explicitly
// * the template that does the actual work
//
// An example of use:
//   Unit *u = TRICEPS_GET_WRAP(Unit, ST(i), "%s: option '%s'", funcName, optName)->get();
//
// @param TClass - type of object, whose wrapper is to be extracted from SV
// @param svptr - the Perl SV* from which the value will be extracted
// @param fmt, ...  - the custom initial part for the error messages in the exception
// @return - the Triceps wrapper class for which the value is being extracted;
//           guaranteed to be not NULL, so get() can be called on it right away
//           (the reason for not returning the value from the wrapper is that
//           for some wrappers there is also a type to get from it)
#define TRICEPS_GET_WRAP(TClass, svptr, ...) GetSvWrap<TRICEPS_NS::Wrap##TClass>(svptr, #TClass, __VA_ARGS__)

// @param WrapClass - the perl wrapper class around the Triceps class
// @param var - variable to return the pointer to the object
// @param svptr - Perl value to get the object from
// @param className - name of the TClass as a string, for error messages
// @param fmt, ... - the prefix for the error message
// @return - the Triceps wrapper class for which the value is being extracted
template<class WrapClass>
WrapClass *GetSvWrap(SV *svptr, const char *className, const char *fmt, ...)
	__attribute__((format(printf, 3, 4)));

template<class WrapClass>
WrapClass *GetSvWrap(SV *svptr, const char *className, const char *fmt, ...)
{
	if (!sv_isobject(svptr) || SvTYPE(SvRV(svptr)) != SVt_PVMG) {
		va_list ap;
		va_start(ap, fmt);
		string s = vstrprintf(fmt, ap);
		va_end(ap);
		throw Exception(strprintf("%s value must be a blessed SV reference to Triceps::%s", 
			s.c_str(), className), false);
	}
	WrapClass *wvar = (WrapClass *)SvIV((SV*)SvRV( svptr ));
	if (wvar == NULL || wvar->badMagic()) {
		va_list ap;
		va_start(ap, fmt);
		string s = vstrprintf(fmt, ap);
		va_end(ap);
		throw Exception(strprintf("%s value has an incorrect magic for Triceps::%s", s.c_str(), className), false);
	}
	return wvar;
}

// Get the pointer to a Triceps class wrap object from a Perl SV value
// that may be one of 2 types. One of the result pointers will be
// populated, the other will be NULL.
// Throws a Triceps::Exception if the value is neither.
//
// It is structured as two parts:
// * the macro that manipulates the class names, so that multiple versions
//   of them don't have to be specified explicitly
// * the template that does the actual work
//
// An example of use (different from TRICEPS_GET_WRAP):
//   TRICEPS_GET_WRAP2(Label, wlb, RowType, wrt, ST(i), "%s: option '%s'", funcName, optName);
//
// @param TClass1 - type 1 of object, whose wrapper is to be extracted from SV
// @param wrap1 - reference to return the value of type 1
// @param TClass2 - type 2 of object, whose wrapper is to be extracted from SV
// @param wrap2 - reference to return the value of type 2
// @param svptr - the Perl SV* from which the value will be extracted
// @param fmt, ...  - the custom initial part for the error messages in the exception
// @return - the Triceps wrapper class for which the value is being extracted;
//           guaranteed to be not NULL, so get() can be called on it right away
//           (the reason for not returning the value from the wrapper is that
//           for some wrappers there is also a type to get from it)
#define TRICEPS_GET_WRAP2(TClass1, wrap1, TClass2, wrap2, svptr, ...) GetSvWrap2<TRICEPS_NS::Wrap##TClass1, TRICEPS_NS::Wrap##TClass2>(wrap1, wrap2, svptr, #TClass1, #TClass2, __VA_ARGS__)

// @param WrapClass1 - wrap type 1 of object, that is to be extracted from SV
// @param WrapClass2 - wrap type 2 of object, that is to be extracted from SV
// @param wrap1 - reference to return the value of type 1
// @param wrap2 - reference to return the value of type 2
// @param svptr - Perl value to get the object from
// @param className1 - name of the TClass1 as a string, for error messages
// @param className2 - name of the TClass2 as a string, for error messages
// @param fmt, ... - the prefix for the error message
// @return - the Triceps wrapper class for which the value is being extracted
template<class WrapClass1, class WrapClass2>
void GetSvWrap2(WrapClass1 *&wrap1, WrapClass2 *&wrap2, SV *svptr, const char *className1, const char *className2, const char *fmt, ...)
	__attribute__((format(printf, 6, 7)));

template<class WrapClass1, class WrapClass2>
void GetSvWrap2(WrapClass1 *&wrap1, WrapClass2 *&wrap2, SV *svptr, const char *className1, const char *className2, const char *fmt, ...)
{
	if (!sv_isobject(svptr) || SvTYPE(SvRV(svptr)) != SVt_PVMG) {
		va_list ap;
		va_start(ap, fmt);
		string s = vstrprintf(fmt, ap);
		va_end(ap);
		throw Exception(strprintf("%s value must be a blessed SV reference to Triceps::%s or Triceps::%s", 
			s.c_str(), className1, className2), false);
	}

	IV ref = SvIV((SV*)SvRV( svptr ));
	wrap1 = (WrapClass1 *)ref;
	wrap2 = (WrapClass2 *)ref;
	if (ref) {
		if (!wrap1->badMagic()) {
			wrap2 = NULL;
		} else if (!wrap2->badMagic()) {
			wrap1 = NULL;
		} else {
			ref = 0;
		}
	}
	if (ref == 0) {
		va_list ap;
		va_start(ap, fmt);
		string s = vstrprintf(fmt, ap);
		va_end(ap);
		throw Exception(strprintf("%s value has an incorrect magic for either Triceps::%s or Triceps::%s", 
			s.c_str(), className1, className2), false);
	}
}

// Extract a string from a Perl SV value.
// Throws a Triceps::Exception if the value is not SvPOK().
//
// @param res - variable to return the string into
// @param svptr - the Perl SV* from which the value will be extracted
// @param fmt, ... - the prefix for the error message
void GetSvString(string &res, SV *svptr, const char *fmt, ...)
	__attribute__((format(printf, 3, 4)));

// Extract an int from a Perl SV value.
// Throws a Triceps::Exception if the value is not SvIOK().
//
// @param svptr - the Perl SV* from which the value will be extracted
// @param fmt, ... - the prefix for the error message
// @return - the int value
IV GetSvInt(SV *svptr, const char *fmt, ...)
	__attribute__((format(printf, 2, 3)));

// Extract an array reference from a Perl SV value.
// Throws a Triceps::Exception if the value is not an array reference.
//
// @param svptr - the Perl SV* from which the value will be extracted
// @param fmt, ... - the prefix for the error message
// @return - the array pointer
AV *GetSvArray(SV *svptr, const char *fmt, ...)
	__attribute__((format(printf, 2, 3)));

// Extract an array or hash reference from a Perl SV value.
// Throws a Triceps::Exception if the value is not an array nor hash reference.
// On success, one of array ro hash will contain the value, the other will be NULL.
//
// @param array - place to return the value if the svptr is an array reference
// @param hash - place to return the value if the svptr is a hash reference
// @param svptr - the Perl SV* from which the value will be extracted
// @param fmt, ... - the prefix for the error message
// @return - the array pointer
void GetSvArrayOrHash(AV *&array, HV *&hash, SV *svptr, const char *fmt, ...)
	__attribute__((format(printf, 4, 5)));

// Also see GetSvCode in PerlCallback.h. It's placed there to avoid
// introducing extra dependencies between the header files.

// The typical argument for binding or function returns: either a
// ready label or a Perl code reference (for which a label will be
// created automatically).
// Throws a Triceps::Exception if the value is not correct.
//
// @param svptr - the Perl SV* from which the value will be extracted
// @param fmt, ... - the prefix for the error message
// @return - the label pointer (not WrapLabel!); since the code reference
//     SV doesn't need any transformations to be used in a label, the case
//     when NULL is returned but no exception thrown means that the svptr
//     is a code reference.
Label *GetSvLabelOrCode(SV *svptr, const char *fmt, ...)
	__attribute__((format(printf, 2, 3)));

// } object parsing and conversion

}; // Triceps::TricepsPerl
}; // Triceps

using namespace TRICEPS_NS::TricepsPerl;

#endif // __TricepsPerl_TricepsPerl_h__
