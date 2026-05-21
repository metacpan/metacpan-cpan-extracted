
#line 1 "ragel/tstr_cparse_rfc2822.rl"
#include <stddef.h>
#include <stdbool.h>
#include <string.h>

#include "tstr_parsed.h"
#include "tstr_token_parse.h"
#include "tstr_cparse.h"


#line 34 "ragel/tstr_cparse_rfc2822.rl"



#line 17 "tstr_cparse_rfc2822.c"
static const int rfc2822_start = 1;
static const int rfc2822_first_final = 65;
static const int rfc2822_error = 0;

static const int rfc2822_en_main = 1;


#line 37 "ragel/tstr_cparse_rfc2822.rl"

tstr_parse_result_t tstr_cparse_rfc2822(const char* p,
                                        size_t len,
                                        tstr_parsed_t* parsed) {
  int cs, v;
  const char* pe = p + len;
  const char* eof = pe;
  const char* mark = NULL;
  tstr_parse_result_t result = TSTR_PARSE_OK;

  (void)tstr_parsed_init(parsed);

  
#line 39 "tstr_cparse_rfc2822.c"
	{
	cs = rfc2822_start;
	}

#line 50 "ragel/tstr_cparse_rfc2822.rl"
  
#line 46 "tstr_cparse_rfc2822.c"
	{
	if ( p == pe )
		goto _test_eof;
	switch ( cs )
	{
case 1:
	switch( (*p) ) {
		case 70: goto tr2;
		case 77: goto tr3;
		case 83: goto tr4;
		case 84: goto tr5;
		case 87: goto tr6;
		case 102: goto tr2;
		case 109: goto tr3;
		case 115: goto tr4;
		case 116: goto tr5;
		case 119: goto tr6;
	}
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
#line 79 "tstr_cparse_rfc2822.c"
	if ( (*p) == 32 )
		goto tr7;
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st50;
	goto st0;
tr7:
#line 30 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_day(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_DAY;
      {p++; cs = 3; goto _out;}
    }
    tstr_parsed_set_day(parsed, v);
  }
	goto st3;
st3:
	if ( ++p == pe )
		goto _test_eof3;
case 3:
#line 99 "tstr_cparse_rfc2822.c"
	switch( (*p) ) {
		case 65: goto tr9;
		case 68: goto tr10;
		case 70: goto tr11;
		case 74: goto tr12;
		case 77: goto tr13;
		case 78: goto tr14;
		case 79: goto tr15;
		case 83: goto tr16;
		case 97: goto tr9;
		case 100: goto tr10;
		case 102: goto tr11;
		case 106: goto tr12;
		case 109: goto tr13;
		case 110: goto tr14;
		case 111: goto tr15;
		case 115: goto tr16;
	}
	goto st0;
tr9:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st4;
st4:
	if ( ++p == pe )
		goto _test_eof4;
case 4:
#line 127 "tstr_cparse_rfc2822.c"
	switch( (*p) ) {
		case 80: goto st5;
		case 85: goto st34;
		case 112: goto st5;
		case 117: goto st34;
	}
	goto st0;
st5:
	if ( ++p == pe )
		goto _test_eof5;
case 5:
	switch( (*p) ) {
		case 82: goto st6;
		case 114: goto st6;
	}
	goto st0;
st6:
	if ( ++p == pe )
		goto _test_eof6;
case 6:
	if ( (*p) == 32 )
		goto tr20;
	goto st0;
tr20:
#line 22 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_month(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_MONTH;
      {p++; cs = 7; goto _out;}
    }
    tstr_parsed_set_month(parsed, v);
  }
	goto st7;
st7:
	if ( ++p == pe )
		goto _test_eof7;
case 7:
#line 165 "tstr_cparse_rfc2822.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr21;
	goto st0;
tr21:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st8;
st8:
	if ( ++p == pe )
		goto _test_eof8;
case 8:
#line 177 "tstr_cparse_rfc2822.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st9;
	goto st0;
st9:
	if ( ++p == pe )
		goto _test_eof9;
case 9:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st10;
	goto st0;
st10:
	if ( ++p == pe )
		goto _test_eof10;
case 10:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st11;
	goto st0;
st11:
	if ( ++p == pe )
		goto _test_eof11;
