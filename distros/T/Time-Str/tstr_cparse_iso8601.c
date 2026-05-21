
#line 1 "ragel/tstr_cparse_iso8601.rl"
#include <stddef.h>
#include <stdbool.h>
#include <string.h>

#include "tstr_parsed.h"
#include "tstr_token_parse.h"
#include "tstr_cparse.h"


#line 49 "ragel/tstr_cparse_iso8601.rl"



#line 17 "tstr_cparse_iso8601.c"
static const int iso8601_start = 1;
static const int iso8601_first_final = 32;
static const int iso8601_error = 0;

static const int iso8601_en_main = 1;


#line 52 "ragel/tstr_cparse_iso8601.rl"

tstr_parse_result_t tstr_cparse_iso8601(const char* p,
                                        size_t len,
                                        tstr_parsed_t* parsed) {
  int cs, v;
  const char* pe = p + len;
  const char* eof = pe;
  const char* mark = NULL;
  tstr_parse_result_t result = TSTR_PARSE_OK;

  (void)tstr_parsed_init(parsed);

  
#line 39 "tstr_cparse_iso8601.c"
	{
	cs = iso8601_start;
	}

#line 65 "ragel/tstr_cparse_iso8601.rl"
  
#line 46 "tstr_cparse_iso8601.c"
	{
	if ( p == pe )
		goto _test_eof;
	switch ( cs )
	{
case 1:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr0;
	goto st0;
st0:
cs = 0;
	goto _out;
tr0:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st2;
st2:
	if ( ++p == pe )
		goto _test_eof2;
case 2:
#line 67 "tstr_cparse_iso8601.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st3;
	goto st0;
st3:
	if ( ++p == pe )
		goto _test_eof3;
case 3:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st4;
	goto st0;
st4:
	if ( ++p == pe )
		goto _test_eof4;
case 4:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st5;
	goto st0;
st5:
	if ( ++p == pe )
		goto _test_eof5;
case 5:
	if ( (*p) == 45 )
		goto tr5;
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr6;
	goto st0;
tr5:
#line 6 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_year(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_YEAR;
      {p++; cs = 6; goto _out;}
    }
    tstr_parsed_set_year4(parsed, v);
  }
	goto st6;
st6:
	if ( ++p == pe )
		goto _test_eof6;
case 6:
#line 108 "tstr_cparse_iso8601.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr7;
	goto st0;
tr7:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st7;
st7:
	if ( ++p == pe )
		goto _test_eof7;
case 7:
#line 120 "tstr_cparse_iso8601.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st8;
	goto st0;
st8:
	if ( ++p == pe )
		goto _test_eof8;
case 8:
	if ( (*p) == 45 )
		goto tr9;
	goto st0;
tr9:
#line 22 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_month(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_MONTH;
      {p++; cs = 9; goto _out;}
    }
    tstr_parsed_set_month(parsed, v);
  }
	goto st9;
st9:
	if ( ++p == pe )
		goto _test_eof9;
case 9:
#line 145 "tstr_cparse_iso8601.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr10;
	goto st0;
tr10:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st10;
st10:
	if ( ++p == pe )
		goto _test_eof10;
case 10:
#line 157 "tstr_cparse_iso8601.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st32;
	goto st0;
st32:
	if ( ++p == pe )
		goto _test_eof32;
case 32:
	if ( (*p) == 84 )
		goto tr33;
	goto st0;
tr33:
#line 30 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_day(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_DAY;
      {p++; cs = 11; goto _out;}
    }
    tstr_parsed_set_day(parsed, v);
  }
	goto st11;
st11:
	if ( ++p == pe )
		goto _test_eof11;
case 11:
#line 182 "tstr_cparse_iso8601.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr12;
	goto st0;
tr12:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st12;
st12:
	if ( ++p == pe )
		goto _test_eof12;
case 12:
#line 194 "tstr_cparse_iso8601.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st33;
	goto st0;
st33:
	if ( ++p == pe )
		goto _test_eof33;
