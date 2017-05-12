#include "EXTERN.h"
#include "perl.h"
#include "callparser1.h"
#include "XSUB.h"

static int check_keyword(const char *keyword)
{
    STRLEN len;

    len = strlen(keyword);
    if (PL_parser->bufend - PL_parser->bufptr < len) {
        return 0;
    }

    if (strnNE(PL_parser->bufptr, keyword, len)) {
        return 0;
    }

    if (PL_parser->bufptr + len != PL_parser->bufend
        && isALNUM(*(PL_parser->bufptr + len))) {
        return 0;
    }

    lex_read_to(PL_parser->bufptr + len);

    return 1;
}

static OP *parse_try(pTHX_ GV *namegv, SV *psobj, U32 *flagsp)
{
    OP *try, *catch, *finally, *ret;
    I32 floor;

    *flagsp |= CALLPARSER_STATEMENT;

    lex_read_space(0);
    if (*(PL_parser->bufptr) != '{') {
        croak("syntax error");
    }
    floor = start_subparse(0, CVf_ANON);
    try = newANONSUB(floor, NULL, parse_block(0));

    lex_read_space(0);
    if (check_keyword("catch")) {
        lex_read_space(0);
        if (*(PL_parser->bufptr) != '{') {
            croak("syntax error");
        }
        floor = start_subparse(0, CVf_ANON);
        catch = newANONSUB(floor, NULL, parse_block(0));
    }
    else {
        catch = newOP(OP_UNDEF, 0);
    }

    lex_read_space(0);
    if (check_keyword("finally")) {
        lex_read_space(0);
        if (*(PL_parser->bufptr) != '{') {
            croak("syntax error");
        }
        floor = start_subparse(0, CVf_ANON);
        finally = newANONSUB(floor, NULL, parse_block(0));
    }
    else {
        finally = newOP(OP_UNDEF, 0);
    }

    ret = newLISTOP(OP_LIST, 0, try, catch);
    op_append_elem(OP_LIST, ret, finally);

    return ret;
}

MODULE = Try  PACKAGE = Try

PROTOTYPES: DISABLE

BOOT:
{
    cv_set_call_parser(get_cv("Try::try", 0), parse_try, &PL_sv_undef);
}
