#ifndef TSTR_PARSE_H
#define TSTR_PARSE_H

#include "tstr_sv.h"
#include "tstr_parsed.h"
#include "tstr_format.h"

void tstr_parse(pTHX_ SV *input, tstr_format_t fmt, int pivot_year,
                REGEXP **regexps, tstr_sv_keys_t *keys, tstr_parsed_t *p);

#endif /* TSTR_PARSE_H */