case 11:
	if ( (*p) == 32 )
		goto tr25;
	goto st0;
tr25:
#line 6 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_year(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_YEAR;
      {p++; cs = 12; goto _out;}
    }
    tstr_parsed_set_year4(parsed, v);
  }
	goto st12;
st12:
	if ( ++p == pe )
		goto _test_eof12;
case 12:
#line 216 "tstr_cparse_rfc2822.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr26;
	goto st0;
tr26:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st13;
st13:
	if ( ++p == pe )
		goto _test_eof13;
case 13:
#line 228 "tstr_cparse_rfc2822.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st14;
	goto st0;
st14:
	if ( ++p == pe )
		goto _test_eof14;
case 14:
	if ( (*p) == 58 )
		goto tr28;
	goto st0;
tr28:
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
#line 253 "tstr_cparse_rfc2822.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr29;
	goto st0;
tr29:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st16;
st16:
	if ( ++p == pe )
		goto _test_eof16;
case 16:
#line 265 "tstr_cparse_rfc2822.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st17;
	goto st0;
st17:
	if ( ++p == pe )
		goto _test_eof17;
case 17:
	switch( (*p) ) {
		case 32: goto tr31;
		case 58: goto tr32;
	}
	goto st0;
tr31:
#line 54 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_minute(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_MINUTE;
      {p++; cs = 18; goto _out;}
    }
    tstr_parsed_set_minute(parsed, v);
  }
	goto st18;
tr51:
#line 62 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_second(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_SECOND;
      {p++; cs = 18; goto _out;}
    }
    tstr_parsed_set_second(parsed, v);
  }
	goto st18;
st18:
	if ( ++p == pe )
		goto _test_eof18;
case 18:
#line 302 "tstr_cparse_rfc2822.c"
	switch( (*p) ) {
		case 43: goto tr33;
		case 45: goto tr33;
		case 71: goto tr35;
		case 85: goto tr36;
	}
	if ( 65 <= (*p) && (*p) <= 90 )
		goto tr34;
	goto st0;
tr33:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st19;
st19:
	if ( ++p == pe )
		goto _test_eof19;
case 19:
#line 320 "tstr_cparse_rfc2822.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st20;
	goto st0;
st20:
	if ( ++p == pe )
		goto _test_eof20;
case 20:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st21;
	goto st0;
st21:
	if ( ++p == pe )
		goto _test_eof21;
case 21:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st22;
	goto st0;
st22:
	if ( ++p == pe )
		goto _test_eof22;
case 22:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st65;
	goto st0;
st65:
	if ( ++p == pe )
		goto _test_eof65;
case 65:
	if ( (*p) == 32 )
		goto tr69;
	goto st0;
tr69:
#line 78 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_tz_offset(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_OFFSET;
      {p++; cs = 23; goto _out;}
    }
    tstr_parsed_set_offset(parsed, v);
  }
	goto st23;
tr70:
#line 90 "ragel/tstr_common.rl"
	{
    tstr_parsed_set_tz_abbrev(parsed, mark, p - mark);
  }
	goto st23;
tr74:
#line 86 "ragel/tstr_common.rl"
	{
    tstr_parsed_set_tz_utc(parsed, mark, p - mark);
  }
	goto st23;
st23:
	if ( ++p == pe )
		goto _test_eof23;
case 23:
#line 378 "tstr_cparse_rfc2822.c"
	if ( (*p) == 40 )
		goto st24;
	goto st0;
st24:
	if ( ++p == pe )
		goto _test_eof24;
case 24:
	if ( 40 <= (*p) && (*p) <= 41 )
		goto st0;
	goto st25;
st25:
	if ( ++p == pe )
		goto _test_eof25;
case 25:
	switch( (*p) ) {
		case 40: goto st0;
		case 41: goto st66;
	}
	goto st25;
st66:
	if ( ++p == pe )
		goto _test_eof66;
case 66:
	goto st0;
tr34:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st26;
st26:
	if ( ++p == pe )
		goto _test_eof26;
case 26:
#line 411 "tstr_cparse_rfc2822.c"
	if ( (*p) > 90 ) {
		if ( 97 <= (*p) && (*p) <= 122 )
			goto st27;
	} else if ( (*p) >= 65 )
		goto st27;
	goto st0;
