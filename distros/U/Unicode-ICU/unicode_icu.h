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

// This file defines the interface that our C++ exposes to C.
// (This is how the XS code accesses ICU’s C++ API.)

#ifndef UNICODE_ICU_H
#define UNICODE_ICU_H

#include <unicode/utypes.h>
#include <unicode/ustring.h>
#include <unicode/parseerr.h>
#include <unicode/umsg.h>

typedef enum {
    PERL_UICU_FORMATTABLE_DATE = 0,
    PERL_UICU_FORMATTABLE_DOUBLE,
    PERL_UICU_FORMATTABLE_LONG,
    PERL_UICU_FORMATTABLE_STRING,
    PERL_UICU_FORMATTABLE_ARRAY,
    PERL_UICU_FORMATTABLE_INT64,
    PERL_UICU_FORMATTABLE_OBJECT,
} perl_uicu_formattable_t;

void perl_uicu_get_arg_types( UMessageFormat* ufmt, perl_uicu_formattable_t* perl_types );

int32_t perl_uicu_mfmt_count_args (UMessageFormat* ufmt);

void perl_uicu_free(void *);

bool perl_uicu_messageformat_uses_named_arguments(
    UMessageFormat *
);

int32_t perl_uicu_format_message__argslist(
    UMessageFormat* ufmt,
    uint32_t argscount,
    perl_uicu_formattable_t* argtypes,
    void** args,
    UChar** output,
    UErrorCode *status
);

#endif