case 33:
	switch( (*p) ) {
		case 44: goto tr35;
		case 46: goto tr35;
		case 58: goto tr36;
		case 90: goto tr37;
	}
	if ( 43 <= (*p) && (*p) <= 45 )
		goto tr34;
	goto st0;
tr34:
#line 46 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_hour(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_HOUR;
      {p++; cs = 13; goto _out;}
    }
    tstr_parsed_set_hour(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st13;
tr39:
#line 70 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_fraction(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_FRACTION;
      {p++; cs = 13; goto _out;}
    }
    tstr_parsed_set_fraction(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st13;
tr49:
#line 54 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_minute(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_MINUTE;
      {p++; cs = 13; goto _out;}
    }
    tstr_parsed_set_minute(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st13;
tr53:
#line 62 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_second(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_SECOND;
      {p++; cs = 13; goto _out;}
    }
    tstr_parsed_set_second(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st13;
st13:
	if ( ++p == pe )
		goto _test_eof13;
case 13:
#line 263 "tstr_cparse_iso8601.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st14;
	goto st0;
st14:
	if ( ++p == pe )
		goto _test_eof14;
case 14:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st34;
	goto st0;
st34:
	if ( ++p == pe )
		goto _test_eof34;
case 34:
	if ( (*p) == 58 )
		goto st15;
	goto st0;
st15:
	if ( ++p == pe )
		goto _test_eof15;
case 15:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st16;
	goto st0;
st16:
	if ( ++p == pe )
		goto _test_eof16;
case 16:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st35;
	goto st0;
st35:
	if ( ++p == pe )
		goto _test_eof35;
case 35:
	goto st0;
tr35:
#line 46 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_hour(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_HOUR;
      {p++; cs = 17; goto _out;}
    }
    tstr_parsed_set_hour(parsed, v);
  }
	goto st17;
tr50:
#line 54 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_minute(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_MINUTE;
      {p++; cs = 17; goto _out;}
    }
    tstr_parsed_set_minute(parsed, v);
  }
	goto st17;
tr54:
#line 62 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_second(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_SECOND;
      {p++; cs = 17; goto _out;}
    }
    tstr_parsed_set_second(parsed, v);
  }
	goto st17;
st17:
	if ( ++p == pe )
		goto _test_eof17;
case 17:
#line 334 "tstr_cparse_iso8601.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr18;
	goto st0;
tr18:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st36;
st36:
	if ( ++p == pe )
		goto _test_eof36;
