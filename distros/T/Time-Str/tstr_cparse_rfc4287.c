
#line 1 "ragel/tstr_cparse_rfc4287.rl"
#include <stddef.h>
#include <stdbool.h>
#include <string.h>

#include "tstr_parsed.h"
#include "tstr_token_parse.h"
#include "tstr_cparse.h"


#line 27 "ragel/tstr_cparse_rfc4287.rl"



#line 17 "tstr_cparse_rfc4287.c"
static const int rfc4287_start = 1;
static const int rfc4287_first_final = 36;
static const int rfc4287_error = 0;

static const int rfc4287_en_main = 1;


#line 30 "ragel/tstr_cparse_rfc4287.rl"

tstr_parse_result_t tstr_cparse_rfc4287(const char* p,
                                        size_t len,
                                        tstr_parsed_t* parsed) {
  int cs, v;
  const char* pe = p + len;
  const char* eof = pe;
  const char* mark = NULL;
  tstr_parse_result_t result = TSTR_PARSE_OK;

  (void)tstr_parsed_init(parsed);

  
#line 39 "tstr_cparse_rfc4287.c"
	{
	cs = rfc4287_start;
	}

#line 43 "ragel/tstr_cparse_rfc4287.rl"
  
#line 46 "tstr_cparse_rfc4287.c"
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
#line 67 "tstr_cparse_rfc4287.c"
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
#line 106 "tstr_cparse_rfc4287.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr6;
	goto st0;
tr6:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st7;
st7:
	if ( ++p == pe )
		goto _test_eof7;
case 7:
#line 118 "tstr_cparse_rfc4287.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st8;
	goto st0;
st8:
	if ( ++p == pe )
		goto _test_eof8;
case 8:
	if ( (*p) == 45 )
		goto tr8;
	goto st0;
tr8:
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
#line 143 "tstr_cparse_rfc4287.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr9;
	goto st0;
tr9:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st10;
st10:
	if ( ++p == pe )
		goto _test_eof10;
case 10:
#line 155 "tstr_cparse_rfc4287.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st11;
	goto st0;
st11:
	if ( ++p == pe )
		goto _test_eof11;
case 11:
	if ( (*p) == 84 )
		goto tr11;
	goto st0;
tr11:
#line 30 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_day(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_DAY;
      {p++; cs = 12; goto _out;}
    }
    tstr_parsed_set_day(parsed, v);
  }
	goto st12;
st12:
	if ( ++p == pe )
		goto _test_eof12;
case 12:
#line 180 "tstr_cparse_rfc4287.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr12;
	goto st0;
tr12:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st13;
st13:
	if ( ++p == pe )
		goto _test_eof13;
case 13:
#line 192 "tstr_cparse_rfc4287.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st14;
	goto st0;
st14:
	if ( ++p == pe )
		goto _test_eof14;
case 14:
	if ( (*p) == 58 )
		goto tr14;
	goto st0;
tr14:
#line 46 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_hour(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_HOUR;
      {p++; cs = 15; goto _out;}
    }
    tstr_parsed_set_hour(parsed, v);
  }
	goto st15;
st15:
	if ( ++p == pe )
		goto _test_eof15;
case 15:
#line 217 "tstr_cparse_rfc4287.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr15;
	goto st0;
tr15:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st16;
st16:
	if ( ++p == pe )
		goto _test_eof16;
case 16:
#line 229 "tstr_cparse_rfc4287.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st17;
	goto st0;
st17:
	if ( ++p == pe )
		goto _test_eof17;
case 17:
	if ( (*p) == 58 )
		goto tr17;
	goto st0;
tr17:
#line 54 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_minute(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_MINUTE;
      {p++; cs = 18; goto _out;}
    }
    tstr_parsed_set_minute(parsed, v);
  }
	goto st18;
st18:
	if ( ++p == pe )
		goto _test_eof18;
case 18:
#line 254 "tstr_cparse_rfc4287.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr18;
	goto st0;
tr18:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st19;
st19:
	if ( ++p == pe )
		goto _test_eof19;
case 19:
#line 266 "tstr_cparse_rfc4287.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st20;
	goto st0;
st20:
	if ( ++p == pe )
		goto _test_eof20;
case 20:
	switch( (*p) ) {
		case 43: goto tr20;
		case 45: goto tr20;
		case 46: goto tr21;
		case 90: goto tr22;
	}
	goto st0;
tr20:
#line 62 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_second(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_SECOND;
      {p++; cs = 21; goto _out;}
    }
    tstr_parsed_set_second(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st21;
tr29:
#line 70 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_fraction(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_FRACTION;
      {p++; cs = 21; goto _out;}
    }
    tstr_parsed_set_fraction(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st21;
st21:
	if ( ++p == pe )
		goto _test_eof21;
case 21:
#line 309 "tstr_cparse_rfc4287.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st22;
	goto st0;
st22:
	if ( ++p == pe )
		goto _test_eof22;
case 22:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st23;
	goto st0;
st23:
	if ( ++p == pe )
		goto _test_eof23;
case 23:
	if ( (*p) == 58 )
		goto st24;
	goto st0;
st24:
	if ( ++p == pe )
		goto _test_eof24;
case 24:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st25;
	goto st0;
st25:
	if ( ++p == pe )
		goto _test_eof25;
case 25:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st36;
	goto st0;
st36:
	if ( ++p == pe )
		goto _test_eof36;
case 36:
	goto st0;
tr21:
#line 62 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_second(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_SECOND;
      {p++; cs = 26; goto _out;}
    }
    tstr_parsed_set_second(parsed, v);
  }
	goto st26;