st27:
	if ( ++p == pe )
		goto _test_eof27;
case 27:
	if ( 65 <= (*p) && (*p) <= 90 )
		goto st67;
	goto st0;
st67:
	if ( ++p == pe )
		goto _test_eof67;
case 67:
	if ( (*p) == 32 )
		goto tr70;
	if ( 65 <= (*p) && (*p) <= 90 )
		goto st68;
	goto st0;
st68:
	if ( ++p == pe )
		goto _test_eof68;
case 68:
	if ( (*p) == 32 )
		goto tr70;
	if ( 65 <= (*p) && (*p) <= 90 )
		goto st69;
	goto st0;
st69:
	if ( ++p == pe )
		goto _test_eof69;
case 69:
	if ( (*p) == 32 )
		goto tr70;
	if ( 65 <= (*p) && (*p) <= 90 )
		goto st70;
	goto st0;
st70:
	if ( ++p == pe )
		goto _test_eof70;
case 70:
	if ( (*p) == 32 )
		goto tr70;
	goto st0;
tr35:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st28;
st28:
	if ( ++p == pe )
		goto _test_eof28;
case 28:
#line 467 "tstr_cparse_rfc2822.c"
	if ( (*p) == 77 )
		goto st29;
	if ( (*p) > 90 ) {
		if ( 97 <= (*p) && (*p) <= 122 )
			goto st27;
	} else if ( (*p) >= 65 )
		goto st27;
	goto st0;
st29:
	if ( ++p == pe )
		goto _test_eof29;
case 29:
	if ( (*p) == 84 )
		goto st71;
	if ( 65 <= (*p) && (*p) <= 90 )
		goto st67;
	goto st0;
st71:
	if ( ++p == pe )
		goto _test_eof71;
case 71:
	if ( (*p) == 32 )
		goto tr74;
	if ( 65 <= (*p) && (*p) <= 90 )
		goto st68;
	goto st0;
tr36:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st30;
st30:
	if ( ++p == pe )
		goto _test_eof30;
case 30:
#line 502 "tstr_cparse_rfc2822.c"
	if ( (*p) == 84 )
		goto st72;
	if ( (*p) > 90 ) {
		if ( 97 <= (*p) && (*p) <= 122 )
			goto st27;
	} else if ( (*p) >= 65 )
		goto st27;
	goto st0;
st72:
	if ( ++p == pe )
		goto _test_eof72;
case 72:
	switch( (*p) ) {
		case 32: goto tr74;
		case 67: goto st71;
	}
	if ( 65 <= (*p) && (*p) <= 90 )
		goto st67;
	goto st0;
tr32:
#line 54 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_minute(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_MINUTE;
      {p++; cs = 31; goto _out;}
    }
    tstr_parsed_set_minute(parsed, v);
  }
	goto st31;
st31:
	if ( ++p == pe )
		goto _test_eof31;
case 31:
#line 536 "tstr_cparse_rfc2822.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr49;
	goto st0;
tr49:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st32;
st32:
	if ( ++p == pe )
		goto _test_eof32;
case 32:
#line 548 "tstr_cparse_rfc2822.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st33;
	goto st0;
st33:
	if ( ++p == pe )
		goto _test_eof33;
case 33:
	if ( (*p) == 32 )
		goto tr51;
	goto st0;
st34:
	if ( ++p == pe )
		goto _test_eof34;
case 34:
	switch( (*p) ) {
		case 71: goto st6;
		case 103: goto st6;
	}
	goto st0;
tr10:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st35;
st35:
	if ( ++p == pe )
		goto _test_eof35;
case 35:
#line 576 "tstr_cparse_rfc2822.c"
	switch( (*p) ) {
		case 69: goto st36;
		case 101: goto st36;
	}
	goto st0;
st36:
	if ( ++p == pe )
		goto _test_eof36;
case 36:
	switch( (*p) ) {
		case 67: goto st6;
		case 99: goto st6;
	}
	goto st0;
tr11:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st37;
st37:
	if ( ++p == pe )
		goto _test_eof37;
case 37:
#line 599 "tstr_cparse_rfc2822.c"
	switch( (*p) ) {
		case 69: goto st38;
		case 101: goto st38;
	}
	goto st0;
st38:
	if ( ++p == pe )
		goto _test_eof38;
