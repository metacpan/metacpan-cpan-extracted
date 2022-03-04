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

// ----------------------------------------------------------------------

/*
 * Perl XS and ICU’s C++ don’t seem to like each other very well.
 * Thus, we have to avoid Perlisms here (and can’t put C++ into the XS).
 * An upshot of that is that this stuff here could find use outside Perl.
 */

#include <unicode/unistr.h>
#include <unicode/fmtable.h>
#include <unicode/msgfmt.h>

#include <unicode/datefmt.h>
#include <unicode/plurfmt.h>
//#include <unicode/selfmt.h>
#include <unicode/format.h>
#include <unicode/dtitvfmt.h>
#include <unicode/measfmt.h>
using namespace icu;

#include <stdlib.h>
#include <assert.h>
#include <string.h>

#include <vector>

#include "unicode_icu.h"
#include "unicode_icu_argtypelist_hack.hh"

extern bool perl_uicu_messageformat_uses_named_arguments (UMessageFormat* ufmt) {
    MessageFormat fmt = *(const MessageFormat*) ufmt;

    return fmt.usesNamedArguments();
}

static inline void _assign_args_to_formattable(
    Formattable *fargs,
    uint32_t argscount,
    perl_uicu_formattable_t* argtypes,
    void** args
) {
    for (uint32_t a=0; a<argscount; a++) {
        switch (argtypes[a]) {
            case PERL_UICU_FORMATTABLE_DATE:
                fargs[a].setDate( 1000 * *( (UDate *) args[a] ) );
                break;

            case PERL_UICU_FORMATTABLE_DOUBLE:
                fargs[a].setDouble( *( (double *) args[a] ) );
                break;

            case PERL_UICU_FORMATTABLE_LONG:
                fargs[a].setLong( *( (long *) args[a] ) );
                break;

            case PERL_UICU_FORMATTABLE_STRING: {
                // Here, alas, we rely on NUL termination:
                const char* utf8str = *( (const char **) args[a] );

                const StringPiece sp = StringPiece(utf8str);
                UnicodeString str = UnicodeString::fromUTF8(sp);

                fargs[a].setString(str);
            } break;

            case PERL_UICU_FORMATTABLE_INT64:
                fargs[a].setInt64( *( (int64_t *) args[a] ) );
                break;

            default:
                assert(0);
        }
    }
}

extern int32_t perl_uicu_format_message__argslist (
    UMessageFormat* ufmt,
    uint32_t argscount,
    perl_uicu_formattable_t* argtypes,
    void** args,
    UChar** output,
    UErrorCode *status
) {
    MessageFormat fmt = *(const MessageFormat*) ufmt;

    std::vector<Formattable> fargs(argscount);

    _assign_args_to_formattable(fargs.data(), argscount, argtypes, args);

    *status = U_ZERO_ERROR;

    UnicodeString tempBuffer;
    FieldPosition pos(FieldPosition::DONT_CARE);
    tempBuffer = fmt.format(fargs.data(), argscount, tempBuffer, pos, *status);

    if (U_FAILURE(*status)) return -1;

    *output = (UChar *) calloc( tempBuffer.length(), sizeof(UChar) );
    memcpy(*output, tempBuffer.getBuffer(), tempBuffer.length() * sizeof(UChar) );

    return tempBuffer.length();
}

extern int32_t perl_uicu_mfmt_count_args (UMessageFormat* ufmt) {
    MessageFormat fmt = *(const MessageFormat*) ufmt;

    int32_t types_count;
    MessageFormatAdapter::perl_uicu_getArgTypeList(fmt, types_count);

    return types_count;
}

extern void perl_uicu_get_arg_types( UMessageFormat* ufmt, perl_uicu_formattable_t* perl_types ) {

    MessageFormat fmt = *(const MessageFormat*) ufmt;

    int32_t types_count;
    const Formattable::Type* types = MessageFormatAdapter::perl_uicu_getArgTypeList(fmt, types_count);

    perl_uicu_formattable_t *utypesptr = (perl_uicu_formattable_t*) calloc(types_count, sizeof(perl_uicu_formattable_t));
    assert(NULL != utypesptr);

    for (int32_t t=0; t<types_count; t++) {
        perl_uicu_formattable_t curtype;

        switch (types[t]) {
            case Formattable::kDate:
                curtype = PERL_UICU_FORMATTABLE_DATE;
                break;
            case Formattable::kDouble:
                curtype = PERL_UICU_FORMATTABLE_DOUBLE;
                break;
            case Formattable::kLong:
                curtype = PERL_UICU_FORMATTABLE_LONG;
                break;
            case Formattable::kString:
                curtype = PERL_UICU_FORMATTABLE_STRING;
                break;
            case Formattable::kArray:
                curtype = PERL_UICU_FORMATTABLE_ARRAY;
                break;
            case Formattable::kInt64:
                curtype = PERL_UICU_FORMATTABLE_INT64;
                break;
            case Formattable::kObject:
                curtype = PERL_UICU_FORMATTABLE_OBJECT;
                break;

            default:
                assert(0);
        }

        perl_types[t] = curtype;
    }
}

extern void perl_uicu_free(void* ptr) {
    free(ptr);
}
