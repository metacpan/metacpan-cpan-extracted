
#line 1 "ragel/tstr_cparse_ecmascript.rl"
#include <stddef.h>
#include <stdbool.h>
#include <string.h>

#include "tstr_parsed.h"
#include "tstr_token_parse.h"
#include "tstr_cparse.h"


#line 30 "ragel/tstr_cparse_ecmascript.rl"



#line 17 "tstr_cparse_ecmascript.c"
static const int ecmascript_start = 1;
static const int ecmascript_first_final = 64;
static const int ecmascript_error = 0;

static const int ecmascript_en_main = 1;


#line 33 "ragel/tstr_cparse_ecmascript.rl"

tstr_parse_result_t tstr_cparse_ecmascript(const char* p,
                                           size_t len,
                                           tstr_parsed_t* parsed) {
  int cs, v;
  const char* pe = p + len;
  const char* eof = pe;
  const char* mark = NULL;
  tstr_parse_result_t result = TSTR_PARSE_OK;

  (void)tstr_parsed_init(parsed);

  
#line 39 "tstr_cparse_ecmascript.c"
	{
	cs = ecmascript_start;
	}

#line 46 "ragel/tstr_cparse_ecmascript.rl"
  
#line 46 "tstr_cparse_ecmascript.c"
	{
	if ( p == pe )
		goto _test_eof;
	switch ( cs )
	{
case 1:
	switch( (*p) ) {
		case 70: goto tr0;
		case 77: goto tr2;
		case 83: goto tr3;
		case 84: goto tr4;
		case 87: goto tr5;
	}
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
#line 72 "tstr_cparse_ecmascript.c"
	if ( (*p) == 114 )
		goto st3;
	goto st0;
st3:
	if ( ++p == pe )
		goto _test_eof3;
case 3:
	if ( (*p) == 105 )
		goto st4;
	goto st0;
st4:
	if ( ++p == pe )
		goto _test_eof4;
case 4:
	if ( (*p) == 32 )
		goto tr8;
	goto st0;
tr8:
#line 38 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_day_name(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_DAY_NAME;
      {p++; cs = 5; goto _out;}
    }
    tstr_parsed_set_day_name(parsed, v);
  }
	goto st5;
st5:
	if ( ++p == pe )
		goto _test_eof5;
case 5:
#line 104 "tstr_cparse_ecmascript.c"
	switch( (*p) ) {
		case 65: goto tr9;
		case 68: goto tr10;
		case 70: goto tr11;
		case 74: goto tr12;
		case 77: goto tr13;
		case 78: goto tr14;
		case 79: goto tr15;
		case 83: goto tr16;
	}
	goto st0;
tr9:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st6;
st6:
	if ( ++p == pe )
		goto _test_eof6;
case 6:
#line 124 "tstr_cparse_ecmascript.c"
	switch( (*p) ) {
		case 112: goto st7;
		case 117: goto st39;
	}
	goto st0;
st7:
	if ( ++p == pe )
		goto _test_eof7;
case 7:
	if ( (*p) == 114 )
		goto st8;
	goto st0;
st8:
	if ( ++p == pe )
		goto _test_eof8;
case 8:
	if ( (*p) == 32 )
		goto tr20;
	goto st0;
tr20:
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
#line 158 "tstr_cparse_ecmascript.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr21;
	goto st0;
tr21:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st10;
st10:
	if ( ++p == pe )
		goto _test_eof10;
case 10:
#line 170 "tstr_cparse_ecmascript.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st11;
	goto st0;
st11:
	if ( ++p == pe )
		goto _test_eof11;
case 11:
	if ( (*p) == 32 )
		goto tr23;
	goto st0;
tr23:
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
#line 195 "tstr_cparse_ecmascript.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr24;
	goto st0;
tr24:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st13;
st13:
	if ( ++p == pe )
		goto _test_eof13;
case 13:
#line 207 "tstr_cparse_ecmascript.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st14;
	goto st0;
st14:
	if ( ++p == pe )
		goto _test_eof14;
case 14:
	if ( 48 <= (*p) && (*p) <= 57 )
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
	if ( (*p) == 32 )
		goto tr28;
	goto st0;
tr28:
#line 6 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_year(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_YEAR;
      {p++; cs = 17; goto _out;}
    }
    tstr_parsed_set_year4(parsed, v);
  }
	goto st17;
