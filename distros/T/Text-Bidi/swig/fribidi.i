%module "Text::Bidi::private"
/*
 * Swig interface file for libfribidi
 * ==================================
 *
 * This interface file was designed for building a perl module, but should be 
 * easily adaptable to other languages.
 *
 * The general form of some functions in libfribidi is that an input string 
 * is supplied together with its length, as well as some pointer for the 
 * outputs of the function, which are arrays of the same length. Thus, the 
 * same integer parameter specifies the length of several arrays. We deal 
 * with it in the following way (adapted from list-vector.i in the guile part 
 * of the swig distribution):
 * The length is an "ignore" argument (numinputs=0), whose translation thus 
 * appears near the beginning. We allocate a (function-) global variable to 
 * hold the value in its typemap. The input string is then dealt with using a 
 * usual "in" typemap, which assigns values both to the string and to the 
 * global variable representing the length. Finally, the output string are 
 * allocated in a check typemap, which guarantees that the length is already 
 * initialised.
 *
 * Some of the outputs are optional, depending on wether we are in array or 
 * scalar context. To adapt it for other languages, it should only be 
 * necessary to modify the WANTARRAY macro.
 */

%include "typemaps.i"
%include "stdint.i"
%import "fribidi-types.h"

%{
#include <limits.h>
#include <fribidi.h>
%}

/* Version strings belong to the library and must not have setters. */
%immutable fribidi_unicode_version;
%immutable fribidi_version_info;

/**************************************************************/

/* string output */
%define OUTSTR(Type, NEWOPT)
  %typemap(in,numinputs=0) Type* NEWOPT ($1_ltype* temp) %{
    temp = &$1;
  %}

  %typemap(check) Type* NEWOPT %{
    Newx(*temp$argnum, ((*_global_p_len) + 1), $*1_ltype);
  %}

  %typemap(argout) Type* NEWOPT %{
    MXPUSHP((const char *)($1), 
            (STRLEN)( (result) * sizeof($*1_ltype)));
  %}

  %typemap(freearg) Type* NEWOPT %{
    if ($1) Safefree($1);
  %}
%enddef

%define OUTARR(Type, NEWOPT)
  %typemap(in,numinputs=0) Type* NEWOPT ($1_ltype* temp) %{
    temp = &$1;
  %}

  %typemap(check) Type* NEWOPT %{
    Newxz(*temp$argnum, ((STRLEN)*_global_p_len + 1), $*1_ltype);
  %}

  %typemap(argout) Type* NEWOPT %{
  // printf("Pushing into $1\n");
    MXPUSHUA($1,(*_global_p_len));
  %}

  %typemap(freearg) Type* NEWOPT %{
    if ($1) Safefree($1);
  %}
%enddef

OUTARR(FriBidiCharType, btypes);
OUTARR(FriBidiBracketType, btypes);
OUTARR(FriBidiJoiningType, jtypes);
OUTARR(FriBidiLevel, embedding_levels);
    
OUTSTR(FriBidiChar, out);
OUTSTR(char, out);

%typemap(check) char* out %{
  Newx(*temp$argnum, 2*((*_global_p_len) + 1), $*1_ltype);
%}

OUTSTR(char, utf8out);

/* the size of the output string may grow because of control seqs. */
%typemap(check) char* utf8out %{
  Newx(*temp$argnum, 4*((*_global_p_len) + 1), $*1_ltype);
%}

%typemap(in,numinputs=0) const FriBidiStrIndex len (FriBidiStrIndex* _global_p_len) %{
  $1 = 0;
  _global_p_len = &$1;
%}

%typemap(in) const FriBidiChar* str (char* buf = 0, STRLEN size = 0) %{
  buf = SvPVbyte($input, size);
  if (size % sizeof($*1_ltype) || size/sizeof($*1_ltype) > INT_MAX)
    SWIG_exception_fail(SWIG_ValueError, "Invalid packed array length");
  *_global_p_len = (FriBidiStrIndex)(size/sizeof($*1_ltype));
  $1 = ($1_ltype)(buf);
%}

%typemap(check) const FriBidiChar* str %{
  if (size$argnum/sizeof($*1_ltype) != (STRLEN)*_global_p_len)
    SWIG_exception_fail(SWIG_ValueError, "Packed arrays must have equal lengths");
%}

%apply const FriBidiChar* str { const FriBidiCharType* bidi_types }
%apply unsigned int { FriBidiChar ch }
%apply unsigned int *OUTPUT { FriBidiChar *mirrored_ch }

/* Secondary arrays must not change the paragraph length. */
%typemap(in) const FriBidiBracketType* bracket_types (STRLEN size = 0) %{
  $1 = ($1_ltype)SvPVbyte($input, size);
%}
%typemap(check) const FriBidiBracketType* bracket_types %{
  if (size$argnum != (STRLEN)*_global_p_len * sizeof($*1_ltype))
    SWIG_exception_fail(SWIG_ValueError, "Packed arrays must have equal lengths");
%}
%apply const FriBidiBracketType* bracket_types { const FriBidiCharType* types }

%typemap(check) const FriBidiLevel* embedding_levels ""
%typemap(argout) const FriBidiLevel* embedding_levels ""
%typemap(freearg) const FriBidiLevel* embedding_levels ""

%apply const FriBidiChar* str { const FriBidiLevel* embedding_levels }

/* input/output str, length not determined by str (e.g., shape_mirroring) */
%typemap(in) FriBidiChar* str (STRLEN size = 0, char *buf = 0) %{
  buf = SvPVbyte($input, size);
  $1 = ($1_ltype)SvPVX(sv_2mortal(newSVpvn(buf, size)));
%}

