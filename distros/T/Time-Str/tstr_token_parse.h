#ifndef TSTR_TOKEN_PARSE_H
#define TSTR_TOKEN_PARSE_H

#include <stddef.h>
#include <stdbool.h>

bool tstr_token_parse_day(const char* src, size_t len, int* day);
bool tstr_token_parse_day_name(const char* src, size_t len, int* day);
bool tstr_token_parse_meridiem(const char* src, size_t len, int* day);
bool tstr_token_parse_month(const char* src, size_t len, int* month);
bool tstr_token_parse_tz_offset(const char* src, size_t len, int* offset);
bool tstr_token_parse_year(const char* src, size_t len, int* year);
bool tstr_token_parse_hour(const char* src, size_t len, int* hour);
bool tstr_token_parse_minute(const char* src, size_t len, int* minute);
bool tstr_token_parse_second(const char* src, size_t len, int* second);
bool tstr_token_parse_fraction(const char* src, size_t len, int* nanosecond);

#endif /* TSTR_TOKEN_PARSE_H */