st17:
	if ( ++p == pe )
		goto _test_eof17;
case 17:
#line 246 "tstr_cparse_ecmascript.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr29;
	goto st0;
tr29:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st18;
st18:
	if ( ++p == pe )
		goto _test_eof18;
case 18:
#line 258 "tstr_cparse_ecmascript.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st19;
	goto st0;
st19:
	if ( ++p == pe )
		goto _test_eof19;
case 19:
	if ( (*p) == 58 )
		goto tr31;
	goto st0;
tr31:
#line 46 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_hour(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_HOUR;
      {p++; cs = 20; goto _out;}
    }
    tstr_parsed_set_hour(parsed, v);
  }
	goto st20;
st20:
	if ( ++p == pe )
		goto _test_eof20;
case 20:
#line 283 "tstr_cparse_ecmascript.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr32;
	goto st0;
tr32:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st21;
st21:
	if ( ++p == pe )
		goto _test_eof21;
case 21:
#line 295 "tstr_cparse_ecmascript.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st22;
	goto st0;
st22:
	if ( ++p == pe )
		goto _test_eof22;
case 22:
	if ( (*p) == 58 )
		goto tr34;
	goto st0;
tr34:
#line 54 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_minute(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_MINUTE;
      {p++; cs = 23; goto _out;}
    }
    tstr_parsed_set_minute(parsed, v);
  }
	goto st23;
st23:
	if ( ++p == pe )
		goto _test_eof23;
case 23:
#line 320 "tstr_cparse_ecmascript.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr35;
	goto st0;
tr35:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st24;
st24:
	if ( ++p == pe )
		goto _test_eof24;
case 24:
#line 332 "tstr_cparse_ecmascript.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st25;
	goto st0;
st25:
	if ( ++p == pe )
		goto _test_eof25;
case 25:
	if ( (*p) == 32 )
		goto tr37;
	goto st0;
tr37:
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
#line 357 "tstr_cparse_ecmascript.c"
	switch( (*p) ) {
		case 43: goto tr38;
		case 45: goto tr38;
		case 71: goto tr39;
		case 85: goto tr40;
	}
	goto st0;
tr38:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st27;
tr50:
#line 86 "ragel/tstr_common.rl"
	{
    tstr_parsed_set_tz_utc(parsed, mark, p - mark);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st27;
st27:
	if ( ++p == pe )
		goto _test_eof27;
case 27:
#line 381 "tstr_cparse_ecmascript.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st28;
	goto st0;
st28:
	if ( ++p == pe )
		goto _test_eof28;
case 28:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st29;
	goto st0;
st29:
	if ( ++p == pe )
		goto _test_eof29;
case 29:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st30;
	goto st0;
st30:
	if ( ++p == pe )
		goto _test_eof30;
case 30:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st64;
	goto st0;
st64:
	if ( ++p == pe )
		goto _test_eof64;
case 64:
	if ( (*p) == 32 )
		goto tr65;
	goto st0;
tr65:
#line 78 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_tz_offset(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_OFFSET;
      {p++; cs = 31; goto _out;}
    }
    tstr_parsed_set_offset(parsed, v);
  }
	goto st31;
st31:
	if ( ++p == pe )
		goto _test_eof31;
case 31:
#line 427 "tstr_cparse_ecmascript.c"
	if ( (*p) == 40 )
		goto st32;
	goto st0;
st32:
	if ( ++p == pe )
		goto _test_eof32;
case 32:
	if ( 40 <= (*p) && (*p) <= 41 )
		goto st0;
	goto st33;
st33:
	if ( ++p == pe )
		goto _test_eof33;
case 33:
	switch( (*p) ) {
		case 40: goto st0;
		case 41: goto st65;
	}
	goto st33;
st65:
	if ( ++p == pe )
		goto _test_eof65;
case 65:
	goto st0;
tr39:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st34;
st34:
	if ( ++p == pe )
		goto _test_eof34;
