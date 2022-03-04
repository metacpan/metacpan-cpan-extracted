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

#include "unicode_icu.h"

#ifdef UICU_HAS_MESSAGEPATTERN

#include "unicode_icu_messagepattern.h"

extern perl_uicu_messagepattern* perl_uicu_parse_pattern( UChar* pattern, int32_t patternlen, UParseError *parseError, UErrorCode *status ) {
    MessagePattern *mpat = new MessagePattern( UnicodeString(pattern, patternlen), parseError, *status );
    return (perl_uicu_messagepattern *) mpat;
}

extern void perl_uicu_free_messagepattern( perl_uicu_messagepattern* ptr ) {
    MessagePattern *mpat = (MessagePattern *) ptr;
    delete mpat;
}

extern int32_t perl_uicu_mpat_count_parts(perl_uicu_messagepattern* ptr ) {
    MessagePattern *mpat = (MessagePattern *) ptr;
    return mpat->countParts();
}

// ----------------------------------------------------------------------

extern const UChar* perl_uicu_mpat_get_pattern_string( perl_uicu_messagepattern* ptr, int32_t *size ) {
    const MessagePattern *mpat = (MessagePattern *) ptr;
    const UnicodeString ustr = mpat->getPatternString();

    // On AlmaLinux 8’s g++ it was observed that returning .getBuffer()’s
    // return value directly caused NULL to be returned. Assumedly (?) ustr
    // is being reaped/emptied prematurely?? Anyway, we get around that by
    // copying the pointer out before the length.
    //
    // Also: Ordinarily we don’t like returning local pointers, but since
    // in this case it’s (likely?) just a pointer to the string inside mpat
    // it seems reasonable and safe.
    //
    const void *buf = ustr.getBuffer();

    *size = ustr.length();

    return (const UChar*) buf;
}

extern perl_uicu_messagepattern_part* perl_uicu_mpat_get_part(perl_uicu_messagepattern* ptr, int32_t index ) {
    MessagePattern *mpat = (MessagePattern *) ptr;
    return (perl_uicu_messagepattern_part*) &(mpat->getPart(index));
}

extern UMessagePatternPartType perl_uicu_mpat_part_get_type( perl_uicu_messagepattern_part* ptr ) {
    MessagePattern::Part *part = (MessagePattern::Part *) ptr;
    return part->getType();
}

extern int32_t perl_uicu_mpat_part_get_index( perl_uicu_messagepattern_part* ptr ) {
    MessagePattern::Part *part = (MessagePattern::Part *) ptr;
    return part->getIndex();
}

extern int32_t perl_uicu_mpat_part_get_length( perl_uicu_messagepattern_part* ptr ) {
    MessagePattern::Part *part = (MessagePattern::Part *) ptr;
    return part->getLength();
}

extern int32_t perl_uicu_mpat_part_get_limit( perl_uicu_messagepattern_part* ptr ) {
    MessagePattern::Part *part = (MessagePattern::Part *) ptr;
    return part->getLimit();
}

extern int32_t perl_uicu_mpat_part_get_value( perl_uicu_messagepattern_part* ptr ) {
    MessagePattern::Part *part = (MessagePattern::Part *) ptr;
    return part->getValue();
}

extern UMessagePatternArgType perl_uicu_mpat_part_get_arg_type( perl_uicu_messagepattern_part* ptr ) {
    MessagePattern::Part *part = (MessagePattern::Part *) ptr;
    return part->getArgType();
}

#endif