%typemap(check) FriBidiChar* str %{
  if (size$argnum != (STRLEN)*_global_p_len * sizeof($*1_ltype))
    SWIG_exception_fail(SWIG_ValueError, "Packed arrays must have equal lengths");
%}

%typemap(argout) FriBidiChar* str %{
  MXPUSHP((const char *)($1), (STRLEN)( (*_global_p_len) * sizeof($*1_ltype)));
%}

/* input/output str, length determined by str (e.g., remove_bidi_marks) */
%typemap(in) FriBidiChar* strl (char* buf = 0, size_t size = 0) %{
  buf = SvPV($input, size);
  *_global_p_len = (FriBidiStrIndex)(size/sizeof($*1_ltype));
  $1 = ($1_ltype)(buf);
%}

%typemap(argout) FriBidiChar* strl %{
  MXPUSHP((const char *)($1), (STRLEN)( (*_global_p_len) * sizeof($*1_ltype)));
%}


%typemap(argout) const FriBidiChar* str ""


%typemap(default) FriBidiParType* pbase_dir (FriBidiParType temp) %{
  temp = FRIBIDI_PAR_ON;
  $1 = &temp;
%}

%apply unsigned int *INOUT { FriBidiParType* pbase_dir }

%typemap(in) FriBidiLevel *emb_levels (STRLEN size = 0, char *buf = 0) %{
  buf = SvPVbyte($input, size);
  $1 = ($1_ltype)SvPVX(sv_2mortal(newSVpvn(buf, size)));
%}

%typemap(check) FriBidiLevel *emb_levels %{
  if (size$argnum != (STRLEN)*_global_p_len * sizeof($*1_ltype))
    SWIG_exception_fail(SWIG_ValueError, "Packed arrays must have equal lengths");
%}

%typemap(argout) FriBidiLevel *emb_levels %{
  MXPUSHUA($1, (*_global_p_len))
%}

%apply FriBidiLevel *emb_levels { FriBidiStrIndex *map }

%apply const FriBidiChar* str { const char* s }

%apply int { FriBidiStrIndex }
%apply unsigned int { FriBidiFlags, FriBidiParType, FriBidiCharType, FriBidiBracketType }
%apply unsigned char { FriBidiJoiningType }


%rename("%(strip:[fribidi_])s") "";

%import "fribidi-common.h"
%include "fribidi-unicode.h"
%include "fribidi-bidi-types.h"
%include "fribidi-flags.h"
%include "fribidi-joining-types.h"
%include "fribidi-mirroring.h"
%include "fribidi-brackets.h"
/* reorder_map supplies initialized levels and a full-paragraph map. */
%ignore fribidi_reorder_line;
%include "fribidi-bidi.h"

%apply FriBidiLevel *emb_levels { FriBidiArabicProp *ar_props }

%include "fribidi-joining.h"
%include "fribidi-arabic.h"
%include "fribidi-shape.h"
%include "fribidi-deprecated.h"

%apply FriBidiStrIndex *map { FriBidiStrIndex *positions_to_this, 
                              FriBidiStrIndex *position_from_this_list }
%inline %{
//%define WANTARRAY
//(GIMME_V == G_ARRAY)
//%enddef

#ifndef Newx
#define Newx(A,B,C) New(42,A,B,C)
#endif
/* Macros for pushing return arguments on the stack. These are available only  
 * in recent versions of perl
 */

/* push (and mortalise) an SV */
#define TEXT_BIDI_PUSH(VAL) \
  if (argvi >= items)\
    EXTEND(sp, 1);\
  ST(argvi)=sv_2mortal(VAL);\
  argvi++

/* push an unsigned int */
#define MXPUSHU(uv) TEXT_BIDI_PUSH(newSVuv(uv))

/* push string pv of length len */
#define MXPUSHP(pv,len) TEXT_BIDI_PUSH(newSVpvn(pv,len))

/* push a ref to an sv */
#define MXPUSHR(sv) TEXT_BIDI_PUSH(newRV_noinc((SV *)sv))

/* push an array (ref) of unsigned (of length len) */
#define MXPUSHUA(ua,len) {\
    AV* tempav = newAV();\
    int i;\
    for(i=0 ; i < len ; i++) {\
      av_push(tempav, newSVuv(ua[i]));}\
    MXPUSHR(tempav);\
  }

#include <fribidi.h>

FriBidiStrIndex utf8_to_internal (const char *s, const FriBidiStrIndex len,
                       /* Output */
                       FriBidiChar *out) {
  return fribidi_charset_to_unicode(FRIBIDI_CHAR_SET_UTF8, s, len, out);
}

FriBidiStrIndex internal_to_utf8 (const FriBidiChar *str, const FriBidiStrIndex len,
                       /* Output */
                       char *utf8out) {
  return fribidi_unicode_to_charset(FRIBIDI_CHAR_SET_UTF8, str, len, utf8out);
}

FriBidiLevel reorder_map (const FriBidiFlags flags,
    const FriBidiCharType *bidi_types, const FriBidiStrIndex len,
    const FriBidiStrIndex off,
    const FriBidiStrIndex length,      const FriBidiParType base_dir,
    FriBidiLevel *emb_levels,          FriBidiStrIndex *map) {
  if (off < 0 || length < 0 || off > len || length > len - off)
    croak("Line range is outside the paragraph");
  return fribidi_reorder_line(
      flags, bidi_types, length, off, base_dir, emb_levels, NULL, map);
}


extern const char *fribidi_version_info;

%}


/* vim: set fo-=t comments-=\:% cindent sw=2: */