case 34:
#line 460 "tstr_cparse_ecmascript.c"
	if ( (*p) == 77 )
		goto st35;
	goto st0;
st35:
	if ( ++p == pe )
		goto _test_eof35;
case 35:
	if ( (*p) == 84 )
		goto st36;
	goto st0;
st36:
	if ( ++p == pe )
		goto _test_eof36;
case 36:
	switch( (*p) ) {
		case 43: goto tr50;
		case 45: goto tr50;
	}
	goto st0;
tr40:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st37;
st37:
	if ( ++p == pe )
		goto _test_eof37;
case 37:
#line 488 "tstr_cparse_ecmascript.c"
	if ( (*p) == 84 )
		goto st38;
	goto st0;
st38:
	if ( ++p == pe )
		goto _test_eof38;
case 38:
	if ( (*p) == 67 )
		goto st36;
	goto st0;
st39:
	if ( ++p == pe )
		goto _test_eof39;
case 39:
	if ( (*p) == 103 )
		goto st8;
	goto st0;
tr10:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st40;
st40:
	if ( ++p == pe )
		goto _test_eof40;
case 40:
#line 514 "tstr_cparse_ecmascript.c"
	if ( (*p) == 101 )
		goto st41;
	goto st0;
st41:
	if ( ++p == pe )
		goto _test_eof41;
case 41:
	if ( (*p) == 99 )
		goto st8;
	goto st0;
tr11:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st42;
st42:
	if ( ++p == pe )
		goto _test_eof42;
case 42:
#line 533 "tstr_cparse_ecmascript.c"
	if ( (*p) == 101 )
		goto st43;
	goto st0;
st43:
	if ( ++p == pe )
		goto _test_eof43;
case 43:
	if ( (*p) == 98 )
		goto st8;
	goto st0;
tr12:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st44;
st44:
	if ( ++p == pe )
		goto _test_eof44;
case 44:
#line 552 "tstr_cparse_ecmascript.c"
	switch( (*p) ) {
		case 97: goto st45;
		case 117: goto st46;
	}
	goto st0;
st45:
	if ( ++p == pe )
		goto _test_eof45;
case 45:
	if ( (*p) == 110 )
		goto st8;
	goto st0;
st46:
	if ( ++p == pe )
		goto _test_eof46;
case 46:
	switch( (*p) ) {
		case 108: goto st8;
		case 110: goto st8;
	}
	goto st0;
tr13:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st47;
st47:
	if ( ++p == pe )
		goto _test_eof47;
case 47:
#line 582 "tstr_cparse_ecmascript.c"
	if ( (*p) == 97 )
		goto st48;
	goto st0;
st48:
	if ( ++p == pe )
		goto _test_eof48;
case 48:
	switch( (*p) ) {
		case 114: goto st8;
		case 121: goto st8;
	}
	goto st0;
tr14:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st49;
st49:
	if ( ++p == pe )
		goto _test_eof49;
case 49:
#line 603 "tstr_cparse_ecmascript.c"
	if ( (*p) == 111 )
		goto st50;
	goto st0;
st50:
	if ( ++p == pe )
		goto _test_eof50;
case 50:
	if ( (*p) == 118 )
		goto st8;
	goto st0;
tr15:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st51;
st51:
	if ( ++p == pe )
		goto _test_eof51;
case 51:
#line 622 "tstr_cparse_ecmascript.c"
	if ( (*p) == 99 )
		goto st52;
	goto st0;
st52:
	if ( ++p == pe )
		goto _test_eof52;
case 52:
	if ( (*p) == 116 )
		goto st8;
	goto st0;
tr16:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st53;
st53:
	if ( ++p == pe )
		goto _test_eof53;
case 53:
#line 641 "tstr_cparse_ecmascript.c"
	if ( (*p) == 101 )
		goto st54;
	goto st0;
st54:
	if ( ++p == pe )
		goto _test_eof54;
case 54:
	if ( (*p) == 112 )
		goto st8;
	goto st0;
tr2:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st55;
st55:
	if ( ++p == pe )
		goto _test_eof55;
