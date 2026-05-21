#ifndef TSTR_REGEXP_H
#define TSTR_REGEXP_H

#include "tstr_sv.h"
#include "tstr_parsed.h"
#include "tstr_parse_result.h"

tstr_parse_result_t tstr_regexp_extract(pTHX_ REGEXP *rx, tstr_parsed_t *p,
                                        tstr_sv_keys_t *keys);

#endif /* TSTR_REGEXP_H */