st26:
	if ( ++p == pe )
		goto _test_eof26;
case 26:
#line 360 "tstr_cparse_rfc4287.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr28;
	goto st0;
tr28:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st27;
st27:
	if ( ++p == pe )
		goto _test_eof27;
case 27:
#line 372 "tstr_cparse_rfc4287.c"
	switch( (*p) ) {
		case 43: goto tr29;
		case 45: goto tr29;
		case 90: goto tr31;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st28;
	goto st0;
st28:
	if ( ++p == pe )
		goto _test_eof28;
case 28:
	switch( (*p) ) {
		case 43: goto tr29;
		case 45: goto tr29;
		case 90: goto tr31;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st29;
	goto st0;
st29:
	if ( ++p == pe )
		goto _test_eof29;
case 29:
	switch( (*p) ) {
		case 43: goto tr29;
		case 45: goto tr29;
		case 90: goto tr31;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st30;
	goto st0;
st30:
	if ( ++p == pe )
		goto _test_eof30;
case 30:
	switch( (*p) ) {
		case 43: goto tr29;
		case 45: goto tr29;
		case 90: goto tr31;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st31;
	goto st0;
st31:
	if ( ++p == pe )
		goto _test_eof31;
case 31:
	switch( (*p) ) {
		case 43: goto tr29;
		case 45: goto tr29;
		case 90: goto tr31;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st32;
	goto st0;
st32:
	if ( ++p == pe )
		goto _test_eof32;
case 32:
	switch( (*p) ) {
		case 43: goto tr29;
		case 45: goto tr29;
		case 90: goto tr31;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st33;
	goto st0;
st33:
	if ( ++p == pe )
		goto _test_eof33;
case 33:
	switch( (*p) ) {
		case 43: goto tr29;
		case 45: goto tr29;
		case 90: goto tr31;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st34;
	goto st0;
st34:
	if ( ++p == pe )
		goto _test_eof34;
case 34:
	switch( (*p) ) {
		case 43: goto tr29;
		case 45: goto tr29;
		case 90: goto tr31;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st35;
	goto st0;
st35:
	if ( ++p == pe )
		goto _test_eof35;
case 35:
	switch( (*p) ) {
		case 43: goto tr29;
		case 45: goto tr29;
		case 90: goto tr31;
	}
	goto st0;
tr22:
#line 62 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_second(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_SECOND;
      {p++; cs = 37; goto _out;}
    }
    tstr_parsed_set_second(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st37;
tr31:
#line 70 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_fraction(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_FRACTION;
      {p++; cs = 37; goto _out;}
    }
    tstr_parsed_set_fraction(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st37;
st37:
	if ( ++p == pe )
		goto _test_eof37;
case 37:
#line 503 "tstr_cparse_rfc4287.c"
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
	_test_eof11: cs = 11; goto _test_eof; 
	_test_eof12: cs = 12; goto _test_eof; 
	_test_eof13: cs = 13; goto _test_eof; 
	_test_eof14: cs = 14; goto _test_eof; 
	_test_eof15: cs = 15; goto _test_eof; 
	_test_eof16: cs = 16; goto _test_eof; 
	_test_eof17: cs = 17; goto _test_eof; 
	_test_eof18: cs = 18; goto _test_eof; 
	_test_eof19: cs = 19; goto _test_eof; 
	_test_eof20: cs = 20; goto _test_eof; 
	_test_eof21: cs = 21; goto _test_eof; 
	_test_eof22: cs = 22; goto _test_eof; 
	_test_eof23: cs = 23; goto _test_eof; 
	_test_eof24: cs = 24; goto _test_eof; 
	_test_eof25: cs = 25; goto _test_eof; 
	_test_eof36: cs = 36; goto _test_eof; 
	_test_eof26: cs = 26; goto _test_eof; 
	_test_eof27: cs = 27; goto _test_eof; 
	_test_eof28: cs = 28; goto _test_eof; 
	_test_eof29: cs = 29; goto _test_eof; 
	_test_eof30: cs = 30; goto _test_eof; 
	_test_eof31: cs = 31; goto _test_eof; 
	_test_eof32: cs = 32; goto _test_eof; 
	_test_eof33: cs = 33; goto _test_eof; 
	_test_eof34: cs = 34; goto _test_eof; 
	_test_eof35: cs = 35; goto _test_eof; 
	_test_eof37: cs = 37; goto _test_eof; 

	_test_eof: {}
	if ( p == eof )
	{
	switch ( cs ) {
	case 36: 
#line 78 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_tz_offset(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_OFFSET;
      {p++; cs = 0; goto _out;}
    }
    tstr_parsed_set_offset(parsed, v);
  }
	break;
	case 37: 
#line 86 "ragel/tstr_common.rl"
	{
    tstr_parsed_set_tz_utc(parsed, mark, p - mark);
  }
	break;
#line 563 "tstr_cparse_rfc4287.c"
	}
	}

	_out: {}
	}

#line 44 "ragel/tstr_cparse_rfc4287.rl"

  if (result != TSTR_PARSE_OK)
    return result;

  return (cs >= rfc4287_first_final) ? TSTR_PARSE_OK : TSTR_PARSE_NOMATCH;
}