case 55:
#line 660 "tstr_cparse_ecmascript.c"
	if ( (*p) == 111 )
		goto st56;
	goto st0;
st56:
	if ( ++p == pe )
		goto _test_eof56;
case 56:
	if ( (*p) == 110 )
		goto st4;
	goto st0;
tr3:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st57;
st57:
	if ( ++p == pe )
		goto _test_eof57;
case 57:
#line 679 "tstr_cparse_ecmascript.c"
	switch( (*p) ) {
		case 97: goto st58;
		case 117: goto st56;
	}
	goto st0;
st58:
	if ( ++p == pe )
		goto _test_eof58;
case 58:
	if ( (*p) == 116 )
		goto st4;
	goto st0;
tr4:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st59;
st59:
	if ( ++p == pe )
		goto _test_eof59;
case 59:
#line 700 "tstr_cparse_ecmascript.c"
	switch( (*p) ) {
		case 104: goto st60;
		case 117: goto st61;
	}
	goto st0;
st60:
	if ( ++p == pe )
		goto _test_eof60;
case 60:
	if ( (*p) == 117 )
		goto st4;
	goto st0;
st61:
	if ( ++p == pe )
		goto _test_eof61;
case 61:
	if ( (*p) == 101 )
		goto st4;
	goto st0;
tr5:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st62;
st62:
	if ( ++p == pe )
		goto _test_eof62;
case 62:
#line 728 "tstr_cparse_ecmascript.c"
	if ( (*p) == 101 )
		goto st63;
	goto st0;
st63:
	if ( ++p == pe )
		goto _test_eof63;
case 63:
	if ( (*p) == 100 )
		goto st4;
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
	_test_eof26: cs = 26; goto _test_eof; 
	_test_eof27: cs = 27; goto _test_eof; 
	_test_eof28: cs = 28; goto _test_eof; 
	_test_eof29: cs = 29; goto _test_eof; 
	_test_eof30: cs = 30; goto _test_eof; 
	_test_eof64: cs = 64; goto _test_eof; 
	_test_eof31: cs = 31; goto _test_eof; 
	_test_eof32: cs = 32; goto _test_eof; 
	_test_eof33: cs = 33; goto _test_eof; 
	_test_eof65: cs = 65; goto _test_eof; 
	_test_eof34: cs = 34; goto _test_eof; 
	_test_eof35: cs = 35; goto _test_eof; 
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
	_test_eof46: cs = 46; goto _test_eof; 
	_test_eof47: cs = 47; goto _test_eof; 
	_test_eof48: cs = 48; goto _test_eof; 
	_test_eof49: cs = 49; goto _test_eof; 
	_test_eof50: cs = 50; goto _test_eof; 
	_test_eof51: cs = 51; goto _test_eof; 
	_test_eof52: cs = 52; goto _test_eof; 
	_test_eof53: cs = 53; goto _test_eof; 
	_test_eof54: cs = 54; goto _test_eof; 
	_test_eof55: cs = 55; goto _test_eof; 
	_test_eof56: cs = 56; goto _test_eof; 
	_test_eof57: cs = 57; goto _test_eof; 
	_test_eof58: cs = 58; goto _test_eof; 
	_test_eof59: cs = 59; goto _test_eof; 
	_test_eof60: cs = 60; goto _test_eof; 
	_test_eof61: cs = 61; goto _test_eof; 
	_test_eof62: cs = 62; goto _test_eof; 
	_test_eof63: cs = 63; goto _test_eof; 

	_test_eof: {}
	if ( p == eof )
	{
	switch ( cs ) {
	case 64: 
#line 78 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_tz_offset(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_OFFSET;
      {p++; cs = 0; goto _out;}
    }
    tstr_parsed_set_offset(parsed, v);
  }
	break;
#line 819 "tstr_cparse_ecmascript.c"
	}
	}

	_out: {}
	}

#line 47 "ragel/tstr_cparse_ecmascript.rl"

  if (result != TSTR_PARSE_OK)
    return result;

  return (cs >= ecmascript_first_final) ? TSTR_PARSE_OK : TSTR_PARSE_NOMATCH;
}