case 38:
	switch( (*p) ) {
		case 66: goto st6;
		case 98: goto st6;
	}
	goto st0;
tr12:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st39;
st39:
	if ( ++p == pe )
		goto _test_eof39;
case 39:
#line 622 "tstr_cparse_rfc2822.c"
	switch( (*p) ) {
		case 65: goto st40;
		case 85: goto st41;
		case 97: goto st40;
		case 117: goto st41;
	}
	goto st0;
st40:
	if ( ++p == pe )
		goto _test_eof40;
case 40:
	switch( (*p) ) {
		case 78: goto st6;
		case 110: goto st6;
	}
	goto st0;
st41:
	if ( ++p == pe )
		goto _test_eof41;
case 41:
	switch( (*p) ) {
		case 76: goto st6;
		case 78: goto st6;
		case 108: goto st6;
		case 110: goto st6;
	}
	goto st0;
tr13:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st42;
st42:
	if ( ++p == pe )
		goto _test_eof42;
case 42:
#line 658 "tstr_cparse_rfc2822.c"
	switch( (*p) ) {
		case 65: goto st43;
		case 97: goto st43;
	}
	goto st0;
st43:
	if ( ++p == pe )
		goto _test_eof43;
case 43:
	switch( (*p) ) {
		case 82: goto st6;
		case 89: goto st6;
		case 114: goto st6;
		case 121: goto st6;
	}
	goto st0;
tr14:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st44;
st44:
	if ( ++p == pe )
		goto _test_eof44;
case 44:
#line 683 "tstr_cparse_rfc2822.c"
	switch( (*p) ) {
		case 79: goto st45;
		case 111: goto st45;
	}
	goto st0;
st45:
	if ( ++p == pe )
		goto _test_eof45;
case 45:
	switch( (*p) ) {
		case 86: goto st6;
		case 118: goto st6;
	}
	goto st0;
tr15:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st46;
st46:
	if ( ++p == pe )
		goto _test_eof46;
case 46:
#line 706 "tstr_cparse_rfc2822.c"
	switch( (*p) ) {
		case 67: goto st47;
		case 99: goto st47;
	}
	goto st0;
st47:
	if ( ++p == pe )
		goto _test_eof47;
case 47:
	switch( (*p) ) {
		case 84: goto st6;
		case 116: goto st6;
	}
	goto st0;
tr16:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st48;
st48:
	if ( ++p == pe )
		goto _test_eof48;
case 48:
#line 729 "tstr_cparse_rfc2822.c"
	switch( (*p) ) {
		case 69: goto st49;
		case 101: goto st49;
	}
	goto st0;
st49:
	if ( ++p == pe )
		goto _test_eof49;
case 49:
	switch( (*p) ) {
		case 80: goto st6;
		case 112: goto st6;
	}
	goto st0;
st50:
	if ( ++p == pe )
		goto _test_eof50;
case 50:
	if ( (*p) == 32 )
		goto tr7;
	goto st0;
tr2:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st51;
st51:
	if ( ++p == pe )
		goto _test_eof51;
case 51:
#line 759 "tstr_cparse_rfc2822.c"
	switch( (*p) ) {
		case 82: goto st52;
		case 114: goto st52;
	}
	goto st0;
st52:
	if ( ++p == pe )
		goto _test_eof52;
case 52:
	switch( (*p) ) {
		case 73: goto st53;
		case 105: goto st53;
	}
	goto st0;
st53:
	if ( ++p == pe )
		goto _test_eof53;
case 53:
	if ( (*p) == 44 )
		goto tr62;
	goto st0;
tr62:
#line 38 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_day_name(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_DAY_NAME;
      {p++; cs = 54; goto _out;}
    }
    tstr_parsed_set_day_name(parsed, v);
  }
	goto st54;
st54:
	if ( ++p == pe )
		goto _test_eof54;
case 54:
#line 795 "tstr_cparse_rfc2822.c"
	if ( (*p) == 32 )
		goto st55;
	goto st0;
st55:
	if ( ++p == pe )
		goto _test_eof55;
case 55:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr0;
	goto st0;
tr3:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st56;
st56:
	if ( ++p == pe )
		goto _test_eof56;
