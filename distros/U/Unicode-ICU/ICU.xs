/*
 * Copyright 2022 cPanel, LLC. (copyright@cpanel.net)
 * Author: Felipe Gasper
 *
 # Copyright (c) 2022, cPanel, LLC.
 # All rights reserved.
 # http://cpanel.net
 #
 # This is free software; you can redistribute it and/or modify it under the
 # same terms as Perl itself. See L<perlartistic>.
 */

#pragma clang diagnostic ignored "-Wcompound-token-split-by-macro"

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <stdbool.h>
#include <string.h>

#include <unicode/uversion.h>

#include "unicode_icu.h"

#ifdef UICU_HAS_MESSAGEPATTERN
#include "unicode_icu_messagepattern.h"
#endif

#include <unicode/uidna.h>
#include <unicode/uloc.h>
#include <unicode/uenum.h>
#include <unicode/ustring.h>

#ifdef UICU_CAN_FORMAT_LISTS
#include <unicode/ulistformatter.h>
#endif

// Since this file is compiled as C++, not C, we can use this:
#include <vector>

// For debugging:
// #include <unicode/ustdio.h>

#ifdef UICU_HAS_MESSAGEPATTERN
typedef struct {
    perl_uicu_messagepattern_part* ptr;
    SV* msg_pattern_sv;
} perl_uicu_mpat_part_struct;
#endif

#define _loc_id_from_sv(loc_id_sv) \
    (SvOK(loc_id_sv) ? SvPVbyte_nolen(loc_id_sv) : NULL)

#define PERL_NAMESPACE "Unicode::ICU"
#define PERL_ERROR_NAMESPACE PERL_NAMESPACE "::X"

#define my_utf8_decode_or_croak(sv) STMT_START { \
    if (!sv_utf8_decode(sv)) croak("ICU returned invalid UTF-8?!?"); \
} STMT_END

#define _warn_if_global_destruct(self_sv) \
    if (PL_dirty) warn("DESTROY at DESTRUCT: %" SVf, self_sv);

#define NV_IS_PLAIN_DOUBLE (sizeof(NV) == sizeof(double))

// C99 defines variable-length arrays, but C++ never did.
// g++ allows them anyway, but not all C++ compilers do.
// For broader compatibility, then, we’ll avoid VLAs but
// mimic them with C++ vectors.
//
#define MAKE_VLA_VIA_VECTOR(name, size, type)   \
    std::vector<type> vector_##name(size);      \
    type *name = vector_##name.data();

/*
 * We do as much as we can here in C, but some of ICU’s functionality
 * is only available from C++. See unicode_icu.cc for those parts.
 */

// ----------------------------------------------------------------------

static void _throw_typed_error_xs( pTHX_ const char* type, SV** args ) {
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs( newSVpvs_flags(PERL_ERROR_NAMESPACE, SVs_TEMP) );
    XPUSHs( newSVpvn_flags(type, strlen(type), SVs_TEMP) );
    SV* arg;
    while ( (arg = *args++) ) {
        XPUSHs( sv_mortalcopy(arg) );
    }
    PUTBACK;

    I32 got = call_method("create", G_SCALAR);
    PERL_UNUSED_ARG(got);

    SPAGAIN;

    assert(got == 1);

    SV* err = SvREFCNT_inc(POPs);

    croak_sv(err);

    assert(0); // Should have croaked already!
}

// ----------------------------------------------------------------------

// A “blessed struct” is an SVPV that stores a C struct, wrapped in a
// reference SV with a bless(). This allows Perl itself to do the
// allocating and freeing of the struct, which simplfies memory management.

#define my_new_blessedstruct(type, classname) _my_new_blessedstruct_f(aTHX_ sizeof(type), classname)

#define my_get_blessedstruct_ptr(svrv) ( (void *) SvPVX( SvRV(svrv) ) )

static SV* _my_new_blessedstruct_f (pTHX_ unsigned size, const char* classname) {

    SV* referent = newSV(size);
    SvPOK_on(referent);

    SV* reference = newRV_noinc(referent);
    sv_bless(reference, gv_stashpv(classname, FALSE));

    return reference;
}

// ----------------------------------------------------------------------

#define _handle_uerr(...)  __handle_uerr(aTHX_ __VA_ARGS__);

static void __handle_uerr( pTHX_ UErrorCode uerr, const char* funcname, const char* msg, ... ) {
    if (U_FAILURE(uerr)) {
        SV* funcname_sv = newSVpvn_flags( funcname, strlen(funcname), SVs_TEMP );
        SV* args[] = {
            funcname_sv,
            sv_2mortal( newSViv(uerr) ),
            NULL,
            NULL
        };

        if (msg) {
            va_list ap;
            va_start(ap, msg);

            SV* msgsv = newSVpvs_flags("", SVs_TEMP);
            sv_vcatpvf(msgsv, msg, &ap);

            args[2] = msgsv;
        }

        _throw_typed_error_xs( aTHX_ "ICU", args );

        assert(0);
    }

    // Don’t bother with the NUL-termination warning:
    if (uerr != U_ZERO_ERROR && uerr != U_STRING_NOT_TERMINATED_WARNING && uerr != U_USING_DEFAULT_WARNING && uerr != U_USING_FALLBACK_WARNING) {
        va_list ap;
        va_start(ap, msg);

        SV* msgsv = newSVpvf("ICU warning (%s): %s", funcname, u_errorName(uerr));
        if (msg) {
            va_list ap;
            va_start(ap, msg);

            sv_vcatpvf(msgsv, msg, &ap);
        }

        sv_2mortal(msgsv);

        warn_sv(msgsv);
    }
}

