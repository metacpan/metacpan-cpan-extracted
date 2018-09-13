#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include <ctype.h>

#define YES 1
#define NO 0

typedef enum { CSV_NULL, CSV_NUMERIC, CSV_STRING } CSVTYPE;

struct csvfield {
    char *string;
    CSVTYPE type;
};

typedef struct csvfield CSVFIELD;


MODULE = Text::CSV::Easy_XS		PACKAGE = Text::CSV::Easy_XS

PROTOTYPES: DISABLE

SV *
csv_build(...)
    CODE:
        // we will keep track of exactly how long the final string
        // needs to be.
        int finallength = 0;

        // turn on the UTF8 flag if we detect any UTF8 strings.
        bool isutf8 = NO;

        CSVFIELD fields[items];

        int i;
        for (i = 0; i < items; i++) {
            svtype svt = SvTYPE(ST(i));

            if (SvROK(ST(i))) croak("not a string");

            if (SvUTF8(ST(i))) isutf8 = YES;

            // SVt_NULL will be treated as an undef.
            if (svt == SVt_NULL) {
                CSVFIELD field = {NULL,CSV_NULL};
                fields[i] = field;
            }
            else {
                STRLEN length;
                char *string = SvPV(ST(i), length);
                if (string == NULL) croak("could not find a string for argument %d", i + 1);

                // if the length is zero, we'll treat it as an empty string.
                if (length == 0) {
                    CSVFIELD field = {NULL,CSV_STRING};
                    fields[i] = field;

                    finallength += 2; // beginning and trailing quote
                }
                else {
                    CSVTYPE csvtype = CSV_NUMERIC;
                    char *ptr;
                    for (ptr = string; *ptr != '\0'; ptr++) {
                        if (!isdigit(*ptr)) {
                            csvtype = CSV_STRING;
                        }

                        // if we encounter a double quote, we'll need to escape it, so add
                        // one to the length to account for it.
                        if (csvtype == CSV_STRING && *ptr == '"') length++;
                    }

                    CSVFIELD field = {string,csvtype};
                    fields[i] = field;

                    finallength += length;
                    if (csvtype == CSV_STRING) finallength += 2; // beginning and trailing quote
                }
            }
        }

        finallength += (items - 1); // commas

        char *outstring;
        Newx(outstring, finallength + 1, char);

        char *optr = outstring;
        for (i = 0; i < items; i++) {
            // record separator
            if (i != 0) {
                *optr++ = ',';
            }

            CSVFIELD field = fields[i];

            // we will quote all strings.
            if (field.type == CSV_STRING) *optr++ = '"';

            if (field.string != NULL) {
                char *ptr;
                for (ptr = field.string; *ptr != '\0'; ptr++) {
                    *optr++ = *ptr;

                    // if we encounter a quote, we need to escape it.
                    if (*ptr == '"') {
                        *optr++ = '"';
                    }
                }
            }

            // closing quote
            if (field.type == CSV_STRING) *optr++ = '"';
        }

        *optr = '\0';

        SV *retval = newSVpvn(outstring, optr - outstring);
        Safefree(outstring);

        if (isutf8) SvUTF8_on(retval);

        RETVAL = retval;
    OUTPUT:
        RETVAL

