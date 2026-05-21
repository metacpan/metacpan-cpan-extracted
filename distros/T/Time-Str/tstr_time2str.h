#ifndef TSTR_TIME2STR_H
#define TSTR_TIME2STR_H

#include "tstr_datetime.h"
#include "tstr_format.h"

bool tstr_time2str(pTHX_ SV* dsv,
                   const tstr_datetime_t* dt,
                   int precision,
                   tstr_format_t fmt);

#endif /* TSTR_TIME2STR_H */
