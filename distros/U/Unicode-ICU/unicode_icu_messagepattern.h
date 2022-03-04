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

#ifndef UNICODE_ICU_MESSAGEPATTERN_H
#define UNICODE_ICU_MESSAGEPATTERN_H

#include "unicode_icu.h"

#include <unicode/messagepattern.h>
using namespace icu;

// There’s no C API for this, so we just have to represent the C++
// pointer as an opaque thing.
typedef void perl_uicu_messagepattern;
typedef void perl_uicu_messagepattern_part;

perl_uicu_messagepattern* perl_uicu_parse_pattern( UChar* pattern, int32_t patternlen, UParseError *parseError, UErrorCode *status );

void perl_uicu_free_messagepattern( perl_uicu_messagepattern* ptr );

int32_t perl_uicu_mpat_count_parts(perl_uicu_messagepattern* ptr );

perl_uicu_messagepattern_part* perl_uicu_mpat_get_part(perl_uicu_messagepattern* ptr, int32_t index );

UMessagePatternPartType perl_uicu_mpat_part_get_type( perl_uicu_messagepattern_part* ptr );

int32_t perl_uicu_mpat_part_get_index( perl_uicu_messagepattern_part* ptr );
int32_t perl_uicu_mpat_part_get_length( perl_uicu_messagepattern_part* ptr );
int32_t perl_uicu_mpat_part_get_limit( perl_uicu_messagepattern_part* ptr );
int32_t perl_uicu_mpat_part_get_value( perl_uicu_messagepattern_part* ptr );

const UChar* perl_uicu_mpat_get_pattern_string( perl_uicu_messagepattern* ptr, int32_t *size );

UMessagePatternArgType perl_uicu_mpat_part_get_arg_type( perl_uicu_messagepattern_part* ptr );

#endif