void
csv_parse(string)
    SV *string
    PPCODE:
    {
        // do not allow references
        if (SvROK(string)) croak("not a string");

        // get the string and verify we have length > 0
        STRLEN len;
        char *str = SvPV(string, len);
        if (len == 0) XSRETURN(0);

        int st_pos  = 0;    // keep track for ST(x)
        char *ptr   = NULL; // tracks character in string
        char *field = NULL; // tracks current field being parsed

        bool isutf8 = SvUTF8(string) != 0; // SvUTF8 doesn't typecast consistently to bool across various archs
        bool quoted = NO;            // is the field quoted?
        bool requires_unescape = NO; // did we encounter an escaped quote, e.g. some ""quote""

        for ( ptr = str; *ptr != '\0'; ptr++ ) {
            if ( field == NULL ) {
                field = ptr;

                quoted = NO;

                // a quoted string: "one","two","three"
                if (*ptr == '"') {
                    quoted = YES;
                    requires_unescape = NO;
                    field++;
                    continue;
                }
                // an undef value: one,,three
                else if (*ptr == ',') {
                    EXTEND( SP, st_pos + 1 );
                    ST(st_pos++) = &PL_sv_undef;
                    field = NULL;
                    continue;
                }
                // an undef at the end with a trailing newline
                else if (
                        ( *ptr == '\n' && *(ptr+1) == '\0' )
                     || ( *ptr == '\r' && *(ptr+1) == '\n' && *(ptr+2) == '\0' )
                ) {
                    // undef is added later
                    field = NULL;
                    break;
                }
                // an unquoted string or number: one,2,3
                else {
                    // do nothing
                }
            }

            if ( !quoted ) {
                switch (*ptr) {
                    case ',':
                        EXTEND( SP, st_pos + 1 );
                        ST(st_pos++) = sv_2mortal( newSVpvn( field, ptr - field ) );
                        field = NULL;
                        break;
                    case '"':
                        croak("quote found in middle of the field: %s\n", field);
                        break;
                    case '\n': {
                        // allow an optional trailing newline
                        if (*(ptr+1) == '\0') {
                            // handle the case when the provide a CRLF
                            if (ptr > field && *(ptr-1) == '\r') {
                                ptr--;
                            }

                            // goto is evil, but in this case, use it to exit
                            // a nested loop. I prefer a switch here, and I don't
                            // want to add additional logic to the for conditional.
                            // I feel guilty if that makes you feel any better.
                            goto outsidefor;
                        }
                        else {
                            croak("newline found in unquoted string: %s\n", field);
                        }

                        break;
                    }
                }
            }
            else {
                if ( *ptr == '"' ) {
                    // see if the quote is part of an escaped quote
                    if ( *(ptr + 1) == '"' ) {
                        requires_unescape = YES;
                        ptr++; // increment to get past the escaped quote
                        continue;
                    }
                    // reached the end of the field
                    else if ( *(ptr + 1) == ','
                           || *(ptr + 1) == '\0'
                           || ( *(ptr + 1) == '\n' && *(ptr + 2) == '\0' ) // trailing newline
                           || ( *(ptr + 1) == '\r' && *(ptr + 2) == '\n' && *(ptr + 3) == '\0' ) // trailing CRLF
                    ) {
                        if (!requires_unescape) {
                            // no additional processing required. just create a string.
                            SV *tmp = sv_2mortal( newSVpvn( field, ptr - field ) );
                            if (isutf8) SvUTF8_on(tmp);
                            EXTEND( SP, st_pos + 1 );
                            ST(st_pos++) = tmp;
                        }
                        else {
                            // we need to convert any double quotes to single quotes
                            int field_len = ptr - field;

                            char *tmp;
                            Newx(tmp, field_len + 1, char);

                            int i;
                            char *fieldptr;
                            for (i = 0, fieldptr = field; fieldptr < ptr; fieldptr++) {
                                tmp[i++] = *fieldptr;
                                if (*fieldptr == '"') {
                                    fieldptr++;
                                }
                            }
                            tmp[i] = '\0';

                            SV *tmpsv = sv_2mortal( newSVpvn( tmp, i ) );
                            if (isutf8) SvUTF8_on(tmpsv);
                            EXTEND( SP, st_pos + 1 );
                            ST(st_pos++) = tmpsv;

                            Safefree(tmp);
                        }

                        field = NULL;

                        // allow trailing newline.
                        if (*(ptr+1) == '\n') break;

                        // move the pointer ahead so we don't process the comma
                        if (*(ptr+1) == ',') ptr++;
                    }
                    else {
                        // put the quote back to make it easier to for the user.
                        croak("invalid field: \"%s\n", field);
                    }
                }
            }
        }

    // No I don't, deal with it!
    // This label should only be used to break out of the switch inside the for
    // loop.
    outsidefor: 

        // if we hit the end of the string, the last field will not have been
        // added if it's a non-quoted string.
        if (field != NULL && !quoted) {
            EXTEND( SP, st_pos + 1 );
            ST(st_pos++) = sv_2mortal( newSVpvn( field, ptr - field ) );
        }
        // if field is not NULL, it means the string never terminated.
        else if (field != NULL) {
            croak("unterminated string: %s\n", str);
        }
        // if there was a trailing comma, add an undef
        else if (*(ptr-1) == ',') {
            EXTEND( SP, st_pos + 1 );
            ST(st_pos++) = &PL_sv_undef;
        }

        XSRETURN(st_pos);
    }