static inline SV* _uchar_array_to_mortal_sv( pTHX_ const UChar* in, U32 chars_count ) {

    UErrorCode uerr = U_ZERO_ERROR;

    int32_t utf8_length;

    u_strToUTF8(
        NULL, 0,
        &utf8_length,
        in, chars_count,
        &uerr
    );

    assert( uerr == U_BUFFER_OVERFLOW_ERROR );

    SV* retval = newSV(utf8_length);
    sv_2mortal(retval);

    uerr = U_ZERO_ERROR;

    u_strToUTF8(
        SvPVX(retval), utf8_length + 1,
        &utf8_length,
        in, chars_count,
        &uerr
    );

    _handle_uerr(uerr, "u_strToUTF8", NULL);

    SvCUR_set(retval, utf8_length);
    SvPOK_on(retval);

    my_utf8_decode_or_croak(retval);

    return retval;
}

#define _croak_empty_utf8len() STMT_START { \
    croak("%s: Empty string given!", __func__); \
} STMT_END

// To call this, pre-allocate a buffer that’s 2 * utf8len bytes.
// Returns the # of elements in dest.
//
// This does *not* assume/require NUL termination.
//
static inline void utf8_to_uchar_or_croak(pTHX_ const char* utf8, int32_t utf8len, UChar* dest, int32_t destlen) {
    UErrorCode uerr = U_ZERO_ERROR;

    if (!utf8len) _croak_empty_utf8len();

    u_strFromUTF8( dest, destlen, NULL, utf8, utf8len, &uerr );
    _handle_uerr(uerr, "u_strFromUTF8", NULL);
}

static int32_t utf8_to_uchar_len_or_croak(pTHX_ const char* utf8, int32_t utf8len) {
    int32_t destlen;
    UErrorCode uerr = U_ZERO_ERROR;

    if (!utf8len) _croak_empty_utf8len();

    u_strFromUTF8( NULL, 0, &destlen, utf8, utf8len, &uerr );
    if (uerr != U_BUFFER_OVERFLOW_ERROR) {
        _handle_uerr(uerr, "u_strFromUTF8", NULL);
    }

    return destlen;
}

static SV* _to_svuvptr (pTHX_ void* ptr, const char* classname) {
    SV* referent = newSVuv( (UV) ptr );
    SV* retval = newRV_noinc(referent);

    sv_bless(retval, gv_stashpv(classname, FALSE));

    return retval;
}

static void* _from_svuvptr (pTHX_ SV* self_sv) {
    return (void *) SvUV( SvRV(self_sv) );
}

static inline void _svs_to_uchar_and_lengths(pTHX_ SV** svs, I32 svs_len, const UChar** ustrings, I32 *ustrlens) {
    for (I32 i=0; i<svs_len; i++) {
        SV* curitem = svs[i];

        STRLEN u8len;
        const char* u8 = SvPVutf8(curitem, u8len);

        STRLEN ustrlen = utf8_to_uchar_len_or_croak(aTHX_
            u8,
            u8len
        );

        UChar* ustr;
        Newx(ustr, ustrlen, UChar);
        SAVEFREEPV(ustr);

        utf8_to_uchar_or_croak(aTHX_
            u8, u8len,
            ustr, ustrlen
        );

        ustrings[i] = ustr;
        ustrlens[i] = ustrlen;
    }
}

#ifdef UICU_CAN_FORMAT_LISTS