case 36:
#line 346 "tstr_cparse_iso8601.c"
	switch( (*p) ) {
		case 43: goto tr39;
		case 45: goto tr39;
		case 90: goto tr41;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st37;
	goto st0;
st37:
	if ( ++p == pe )
		goto _test_eof37;
case 37:
	switch( (*p) ) {
		case 43: goto tr39;
		case 45: goto tr39;
		case 90: goto tr41;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st38;
	goto st0;
st38:
	if ( ++p == pe )
		goto _test_eof38;
case 38:
	switch( (*p) ) {
		case 43: goto tr39;
		case 45: goto tr39;
		case 90: goto tr41;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st39;
	goto st0;
st39:
	if ( ++p == pe )
		goto _test_eof39;
case 39:
	switch( (*p) ) {
		case 43: goto tr39;
		case 45: goto tr39;
		case 90: goto tr41;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st40;
	goto st0;
st40:
	if ( ++p == pe )
		goto _test_eof40;
case 40:
	switch( (*p) ) {
		case 43: goto tr39;
		case 45: goto tr39;
		case 90: goto tr41;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st41;
	goto st0;
st41:
	if ( ++p == pe )
		goto _test_eof41;
case 41:
	switch( (*p) ) {
		case 43: goto tr39;
		case 45: goto tr39;
		case 90: goto tr41;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st42;
	goto st0;
st42:
	if ( ++p == pe )
		goto _test_eof42;
case 42:
	switch( (*p) ) {
		case 43: goto tr39;
		case 45: goto tr39;
		case 90: goto tr41;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st43;
	goto st0;
st43:
	if ( ++p == pe )
		goto _test_eof43;
case 43:
	switch( (*p) ) {
		case 43: goto tr39;
		case 45: goto tr39;
		case 90: goto tr41;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st44;
	goto st0;
st44:
	if ( ++p == pe )
		goto _test_eof44;
case 44:
	switch( (*p) ) {
		case 43: goto tr39;
		case 45: goto tr39;
		case 90: goto tr41;
	}
	goto st0;
tr37:
#line 46 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_hour(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_HOUR;
      {p++; cs = 45; goto _out;}
    }
    tstr_parsed_set_hour(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st45;
tr41:
#line 70 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_fraction(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_FRACTION;
      {p++; cs = 45; goto _out;}
    }
    tstr_parsed_set_fraction(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st45;
tr52:
#line 54 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_minute(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_MINUTE;
      {p++; cs = 45; goto _out;}
    }
    tstr_parsed_set_minute(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st45;
tr55:
#line 62 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_second(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_SECOND;
      {p++; cs = 45; goto _out;}
    }
    tstr_parsed_set_second(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st45;
st45:
	if ( ++p == pe )
		goto _test_eof45;
case 45:
#line 501 "tstr_cparse_iso8601.c"
	goto st0;
tr36:
#line 46 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_hour(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_HOUR;
      {p++; cs = 18; goto _out;}
    }
    tstr_parsed_set_hour(parsed, v);
  }
	goto st18;
st18:
	if ( ++p == pe )
		goto _test_eof18;
case 18:
#line 517 "tstr_cparse_iso8601.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr19;
	goto st0;
tr19:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st19;
st19:
	if ( ++p == pe )
		goto _test_eof19;
case 19:
#line 529 "tstr_cparse_iso8601.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st46;
	goto st0;
st46:
	if ( ++p == pe )
		goto _test_eof46;
case 46:
	switch( (*p) ) {
		case 44: goto tr50;
		case 46: goto tr50;
		case 58: goto tr51;
		case 90: goto tr52;
	}
	if ( 43 <= (*p) && (*p) <= 45 )
		goto tr49;
	goto st0;
tr51:
#line 54 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_minute(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_MINUTE;
      {p++; cs = 20; goto _out;}
    }
    tstr_parsed_set_minute(parsed, v);
  }
	goto st20;
st20:
	if ( ++p == pe )
		goto _test_eof20;
case 20:
#line 560 "tstr_cparse_iso8601.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr21;
	goto st0;
tr21:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st21;
st21:
	if ( ++p == pe )
		goto _test_eof21;
case 21:
#line 572 "tstr_cparse_iso8601.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st47;
	goto st0;
st47:
	if ( ++p == pe )
		goto _test_eof47;
case 47:
	switch( (*p) ) {
		case 44: goto tr54;
		case 46: goto tr54;
		case 90: goto tr55;
	}
	if ( 43 <= (*p) && (*p) <= 45 )
		goto tr53;
	goto st0;
tr6:
#line 6 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_year(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_YEAR;
      {p++; cs = 22; goto _out;}
    }
    tstr_parsed_set_year4(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st22;
st22:
	if ( ++p == pe )
		goto _test_eof22;
case 22:
#line 604 "tstr_cparse_iso8601.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st23;
	goto st0;
st23:
	if ( ++p == pe )
		goto _test_eof23;
case 23:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr24;
	goto st0;
tr24:
#line 22 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_month(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_MONTH;
      {p++; cs = 24; goto _out;}
    }
    tstr_parsed_set_month(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st24;
st24:
	if ( ++p == pe )
		goto _test_eof24;
case 24:
#line 631 "tstr_cparse_iso8601.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st48;
	goto st0;
st48:
	if ( ++p == pe )
		goto _test_eof48;
case 48:
	if ( (*p) == 84 )
		goto tr56;
	goto st0;
tr56:
#line 30 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_day(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_DAY;
      {p++; cs = 25; goto _out;}
    }
    tstr_parsed_set_day(parsed, v);
  }
	goto st25;
st25:
	if ( ++p == pe )
		goto _test_eof25;
case 25:
#line 656 "tstr_cparse_iso8601.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr26;
	goto st0;
tr26:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st26;
st26:
	if ( ++p == pe )
		goto _test_eof26;
case 26:
#line 668 "tstr_cparse_iso8601.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st49;
	goto st0;
st49:
	if ( ++p == pe )
		goto _test_eof49;
case 49:
	switch( (*p) ) {
		case 44: goto tr58;
		case 46: goto tr58;
		case 90: goto tr37;
	}
	if ( (*p) > 45 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr59;
	} else if ( (*p) >= 43 )
		goto tr57;
	goto st0;
tr57:
#line 46 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_hour(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_HOUR;
      {p++; cs = 27; goto _out;}
    }
    tstr_parsed_set_hour(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st27;
tr60:
#line 70 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_fraction(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_FRACTION;
      {p++; cs = 27; goto _out;}
    }
    tstr_parsed_set_fraction(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st27;
tr69:
#line 54 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_minute(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_MINUTE;
      {p++; cs = 27; goto _out;}
    }
    tstr_parsed_set_minute(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st27;
tr72:
#line 62 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_second(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_SECOND;
      {p++; cs = 27; goto _out;}
    }
    tstr_parsed_set_second(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st27;
st27:
	if ( ++p == pe )
		goto _test_eof27;
case 27:
#line 739 "tstr_cparse_iso8601.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st28;
	goto st0;
st28:
	if ( ++p == pe )
		goto _test_eof28;
case 28:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st50;
	goto st0;
st50:
	if ( ++p == pe )
		goto _test_eof50;
case 50:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st16;
	goto st0;
tr58:
#line 46 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_hour(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_HOUR;
      {p++; cs = 29; goto _out;}
    }
    tstr_parsed_set_hour(parsed, v);
  }
	goto st29;