case 56:
#line 814 "tstr_cparse_rfc2822.c"
	switch( (*p) ) {
		case 79: goto st57;
		case 111: goto st57;
	}
	goto st0;
st57:
	if ( ++p == pe )
		goto _test_eof57;
case 57:
	switch( (*p) ) {
		case 78: goto st53;
		case 110: goto st53;
	}
	goto st0;
tr4:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st58;
st58:
	if ( ++p == pe )
		goto _test_eof58;
case 58:
#line 837 "tstr_cparse_rfc2822.c"
	switch( (*p) ) {
		case 65: goto st59;
		case 85: goto st57;
		case 97: goto st59;
		case 117: goto st57;
	}
	goto st0;
st59:
	if ( ++p == pe )
		goto _test_eof59;
case 59:
	switch( (*p) ) {
		case 84: goto st53;
		case 116: goto st53;
	}
	goto st0;
tr5:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st60;
st60:
	if ( ++p == pe )
		goto _test_eof60;
case 60:
#line 862 "tstr_cparse_rfc2822.c"
	switch( (*p) ) {
		case 72: goto st61;
		case 85: goto st62;
		case 104: goto st61;
		case 117: goto st62;
	}
	goto st0;
st61:
	if ( ++p == pe )
		goto _test_eof61;
case 61:
	switch( (*p) ) {
		case 85: goto st53;
		case 117: goto st53;
	}
	goto st0;
st62:
	if ( ++p == pe )
		goto _test_eof62;
case 62:
	switch( (*p) ) {
		case 69: goto st53;
		case 101: goto st53;
	}
	goto st0;
tr6:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st63;
st63:
	if ( ++p == pe )
		goto _test_eof63;
case 63:
#line 896 "tstr_cparse_rfc2822.c"
	switch( (*p) ) {
		case 69: goto st64;
		case 101: goto st64;
	}
	goto st0;
st64:
	if ( ++p == pe )
		goto _test_eof64;
case 64:
	switch( (*p) ) {
		case 68: goto st53;
		case 100: goto st53;
	}
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
	_test_eof65: cs = 65; goto _test_eof; 
	_test_eof23: cs = 23; goto _test_eof; 
	_test_eof24: cs = 24; goto _test_eof; 
	_test_eof25: cs = 25; goto _test_eof; 
	_test_eof66: cs = 66; goto _test_eof; 
	_test_eof26: cs = 26; goto _test_eof; 
	_test_eof27: cs = 27; goto _test_eof; 
	_test_eof67: cs = 67; goto _test_eof; 
	_test_eof68: cs = 68; goto _test_eof; 
	_test_eof69: cs = 69; goto _test_eof; 
	_test_eof70: cs = 70; goto _test_eof; 
	_test_eof28: cs = 28; goto _test_eof; 
	_test_eof29: cs = 29; goto _test_eof; 
	_test_eof71: cs = 71; goto _test_eof; 
	_test_eof30: cs = 30; goto _test_eof; 
	_test_eof72: cs = 72; goto _test_eof; 
	_test_eof31: cs = 31; goto _test_eof; 
	_test_eof32: cs = 32; goto _test_eof; 
	_test_eof33: cs = 33; goto _test_eof; 
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
	_test_eof64: cs = 64; goto _test_eof; 

	_test_eof: {}
	if ( p == eof )
	{
	switch ( cs ) {
	case 65: 
#line 78 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_tz_offset(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_OFFSET;
      {p++; cs = 0; goto _out;}
    }
    tstr_parsed_set_offset(parsed, v);
  }
	break;
	case 71: 
	case 72: 
#line 86 "ragel/tstr_common.rl"
	{
    tstr_parsed_set_tz_utc(parsed, mark, p - mark);
  }
	break;
	case 67: 
	case 68: 
	case 69: 
	case 70: 
#line 90 "ragel/tstr_common.rl"
	{
    tstr_parsed_set_tz_abbrev(parsed, mark, p - mark);
  }
	break;
#line 1014 "tstr_cparse_rfc2822.c"
	}
	}

	_out: {}
	}

#line 51 "ragel/tstr_cparse_rfc2822.rl"

  if (result != TSTR_PARSE_OK)
    return result;

  return (cs >= rfc2822_first_final) ? TSTR_PARSE_OK : TSTR_PARSE_NOMATCH;
}