static
#ifdef UICU_CAN_FORMAT_OR
#define ULISTFMT_FUNC ulistfmt_openForType
SV* _format_list(pTHX_ SV* locale_sv, UListFormatterType type, SV** args, I32 argslen) {
#else
#define ULISTFMT_FUNC ulistfmt_open
SV* _format_list(pTHX_ SV* locale_sv, SV** args, I32 argslen) {
#endif
    const char* locale = _loc_id_from_sv(locale_sv);

    MAKE_VLA_VIA_VECTOR(ustrings, argslen, const UChar*);
    MAKE_VLA_VIA_VECTOR(ustrlens, argslen, I32);

    _svs_to_uchar_and_lengths(aTHX_ args, argslen, ustrings, ustrlens);

    UErrorCode uerr = U_ZERO_ERROR;

#ifdef UICU_CAN_FORMAT_OR
    UListFormatter* lfmt = ULISTFMT_FUNC(locale, type, ULISTFMT_WIDTH_WIDE, &uerr);
#else
    UListFormatter* lfmt = ULISTFMT_FUNC(locale, &uerr);
#endif
    _handle_uerr(uerr, STRINGIFY(ULISTFMT_FUNC), NULL);

    uerr = U_ZERO_ERROR;

    I32 bufsize = ulistfmt_format(
        lfmt, ustrings, ustrlens, argslen, NULL, 0, &uerr
    );
    if (uerr != U_BUFFER_OVERFLOW_ERROR) {
        if (U_FAILURE(uerr)) ulistfmt_close(lfmt);

        _handle_uerr(uerr, "ulistfmt_format", NULL);
    }

    MAKE_VLA_VIA_VECTOR(result, bufsize, UChar);

    uerr = U_ZERO_ERROR;
    ulistfmt_format(
        lfmt, ustrings, ustrlens, argslen, result, bufsize, &uerr
    );
    ulistfmt_close(lfmt);

    _handle_uerr(uerr, "ulistfmt_format", NULL);

    SV* retval = _uchar_array_to_mortal_sv(aTHX_ result, bufsize);

    SvREFCNT_inc(retval);

    return retval;
}
#endif

#ifdef UICU_HAS_MESSAGEPATTERN
static inline const UChar* _mpat_string(pTHX_ perl_uicu_mpat_part_struct* mystruct) {
    SV* msgpattern_sv = mystruct->msg_pattern_sv;

    perl_uicu_messagepattern *mpat = _from_svuvptr(aTHX_ msgpattern_sv);

    I32 len;
    return perl_uicu_mpat_get_pattern_string(mpat, &len);
}
#endif

#ifdef UICU_HAS_UIDNA_OBJECT
typedef int32_t (*idna_converter_t) (
    const UIDNA*,
    const char*, int32_t,
    char*, int32_t,
    UIDNAInfo*, UErrorCode*
);

#define _idn_convert(self_sv, unicode_name, func) \
    __idn_convert_fn(aTHX_ self_sv, unicode_name, func, #func)

static SV* __idn_convert_fn (pTHX_ SV* self_sv, SV* unicode_name, idna_converter_t converter_func, const char* converter_func_name) {
    UIDNA* uidna = (UIDNA*) _from_svuvptr(aTHX_ self_sv);

    STRLEN utf8len;
    const char* name_utf8 = SvPVutf8(unicode_name, utf8len);

    UIDNAInfo uinfo = UIDNA_INFO_INITIALIZER;
    UErrorCode status = U_ZERO_ERROR;

    int32_t asciilen = converter_func(
        uidna,
        name_utf8,
        utf8len,
        NULL,
        0,
        &uinfo,
        &status
    );

    if ( status != U_BUFFER_OVERFLOW_ERROR ) {
        _handle_uerr(status, converter_func_name, NULL);
    }

    // Now that we know the converter itself didn’t error,
    // check for errors in the secondary status object.
    if (uinfo.errors) {
        SV* args[] = {
            unicode_name,
            sv_2mortal( newSVuv(uinfo.errors) ),
            NULL,
        };

        _throw_typed_error_xs(aTHX_ "BadIDN", args );

        assert(0);
    }

    SV* retval = newSV(asciilen);
    SvPOK_on(retval);
    sv_2mortal(retval);

    uinfo = UIDNA_INFO_INITIALIZER;
    status = U_ZERO_ERROR;

    converter_func(
        uidna,
        name_utf8,
        utf8len,
        SvPVX(retval),
        asciilen,
        &uinfo,
        &status
    );

    _handle_uerr(status, converter_func_name, NULL);

    SvCUR_set(retval, asciilen);
    my_utf8_decode_or_croak(retval);

    SvREFCNT_inc(retval);

    return retval;
}
#endif

typedef ULayoutType (*loc_orientation_getter_t) (const char*, UErrorCode*);

#define _get_orientation(loc_id_sv, getter_funcname) \
    __get_orientation( aTHX_ loc_id_sv, getter_funcname, #getter_funcname )

ULayoutType __get_orientation(pTHX_
    SV* loc_id_sv,
    loc_orientation_getter_t getter_func,
    const char* getter_func_name
) {
    const char* loc_id = _loc_id_from_sv(loc_id_sv);

    UErrorCode status = U_ZERO_ERROR;

    ULayoutType lt = getter_func(loc_id, &status);
    _handle_uerr(status, getter_func_name, NULL);

    return lt;
}

#define _handle_uerr_with_parseError(...) \
    __handle_uerr_with_parseError(aTHX_ __VA_ARGS__)

void __handle_uerr_with_parseError(pTHX_
    UErrorCode uerr,
    const char* fn,
    UChar* pattern_uchar,
    int32_t offset
) {
    if (offset >= 0) {
        _handle_uerr(uerr, fn, "offset=%d", u_countChar32(pattern_uchar, offset));
    }
    else {
        _handle_uerr(uerr, fn, NULL);
    }
}

// ----------------------------------------------------------------------

#define _define_locale_iv_constsub(name) \
    newCONSTSUB( gv_stashpvs(PERL_NAMESPACE "::Locale", FALSE), #name, newSVuv(ULOC_##name) );

#define _add_umsgpat_part_type(hv, name) \
    hv_stores(hv, #name, newSViv(UMSGPAT_PART_TYPE_##name));

#define _add_umsgpat_arg_type(hv, name) \
    hv_stores(hv, #name, newSViv(UMSGPAT_ARG_TYPE_##name));

#define _define_idn_uv_constsub(name) \
    newCONSTSUB( gv_stashpvs(PERL_NAMESPACE "::IDN", FALSE), "UIDNA_" #name, newSVuv(UIDNA_##name) );

#define _add_uidna_error(hv, name) \
    hv_stores(hv, #name, newSViv(UIDNA_ERROR_##name));

#define _croak_no_named_arguments() \
    croak(PERL_NAMESPACE " cannot accept named arguments with this version of ICU (" U_ICU_VERSION ").")

// ----------------------------------------------------------------------

MODULE = Unicode::ICU    PACKAGE = Unicode::ICU

PROTOTYPES: DISABLE

BOOT:
    newCONSTSUB( gv_stashpvs("$Package", FALSE), "ICU_VERSION", newSVpvs(U_ICU_VERSION) );
    newCONSTSUB( gv_stashpvs("$Package", FALSE), "ICU_MAJOR_VERSION", newSVuv(U_ICU_VERSION_MAJOR_NUM) );
    newCONSTSUB( gv_stashpvs("$Package", FALSE), "ICU_MINOR_VERSION", newSVuv(U_ICU_VERSION_MINOR_NUM) );

const char*
get_error_name(I32 errnum)
    CODE:
        RETVAL = u_errorName((UErrorCode) errnum);

    OUTPUT:
        RETVAL

# ----------------------------------------------------------------------

MODULE = Unicode::ICU    PACKAGE = Unicode::ICU::Locale

BOOT:
    newCONSTSUB( gv_stashpvs(PERL_NAMESPACE "::Locale", FALSE), "DEFAULT_LOCALE", newSVpv(uloc_getDefault(), 0) );
    _define_locale_iv_constsub(LAYOUT_LTR);
    _define_locale_iv_constsub(LAYOUT_RTL);
    _define_locale_iv_constsub(LAYOUT_TTB);
    _define_locale_iv_constsub(LAYOUT_BTT);
    _define_locale_iv_constsub(LAYOUT_UNKNOWN);

SV*
list_locales()
    CODE:
        int32_t avail_count = uloc_countAvailable();

        AV* retval_referent = newAV();

        av_extend(retval_referent, avail_count);

        int32_t index = 0;

        while (index < avail_count) {
            av_store(retval_referent, index, newSVpv(uloc_getAvailable(index), 0));

            index++;
        }

        RETVAL = newRV_noinc((SV*) retval_referent);

    OUTPUT:
        RETVAL

SV*
get_display_name (SV* loc_id_sv=&PL_sv_undef, SV* disp_loc_id_sv=&PL_sv_undef)
    CODE:
        const char* loc_id = _loc_id_from_sv(loc_id_sv);
        const char* disp_loc_id = _loc_id_from_sv(disp_loc_id_sv);

        UErrorCode err = U_ZERO_ERROR;

        const I32 bufsz = uloc_getDisplayName(loc_id, disp_loc_id, NULL, 0, &err);

        if (err != U_BUFFER_OVERFLOW_ERROR) {
            _handle_uerr(err, "uloc_getDisplayName", NULL);
        }

        // This specific call seems to expect the passed buffer size
        // to be 1 more than the actual size needed, assumedly because
        // it expects to write a NUL character at the end. Without
        // the +1 this would populate the buffer with a truncated-by-1
        // string.
        //
        MAKE_VLA_VIA_VECTOR(name, 1+bufsz, UChar);

        err = U_ZERO_ERROR;

        uloc_getDisplayName(loc_id, disp_loc_id, name, 1 + bufsz, &err);
        _handle_uerr(err, "uloc_getDisplayName", NULL);

        SV* ret = _uchar_array_to_mortal_sv(aTHX_ name, bufsz);

        RETVAL = SvREFCNT_inc(ret);

    OUTPUT:
        RETVAL

IV
get_character_orientation (SV* loc_id_sv=&PL_sv_undef)
    CODE:
        RETVAL = _get_orientation(loc_id_sv, uloc_getCharacterOrientation);

    OUTPUT:
        RETVAL

IV
get_line_orientation (SV* loc_id_sv=&PL_sv_undef)
    CODE:
        RETVAL = _get_orientation(loc_id_sv, uloc_getLineOrientation);

    OUTPUT:
        RETVAL

bool
is_rtl (SV* loc_id_sv=&PL_sv_undef)
    CODE:
        // NB: This doesn’t use ICU’s C<uloc_isRightToLeft()> because
        // we want to check for errors, which that function doesn’t allow.
        //
        ULayoutType lt = _get_orientation(loc_id_sv, uloc_getCharacterOrientation);
        RETVAL = (lt == ULOC_LAYOUT_RTL);

    OUTPUT:
        RETVAL

SV*
canonicalize (SV* loc_id_sv=&PL_sv_undef)
    CODE:
        if (!SvOK(loc_id_sv)) croak("Need locale ID!");

        const char* loc_id = _loc_id_from_sv(loc_id_sv);
        UErrorCode err = U_ZERO_ERROR;

        I32 size = uloc_canonicalize( loc_id, NULL, 0, &err );
        if (err != U_BUFFER_OVERFLOW_ERROR) {
            _handle_uerr(err, "uloc_canonicalize", NULL);
        }

        RETVAL = newSV(size);
        sv_2mortal(RETVAL);

        err = U_ZERO_ERROR;

        uloc_canonicalize( loc_id, SvPVX(RETVAL), 1 + size, &err);
        _handle_uerr(err, "uloc_canonicalize", NULL);

        SvPOK_on(RETVAL);
        SvCUR_set(RETVAL, size);
        SvREFCNT_inc(RETVAL);

    OUTPUT:
        RETVAL

# ----------------------------------------------------------------------

MODULE = Unicode::ICU    PACKAGE = Unicode::ICU::MessageFormat

BOOT:
    newCONSTSUB( gv_stashpvs("Unicode::ICU::MessageFormat", FALSE), "CAN_TAKE_NAMED_ARGUMENTS",
#ifdef UICU_HAS_MESSAGEPATTERN
        &PL_sv_yes
#else
        &PL_sv_no
#endif
    );

SV*
new (SV* classname, SV* locale_sv=&PL_sv_undef)
    CODE:
        const char* locale = _loc_id_from_sv(locale_sv);
        UErrorCode uerr = U_ZERO_ERROR;

        UMessageFormat *fmt = umsg_open(
            (UChar*) "",
            0,
            locale,
            NULL,
            &uerr
        );

        _handle_uerr(uerr, "umsg_open", NULL);

        RETVAL = _to_svuvptr(aTHX_ fmt, SvPVbyte_nolen(classname));

    OUTPUT:
        RETVAL

void
DESTROY (SV* self_sv)
    CODE:
        _warn_if_global_destruct(self_sv);

        UMessageFormat *fmt = (UMessageFormat*) _from_svuvptr(aTHX_ self_sv);

        umsg_close(fmt);

const char*
get_locale (SV* self_sv)
    CODE:
        UMessageFormat *fmt = (UMessageFormat*) _from_svuvptr(aTHX_ self_sv);

        RETVAL = umsg_getLocale(fmt);

    OUTPUT:
        RETVAL

void
format (SV* self_sv, SV* pattern, SV* args=NULL)
    PPCODE:
        if (args && SvOK(args) && SvROK(args)) {
            if (SvTYPE(SvRV(args)) == SVt_PVHV) {
#ifdef UICU_HAS_MESSAGEPATTERN
                // In case someone just loaded Unicode::ICU:
                load_module(PERL_LOADMOD_NOIMPORT, newSVpvs(PERL_NAMESPACE "::MessageFormat"), NULL);

                // We can just “goto” the other function since it
                // needs the same args we already have:
                PUSHMARK(SP);
                int count = call_method("_parse_named_args_as_positional", GIMME_V);

                XSRETURN(count);
#else
                _croak_no_named_arguments();
#endif
            }
        }

        // MessageFormat is trickier than other parts of ICU to expose
        // in Perl. To do it we have to solve two issues:
        //
        // - ICU’s C API doesn’t accept dynamic MessageFormat arguments.
        //   Thus, we need the C++ API. That API, though, doesn’t play
        //   nicely with XS, so we compile the C++ code to its own object
        //   file then static-link to that.
        //
        // - Perl scalars don’t have defined types the way ICU expects.
        //   We thus have to query the pattern string for the types it
        //   expects, then extract C buffers from the args for those types.
        //   Querying the pattern, of course, requires C++; in fact, even
        //   the C++ API doesn’t actually expose the controls we need.
        //   See unicode_icu_argtypelist_hack.hh for the workaround.

        UMessageFormat *fmt = (UMessageFormat*) _from_svuvptr(aTHX_ self_sv);

        STRLEN pattern_u8len;
        const char* pattern_u8 = SvPVutf8(pattern, pattern_u8len);

        STRLEN pattern_ucharlen = utf8_to_uchar_len_or_croak(aTHX_
            pattern_u8,
            pattern_u8len
        );

        MAKE_VLA_VIA_VECTOR(pattern_uchar, pattern_ucharlen, UChar);

        utf8_to_uchar_or_croak(aTHX_
            pattern_u8,
            pattern_u8len,
            pattern_uchar,
            pattern_ucharlen
        );

        UParseError parseError = { 0 };

        UErrorCode uerr = U_ZERO_ERROR;

        umsg_applyPattern( fmt, pattern_uchar, pattern_ucharlen, &parseError, &uerr);

        _handle_uerr_with_parseError(uerr, "applyPattern", pattern_uchar, parseError.offset);

        if (perl_uicu_messageformat_uses_named_arguments(fmt)) {
#ifdef UICU_HAS_MESSAGEPATTERN
            if (!args || !SvOK(args)) {
                croak("This phrase needs named arguments.");
            }

            // We got here because we got args that aren’t
            // a hashref, and we need the hashref. So croak.
            croak("Named arguments must be a hashref, not %" SVf, args);
#else
            _croak_no_named_arguments();
#endif
        }

        AV* args_array;

        STRLEN slen;
        UChar* output;

        I32 args_count = perl_uicu_mfmt_count_args(fmt);

        MAKE_VLA_VIA_VECTOR(arg_types, args_count, perl_uicu_formattable_t);
        MAKE_VLA_VIA_VECTOR(args_ptrs, args_count, void*);

        perl_uicu_get_arg_types(fmt, arg_types);

        if (args_count) {
            if (!args || !SvOK(args)) {
                croak("This phrase needs %d argument%s", args_count, args_count == 1 ? "" : "s");
            }

            if (!SvROK(args) || (SvTYPE(SvRV(args)) != SVt_PVAV)) {
                croak("Positional arguments must be an arrayref, not %" SVf, args);
            }

            args_array = (AV*) SvRV(args);

            SSize_t given_args_count = 1 + av_len(args_array);

            if (arg_types[0] == PERL_UICU_FORMATTABLE_OBJECT) {
                croak("Unused initial pattern argument. Did you forget to 0-index the arguments?");
            }

            if (given_args_count != args_count) {
                croak("ICU arguments mismatch: Need %d, got %ld", args_count, given_args_count);
            }

            for (I32 a=0; a<args_count; a++) {
                SV* curarg = *(av_fetch(args_array, a, 0));

                if (!SvOK(curarg)) {
                    croak("undef (argument index %d) is forbidden", a);
                }

                switch (arg_types[a]) {
                    case PERL_UICU_FORMATTABLE_OBJECT:
                        croak("Unused argument (index %d)", a);

                    case PERL_UICU_FORMATTABLE_DATE:
                    case PERL_UICU_FORMATTABLE_DOUBLE:

                        // Ideally we’d use a preprocessor directive here,
                        // but NV_IS_PLAIN_DOUBLE needs sizeof(). The
                        // compiler should still optimize this out, at least.
                        if (NV_IS_PLAIN_DOUBLE) {
                            SvNV(curarg);
                            args_ptrs[a] = &SvNVX(curarg);
                        }
                        else {
                            double *myval;
                            Newx(myval, 1, double);
                            SAVEFREEPV(myval);

                            args_ptrs[a] = myval;
                            *myval = (double) SvNV(curarg);
                        }
                        break;

                    case PERL_UICU_FORMATTABLE_LONG:
                    case PERL_UICU_FORMATTABLE_INT64:
                        SvIV(curarg);
                        args_ptrs[a] = &SvIVX(curarg);
                        break;

                    case PERL_UICU_FORMATTABLE_STRING: {
                        SvPVutf8_nolen(curarg);
                        sv_utf8_upgrade(curarg);

                        if (memchr(SvPVX(curarg), 0, SvCUR(curarg))) {
                            croak("NUL bytes (argument index %d) are forbidden", a);
                        }

                        args_ptrs[a] = &SvPVX(curarg);
                    } break;

                    case PERL_UICU_FORMATTABLE_ARRAY:
                        croak("Array arguments are unsupported.");
                }
            }
        }

        slen = perl_uicu_format_message__argslist(
            fmt,
            args_count,
            arg_types,
            args_ptrs,
            &output,
            &uerr
        );

        _handle_uerr(uerr, "MessageFormat::format", NULL);

        SV* RETVAL = _uchar_array_to_mortal_sv(aTHX_ output, slen);

        ST(0) = RETVAL;

        perl_uicu_free(output);

        XSRETURN(1);


# ----------------------------------------------------------------------

MODULE = Unicode::ICU    PACKAGE = Unicode::ICU::MessagePattern

#ifdef UICU_HAS_MESSAGEPATTERN

SV*
new (const char* classname, SV* pattern)
    CODE:
        STRLEN pattern_u8len;
        const char* pattern_u8 = SvPVutf8(pattern, pattern_u8len);

        STRLEN pattern_ucharlen = utf8_to_uchar_len_or_croak(aTHX_
            pattern_u8,
            pattern_u8len
        );

        MAKE_VLA_VIA_VECTOR(pattern_uchar, pattern_ucharlen, UChar);

        utf8_to_uchar_or_croak(aTHX_
            pattern_u8,
            pattern_u8len,
            pattern_uchar,
            pattern_ucharlen
        );

        UParseError parseError = { 0 };

        UErrorCode uerr = U_ZERO_ERROR;

        perl_uicu_messagepattern* mpat = perl_uicu_parse_pattern(
            pattern_uchar,
            pattern_ucharlen,
            &parseError,
            &uerr
        );

        _handle_uerr_with_parseError(uerr, "new MessagePattern", pattern_uchar, parseError.offset);

        RETVAL = _to_svuvptr(aTHX_ mpat, classname);

    OUTPUT:
        RETVAL

I32
count_parts (SV* self_sv)
    CODE:
        perl_uicu_messagepattern* mpat = _from_svuvptr(aTHX_ self_sv);
        RETVAL = perl_uicu_mpat_count_parts(mpat);

    OUTPUT:
        RETVAL

SV*
get_part (SV* self_sv, UV part_index)
    CODE:
        perl_uicu_messagepattern* mpat = _from_svuvptr(aTHX_ self_sv);

        if (part_index >= (U32) perl_uicu_mpat_count_parts(mpat)) {
            int32_t max = perl_uicu_mpat_count_parts(mpat) - 1;

            croak("Given part index (%" UVf ") exceeds maximum (%d)", part_index, max);
        }

        perl_uicu_messagepattern_part* part = perl_uicu_mpat_get_part(mpat, part_index);

        RETVAL = my_new_blessedstruct(perl_uicu_mpat_part_struct, PERL_NAMESPACE "::MessagePatternPart");
        perl_uicu_mpat_part_struct* mystruct = (perl_uicu_mpat_part_struct*) my_get_blessedstruct_ptr(RETVAL);

        *mystruct = (perl_uicu_mpat_part_struct) {
            .ptr = part,
            .msg_pattern_sv = SvREFCNT_inc(self_sv),
        };

    OUTPUT:
        RETVAL

void
DESTROY (SV* self_sv)
    CODE:
        _warn_if_global_destruct(self_sv);

        perl_uicu_messagepattern* mpat = _from_svuvptr(aTHX_ self_sv);
        perl_uicu_free_messagepattern(mpat);

#endif

# ----------------------------------------------------------------------

MODULE = Unicode::ICU    PACKAGE = Unicode::ICU::MessagePatternPart

#ifdef UICU_HAS_MESSAGEPATTERN

BOOT:
    load_module(PERL_LOADMOD_NOIMPORT, newSVpvs(PERL_NAMESPACE "::MessagePatternPart"), NULL);

    HV* umsgpat_part_type = get_hv(PERL_NAMESPACE "::MessagePatternPart::PART_TYPE", GV_ADD);
    _add_umsgpat_part_type(umsgpat_part_type, MSG_START);
    _add_umsgpat_part_type(umsgpat_part_type, MSG_LIMIT);
    _add_umsgpat_part_type(umsgpat_part_type, SKIP_SYNTAX);
    _add_umsgpat_part_type(umsgpat_part_type, INSERT_CHAR);
    _add_umsgpat_part_type(umsgpat_part_type, REPLACE_NUMBER);
    _add_umsgpat_part_type(umsgpat_part_type, ARG_START);
    _add_umsgpat_part_type(umsgpat_part_type, ARG_LIMIT);
    _add_umsgpat_part_type(umsgpat_part_type, ARG_NUMBER);
    _add_umsgpat_part_type(umsgpat_part_type, ARG_NAME);
    _add_umsgpat_part_type(umsgpat_part_type, ARG_TYPE);
    _add_umsgpat_part_type(umsgpat_part_type, ARG_STYLE);
    _add_umsgpat_part_type(umsgpat_part_type, ARG_SELECTOR);
    _add_umsgpat_part_type(umsgpat_part_type, ARG_INT);
    _add_umsgpat_part_type(umsgpat_part_type, ARG_DOUBLE);

    HV* umsgpat_arg_type = get_hv(PERL_NAMESPACE "::MessagePatternPart::ARG_TYPE", GV_ADD);
    _add_umsgpat_arg_type(umsgpat_arg_type, NONE);
    _add_umsgpat_arg_type(umsgpat_arg_type, SIMPLE);
    _add_umsgpat_arg_type(umsgpat_arg_type, CHOICE);
    _add_umsgpat_arg_type(umsgpat_arg_type, PLURAL);
    _add_umsgpat_arg_type(umsgpat_arg_type, SELECT);
    _add_umsgpat_arg_type(umsgpat_arg_type, SELECTORDINAL);

I32
type (SV* self_sv)
    CODE:
        perl_uicu_mpat_part_struct* mystruct = (perl_uicu_mpat_part_struct*) my_get_blessedstruct_ptr(self_sv);

        RETVAL = perl_uicu_mpat_part_get_type(mystruct->ptr);

    OUTPUT:
        RETVAL

I32
index (SV* self_sv)
    CODE:
        perl_uicu_mpat_part_struct* mystruct = (perl_uicu_mpat_part_struct*) my_get_blessedstruct_ptr(self_sv);

        I32 raw = perl_uicu_mpat_part_get_index(mystruct->ptr);

        const UChar* ustr = _mpat_string(aTHX_ mystruct);

        RETVAL = u_countChar32(ustr, raw);

    OUTPUT:
        RETVAL

I32
length (SV* self_sv)
    CODE:
        perl_uicu_mpat_part_struct* mystruct = (perl_uicu_mpat_part_struct*) my_get_blessedstruct_ptr(self_sv);

        I32 rawidx = perl_uicu_mpat_part_get_index(mystruct->ptr);
        I32 rawlen = perl_uicu_mpat_part_get_length(mystruct->ptr);

        const UChar* ustr = _mpat_string(aTHX_ mystruct);

        RETVAL = u_countChar32(ustr + rawidx, rawlen);

    OUTPUT:
        RETVAL

I32
limit (SV* self_sv)
    CODE:
        perl_uicu_mpat_part_struct* mystruct = (perl_uicu_mpat_part_struct*) my_get_blessedstruct_ptr(self_sv);

        I32 raw = perl_uicu_mpat_part_get_limit(mystruct->ptr);

        const UChar* ustr = _mpat_string(aTHX_ mystruct);

        RETVAL = u_countChar32(ustr, raw);

    OUTPUT:
        RETVAL

I32
value (SV* self_sv)
    CODE:
        perl_uicu_mpat_part_struct* mystruct = (perl_uicu_mpat_part_struct*) my_get_blessedstruct_ptr(self_sv);

        RETVAL = perl_uicu_mpat_part_get_value(mystruct->ptr);

    OUTPUT:
        RETVAL

I32
arg_type (SV* self_sv)
    CODE:
        perl_uicu_mpat_part_struct* mystruct = (perl_uicu_mpat_part_struct*) my_get_blessedstruct_ptr(self_sv);

        RETVAL = perl_uicu_mpat_part_get_arg_type(mystruct->ptr);

    OUTPUT:
        RETVAL

void
DESTROY (SV* self_sv)
    CODE:
        _warn_if_global_destruct(self_sv);
        perl_uicu_mpat_part_struct* mystruct = (perl_uicu_mpat_part_struct*) my_get_blessedstruct_ptr(self_sv);
        SvREFCNT_dec(mystruct->msg_pattern_sv);

#endif

# ----------------------------------------------------------------------

MODULE = Unicode::ICU    PACKAGE = Unicode::ICU::ListFormatter

#ifdef UICU_CAN_FORMAT_LISTS

SV*
format_and (SV* locale_sv=&PL_sv_undef, ...)
    CODE:
#ifdef UICU_CAN_FORMAT_OR
        RETVAL = _format_list(aTHX_ locale_sv, ULISTFMT_TYPE_AND, &ST(1), items-1);
#else
        RETVAL = _format_list(aTHX_ locale_sv, &ST(1), items-1);
#endif

    OUTPUT:
        RETVAL

#ifdef UICU_CAN_FORMAT_OR
SV*
format_or (SV* locale_sv=&PL_sv_undef, ...)
    CODE:
        RETVAL = _format_list(aTHX_ locale_sv, ULISTFMT_TYPE_OR, &ST(1), items-1);

    OUTPUT:
        RETVAL

#endif

#endif

#----------------------------------------------------------------------

MODULE = Unicode::ICU   PACKAGE = Unicode::ICU::IDN

#ifdef UICU_HAS_UIDNA_OBJECT

BOOT:
    load_module(PERL_LOADMOD_NOIMPORT, newSVpvs(PERL_NAMESPACE "::IDN"), NULL);

    _define_idn_uv_constsub(DEFAULT);
    _define_idn_uv_constsub(ALLOW_UNASSIGNED);
    _define_idn_uv_constsub(USE_STD3_RULES);
    _define_idn_uv_constsub(CHECK_BIDI);
    _define_idn_uv_constsub(CHECK_CONTEXTJ);
    _define_idn_uv_constsub(NONTRANSITIONAL_TO_ASCII);
    _define_idn_uv_constsub(NONTRANSITIONAL_TO_UNICODE);
    _define_idn_uv_constsub(CHECK_CONTEXTO);

    HV* error_hv = get_hv(PERL_NAMESPACE "::IDN::ERROR", GV_ADD);
    _add_uidna_error(error_hv, EMPTY_LABEL);
    _add_uidna_error(error_hv, LABEL_TOO_LONG);
    _add_uidna_error(error_hv, DOMAIN_NAME_TOO_LONG);
    _add_uidna_error(error_hv, LEADING_HYPHEN);
    _add_uidna_error(error_hv, TRAILING_HYPHEN);
    _add_uidna_error(error_hv, HYPHEN_3_4);
    _add_uidna_error(error_hv, LEADING_COMBINING_MARK);
    _add_uidna_error(error_hv, DISALLOWED);
    _add_uidna_error(error_hv, PUNYCODE);
    _add_uidna_error(error_hv, LABEL_HAS_DOT);
    _add_uidna_error(error_hv, INVALID_ACE_LABEL);
    _add_uidna_error(error_hv, BIDI);
    _add_uidna_error(error_hv, CONTEXTJ);
    _add_uidna_error(error_hv, CONTEXTO_PUNCTUATION);
    _add_uidna_error(error_hv, CONTEXTO_DIGITS);

SV*
new (const char* classname, U32 options=UIDNA_DEFAULT)
    CODE:
        UErrorCode status = U_ZERO_ERROR;
        UIDNA* uidna = uidna_openUTS46(options, &status);
        _handle_uerr(status, "uidna_openUTS46", NULL);

        RETVAL = _to_svuvptr(aTHX_ uidna, classname);

    OUTPUT:
        RETVAL

SV*
name2ascii (SV* self_sv, SV* unicode_name)
    CODE:
        RETVAL = _idn_convert(self_sv, unicode_name, uidna_nameToASCII_UTF8);

    OUTPUT:
        RETVAL

SV*
name2unicode (SV* self_sv, SV* unicode_name)
    CODE:
        RETVAL = _idn_convert(self_sv, unicode_name, uidna_nameToUnicodeUTF8);

    OUTPUT:
        RETVAL

void DESTROY (SV* self_sv)
    CODE:
        _warn_if_global_destruct(self_sv);
        UIDNA* uidna = (UIDNA*) _from_svuvptr(aTHX_ self_sv);
        uidna_close(uidna);

#endif