tr70:
#line 54 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_minute(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_MINUTE;
      {p++; cs = 29; goto _out;}
    }
    tstr_parsed_set_minute(parsed, v);
  }
	goto st29;
tr73:
#line 62 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_second(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_SECOND;
      {p++; cs = 29; goto _out;}
    }
    tstr_parsed_set_second(parsed, v);
  }
	goto st29;
st29:
	if ( ++p == pe )
		goto _test_eof29;
case 29:
#line 791 "tstr_cparse_iso8601.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr30;
	goto st0;
tr30:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st51;
st51:
	if ( ++p == pe )
		goto _test_eof51;
case 51:
#line 803 "tstr_cparse_iso8601.c"
	switch( (*p) ) {
		case 43: goto tr60;
		case 45: goto tr60;
		case 90: goto tr41;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st52;
	goto st0;
st52:
	if ( ++p == pe )
		goto _test_eof52;
case 52:
	switch( (*p) ) {
		case 43: goto tr60;
		case 45: goto tr60;
		case 90: goto tr41;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st53;
	goto st0;
st53:
	if ( ++p == pe )
		goto _test_eof53;
case 53:
	switch( (*p) ) {
		case 43: goto tr60;
		case 45: goto tr60;
		case 90: goto tr41;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st54;
	goto st0;
st54:
	if ( ++p == pe )
		goto _test_eof54;
case 54:
	switch( (*p) ) {
		case 43: goto tr60;
		case 45: goto tr60;
		case 90: goto tr41;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st55;
	goto st0;
st55:
	if ( ++p == pe )
		goto _test_eof55;
case 55:
	switch( (*p) ) {
		case 43: goto tr60;
		case 45: goto tr60;
		case 90: goto tr41;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st56;
	goto st0;
st56:
	if ( ++p == pe )
		goto _test_eof56;
case 56:
	switch( (*p) ) {
		case 43: goto tr60;
		case 45: goto tr60;
		case 90: goto tr41;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st57;
	goto st0;
st57:
	if ( ++p == pe )
		goto _test_eof57;
case 57:
	switch( (*p) ) {
		case 43: goto tr60;
		case 45: goto tr60;
		case 90: goto tr41;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st58;
	goto st0;
st58:
	if ( ++p == pe )
		goto _test_eof58;
case 58:
	switch( (*p) ) {
		case 43: goto tr60;
		case 45: goto tr60;
		case 90: goto tr41;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st59;
	goto st0;
st59:
	if ( ++p == pe )
		goto _test_eof59;
case 59:
	switch( (*p) ) {
		case 43: goto tr60;
		case 45: goto tr60;
		case 90: goto tr41;
	}
	goto st0;
tr59:
#line 46 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_hour(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_HOUR;
      {p++; cs = 30; goto _out;}
    }
    tstr_parsed_set_hour(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st30;
st30:
	if ( ++p == pe )
		goto _test_eof30;
case 30:
#line 922 "tstr_cparse_iso8601.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st60;
	goto st0;
st60:
	if ( ++p == pe )
		goto _test_eof60;
case 60:
	switch( (*p) ) {
		case 44: goto tr70;
		case 46: goto tr70;
		case 90: goto tr52;
	}
	if ( (*p) > 45 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto tr71;
	} else if ( (*p) >= 43 )
		goto tr69;
	goto st0;
tr71:
#line 54 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_minute(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_MINUTE;
      {p++; cs = 31; goto _out;}
    }
    tstr_parsed_set_minute(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st31;
st31:
	if ( ++p == pe )
		goto _test_eof31;
case 31:
#line 957 "tstr_cparse_iso8601.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st61;
	goto st0;
st61:
	if ( ++p == pe )
		goto _test_eof61;
case 61:
	switch( (*p) ) {
		case 44: goto tr73;
		case 46: goto tr73;
		case 90: goto tr55;
	}
	if ( 43 <= (*p) && (*p) <= 45 )
		goto tr72;
	goto st0;
	}
	_test_eof2: cs = 2; goto _test_eof; 
	_test_eof3: cs = 3; goto _test_eof; 
	_test_eof4: cs = 4; goto _test_eof; 
	_test_eof5: cs = 5; goto _test_eof; 
	_test_eof6: cs = 6; goto _test_eof; 
	_test_eof7: cs = 7; goto _test_eof; 
	_test_eof8: cs = 8; goto _test_eof; 
	_test_eof9: cs = 9; goto _test_eof; 
	_test_eof10: cs = 10; goto _test_eof; 
	_test_eof32: cs = 32; goto _test_eof; 
	_test_eof11: cs = 11; goto _test_eof; 
	_test_eof12: cs = 12; goto _test_eof; 
	_test_eof33: cs = 33; goto _test_eof; 
	_test_eof13: cs = 13; goto _test_eof; 
	_test_eof14: cs = 14; goto _test_eof; 
	_test_eof34: cs = 34; goto _test_eof; 
	_test_eof15: cs = 15; goto _test_eof; 
	_test_eof16: cs = 16; goto _test_eof; 
	_test_eof35: cs = 35; goto _test_eof; 
	_test_eof17: cs = 17; goto _test_eof; 
	_test_eof36: cs = 36; goto _test_eof; 
	_test_eof37: cs = 37; goto _test_eof; 
	_test_eof38: cs = 38; goto _test_eof; 
	_test_eof39: cs = 39; goto _test_eof; 
	_test_eof40: cs = 40; goto _test_eof; 
	_test_eof41: cs = 41; goto _test_eof; 
	_test_eof42: cs = 42; goto _test_eof; 
	_test_eof43: cs = 43; goto _test_eof; 
	_test_eof44: cs = 44; goto _test_eof; 
	_test_eof45: cs = 45; goto _test_eof; 
	_test_eof18: cs = 18; goto _test_eof; 
	_test_eof19: cs = 19; goto _test_eof; 
	_test_eof46: cs = 46; goto _test_eof; 
	_test_eof20: cs = 20; goto _test_eof; 
	_test_eof21: cs = 21; goto _test_eof; 
	_test_eof47: cs = 47; goto _test_eof; 
	_test_eof22: cs = 22; goto _test_eof; 
	_test_eof23: cs = 23; goto _test_eof; 
	_test_eof24: cs = 24; goto _test_eof; 
	_test_eof48: cs = 48; goto _test_eof; 
	_test_eof25: cs = 25; goto _test_eof; 
	_test_eof26: cs = 26; goto _test_eof; 
	_test_eof49: cs = 49; goto _test_eof; 
	_test_eof27: cs = 27; goto _test_eof; 
	_test_eof28: cs = 28; goto _test_eof; 
	_test_eof50: cs = 50; goto _test_eof; 
	_test_eof29: cs = 29; goto _test_eof; 
	_test_eof51: cs = 51; goto _test_eof; 
	_test_eof52: cs = 52; goto _test_eof; 
	_test_eof53: cs = 53; goto _test_eof; 
	_test_eof54: cs = 54; goto _test_eof; 
	_test_eof55: cs = 55; goto _test_eof; 
	_test_eof56: cs = 56; goto _test_eof; 
	_test_eof57: cs = 57; goto _test_eof; 
	_test_eof58: cs = 58; goto _test_eof; 
	_test_eof59: cs = 59; goto _test_eof; 
	_test_eof30: cs = 30; goto _test_eof; 
	_test_eof60: cs = 60; goto _test_eof; 
	_test_eof31: cs = 31; goto _test_eof; 
	_test_eof61: cs = 61; goto _test_eof; 

	_test_eof: {}
	if ( p == eof )
	{
	switch ( cs ) {
	case 32: 
	case 48: 
#line 30 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_day(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_DAY;
      {p++; cs = 0; goto _out;}
    }
    tstr_parsed_set_day(parsed, v);
  }
	break;
	case 33: 
	case 49: 
#line 46 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_hour(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_HOUR;
      {p++; cs = 0; goto _out;}
    }
    tstr_parsed_set_hour(parsed, v);
  }
	break;
	case 46: 
	case 60: 
#line 54 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_minute(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_MINUTE;
      {p++; cs = 0; goto _out;}
    }
    tstr_parsed_set_minute(parsed, v);
  }
	break;
	case 47: 
	case 61: 
#line 62 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_second(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_SECOND;
      {p++; cs = 0; goto _out;}
    }
    tstr_parsed_set_second(parsed, v);
  }
	break;
	case 36: 
	case 37: 
	case 38: 
	case 39: 
	case 40: 
	case 41: 
	case 42: 
	case 43: 
	case 44: 
	case 51: 
	case 52: 
	case 53: 
	case 54: 
	case 55: 
	case 56: 
	case 57: 
	case 58: 
	case 59: 
#line 70 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_fraction(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_FRACTION;
      {p++; cs = 0; goto _out;}
    }
    tstr_parsed_set_fraction(parsed, v);
  }
	break;
	case 34: 
	case 35: 
	case 50: 
#line 78 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_tz_offset(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_OFFSET;
      {p++; cs = 0; goto _out;}
    }
    tstr_parsed_set_offset(parsed, v);
  }
	break;
	case 45: 
#line 86 "ragel/tstr_common.rl"
	{
    tstr_parsed_set_tz_utc(parsed, mark, p - mark);
  }
	break;
#line 1128 "tstr_cparse_iso8601.c"
	}
	}

	_out: {}
	}

#line 66 "ragel/tstr_cparse_iso8601.rl"

  if (result != TSTR_PARSE_OK)
    return result;

  return (cs >= iso8601_first_final) ? TSTR_PARSE_OK : TSTR_PARSE_NOMATCH;
}
