
#line 1 "ragel/tstr_cparse_datetime.rl"
#include <stddef.h>
#include <stdbool.h>
#include <string.h>

#include "tstr_parsed.h"
#include "tstr_token_parse.h"
#include "tstr_cparse.h"


#line 108 "ragel/tstr_cparse_datetime.rl"



#line 17 "tstr_cparse_datetime.c"
static const int datetime_start = 1;
static const int datetime_first_final = 378;
static const int datetime_error = 0;

static const int datetime_en_main = 1;


#line 111 "ragel/tstr_cparse_datetime.rl"

tstr_parse_result_t tstr_cparse_datetime(const char* p,
                                         size_t len,
                                         tstr_parsed_t* parsed) {
  int cs, v;
  const char* pe = p + len;
  const char* eof = pe;
  const char* mark = NULL;
  const char* mark_day = NULL;
  tstr_parse_result_t result = TSTR_PARSE_OK;
  char sep_char = 0;

  (void)tstr_parsed_init(parsed);

  
#line 41 "tstr_cparse_datetime.c"
	{
	cs = datetime_start;
	}

#line 126 "ragel/tstr_cparse_datetime.rl"
  
#line 48 "tstr_cparse_datetime.c"
	{
	short _widec;
	if ( p == pe )
		goto _test_eof;
	switch ( cs )
	{
case 1:
	switch( (*p) ) {
		case 10: goto tr0;
		case 65: goto tr3;
		case 68: goto tr4;
		case 70: goto tr5;
		case 74: goto tr6;
		case 77: goto tr7;
		case 78: goto tr8;
		case 79: goto tr9;
		case 83: goto tr10;
		case 84: goto tr11;
		case 87: goto tr12;
		case 97: goto tr3;
		case 100: goto tr4;
		case 102: goto tr5;
		case 106: goto tr6;
		case 109: goto tr7;
		case 110: goto tr8;
		case 111: goto tr9;
		case 115: goto tr10;
		case 116: goto tr11;
		case 119: goto tr12;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr2;
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
#line 93 "tstr_cparse_datetime.c"
	if ( (*p) == 32 )
		goto st3;
	goto st0;
st3:
	if ( ++p == pe )
		goto _test_eof3;
case 3:
	if ( (*p) == 32 )
		goto st4;
	goto st0;
st4:
	if ( ++p == pe )
		goto _test_eof4;
case 4:
	if ( (*p) == 32 )
		goto st5;
	goto st0;
st5:
	if ( ++p == pe )
		goto _test_eof5;
case 5:
	if ( (*p) == 32 )
		goto st6;
	goto st0;
st6:
	if ( ++p == pe )
		goto _test_eof6;
case 6:
	if ( (*p) == 32 )
		goto st7;
	goto st0;
st7:
	if ( ++p == pe )
		goto _test_eof7;
case 7:
	if ( (*p) == 32 )
		goto st8;
	goto st0;
st8:
	if ( ++p == pe )
		goto _test_eof8;
case 8:
	if ( (*p) == 32 )
		goto st9;
	goto st0;
st9:
	if ( ++p == pe )
		goto _test_eof9;
case 9:
	if ( (*p) == 32 )
		goto st10;
	goto st0;
st10:
	if ( ++p == pe )
		goto _test_eof10;
case 10:
	if ( (*p) == 32 )
		goto st11;
	goto st0;
st11:
	if ( ++p == pe )
		goto _test_eof11;
case 11:
	if ( (*p) == 32 )
		goto st12;
	goto st0;
st12:
	if ( ++p == pe )
		goto _test_eof12;
case 12:
	if ( (*p) == 32 )
		goto st13;
	goto st0;
st13:
	if ( ++p == pe )
		goto _test_eof13;
case 13:
	if ( (*p) == 32 )
		goto st14;
	goto st0;
st14:
	if ( ++p == pe )
		goto _test_eof14;
case 14:
	if ( (*p) == 32 )
		goto st15;
	goto st0;
st15:
	if ( ++p == pe )
		goto _test_eof15;
case 15:
	if ( (*p) == 32 )
		goto st16;
	goto st0;
st16:
	if ( ++p == pe )
		goto _test_eof16;
case 16:
	if ( (*p) == 32 )
		goto st17;
	goto st0;
st17:
	if ( ++p == pe )
		goto _test_eof17;
case 17:
	if ( (*p) == 32 )
		goto st18;
	goto st0;
st18:
	if ( ++p == pe )
		goto _test_eof18;
case 18:
	if ( (*p) == 32 )
		goto st19;
	goto st0;
st19:
	if ( ++p == pe )
		goto _test_eof19;
case 19:
	if ( (*p) == 32 )
		goto st20;
	goto st0;
st20:
	if ( ++p == pe )
		goto _test_eof20;
case 20:
	if ( (*p) == 32 )
		goto st21;
	goto st0;
st21:
	if ( ++p == pe )
		goto _test_eof21;
case 21:
	if ( (*p) == 32 )
		goto st22;
	goto st0;
st22:
	if ( ++p == pe )
		goto _test_eof22;
case 22:
	if ( (*p) == 32 )
		goto st23;
	goto st0;
st23:
	if ( ++p == pe )
		goto _test_eof23;
case 23:
	if ( (*p) == 32 )
		goto st24;
	goto st0;
st24:
	if ( ++p == pe )
		goto _test_eof24;
case 24:
	if ( (*p) == 32 )
		goto st25;
	goto st0;
st25:
	if ( ++p == pe )
		goto _test_eof25;
case 25:
	switch( (*p) ) {
		case 70: goto st26;
		case 102: goto st26;
	}
	goto st0;
st26:
	if ( ++p == pe )
		goto _test_eof26;
case 26:
	switch( (*p) ) {
		case 82: goto st27;
		case 114: goto st27;
	}
	goto st0;
st27:
	if ( ++p == pe )
		goto _test_eof27;
case 27:
	switch( (*p) ) {
		case 73: goto st28;
		case 105: goto st28;
	}
	goto st0;
st28:
	if ( ++p == pe )
		goto _test_eof28;
case 28:
	switch( (*p) ) {
		case 32: goto tr39;
		case 44: goto tr40;
		case 46: goto tr41;
	}
	goto st0;
tr39:
#line 38 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_day_name(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_DAY_NAME;
      {p++; cs = 29; goto _out;}
    }
    tstr_parsed_set_day_name(parsed, v);
  }
	goto st29;
st29:
	if ( ++p == pe )
		goto _test_eof29;
case 29:
#line 302 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 65: goto tr3;
		case 68: goto tr4;
		case 70: goto tr42;
		case 74: goto tr6;
		case 77: goto tr43;
		case 78: goto tr8;
		case 79: goto tr9;
		case 83: goto tr44;
		case 97: goto tr3;
		case 100: goto tr4;
		case 102: goto tr42;
		case 106: goto tr6;
		case 109: goto tr43;
		case 110: goto tr8;
		case 111: goto tr9;
		case 115: goto tr44;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr2;
	goto st0;
tr2:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
#line 21 "ragel/tstr_cparse_datetime.rl"
	{
    mark_day = p;
  }
	goto st30;
st30:
	if ( ++p == pe )
		goto _test_eof30;
case 30:
#line 336 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 32: goto tr45;
		case 46: goto tr47;
		case 65: goto tr49;
		case 68: goto tr50;
		case 70: goto tr51;
		case 73: goto tr52;
		case 74: goto tr53;
		case 77: goto tr54;
		case 78: goto tr55;
		case 79: goto tr56;
		case 82: goto st293;
		case 83: goto tr58;
		case 84: goto st297;
		case 86: goto tr60;
		case 88: goto tr61;
		case 97: goto tr49;
		case 100: goto tr50;
		case 102: goto tr51;
		case 105: goto tr52;
		case 106: goto tr53;
		case 109: goto tr54;
		case 110: goto tr55;
		case 111: goto tr56;
		case 114: goto st293;
		case 115: goto tr58;
		case 116: goto st297;
		case 118: goto tr60;
		case 120: goto tr61;
	}
	if ( (*p) > 47 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st163;
	} else if ( (*p) >= 45 )
		goto tr46;
	goto st0;
tr45:
#line 25 "ragel/tstr_cparse_datetime.rl"
	{
    mark = mark_day;
  }
#line 30 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_day(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_DAY;
      {p++; cs = 31; goto _out;}
    }
    tstr_parsed_set_day(parsed, v);
  }
	goto st31;
st31:
	if ( ++p == pe )
		goto _test_eof31;
case 31:
#line 391 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 65: goto tr62;
		case 68: goto tr63;
		case 70: goto tr64;
		case 73: goto tr65;
		case 74: goto tr66;
		case 77: goto tr67;
		case 78: goto tr68;
		case 79: goto tr69;
		case 83: goto tr70;
		case 86: goto tr71;
		case 88: goto tr72;
		case 97: goto tr62;
		case 100: goto tr63;
		case 102: goto tr64;
		case 105: goto tr65;
		case 106: goto tr66;
		case 109: goto tr67;
		case 110: goto tr68;
		case 111: goto tr69;
		case 115: goto tr70;
		case 118: goto tr71;
		case 120: goto tr72;
	}
	goto st0;
tr62:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st32;
st32:
	if ( ++p == pe )
		goto _test_eof32;
case 32:
#line 425 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 80: goto st33;
		case 85: goto st76;
		case 112: goto st33;
		case 117: goto st76;
	}
	goto st0;
st33:
	if ( ++p == pe )
		goto _test_eof33;
case 33:
	switch( (*p) ) {
		case 82: goto st34;
		case 114: goto st34;
	}
	goto st0;
st34:
	if ( ++p == pe )
		goto _test_eof34;
case 34:
	switch( (*p) ) {
		case 32: goto tr76;
		case 44: goto tr77;
		case 46: goto tr77;
		case 73: goto st74;
		case 105: goto st74;
	}
	goto st0;
tr338:
#line 25 "ragel/tstr_cparse_datetime.rl"
	{
    mark = mark_day;
  }
#line 30 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_day(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_DAY;
      {p++; cs = 35; goto _out;}
    }
    tstr_parsed_set_day(parsed, v);
  }
	goto st35;
tr76:
#line 22 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_month(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_MONTH;
      {p++; cs = 35; goto _out;}
    }
    tstr_parsed_set_month(parsed, v);
  }
	goto st35;
tr348:
#line 30 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_day(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_DAY;
      {p++; cs = 35; goto _out;}
    }
    tstr_parsed_set_day(parsed, v);
  }
	goto st35;
st35:
	if ( ++p == pe )
		goto _test_eof35;
case 35:
#line 492 "tstr_cparse_datetime.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr79;
	goto st0;
tr79:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st36;
tr294:
#line 22 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_month(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_MONTH;
      {p++; cs = 36; goto _out;}
    }
    tstr_parsed_set_month(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st36;
st36:
	if ( ++p == pe )
		goto _test_eof36;
case 36:
#line 516 "tstr_cparse_datetime.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st37;
	goto st0;
st37:
	if ( ++p == pe )
		goto _test_eof37;
case 37:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st38;
	goto st0;
st38:
	if ( ++p == pe )
		goto _test_eof38;
case 38:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st378;
	goto st0;
st378:
	if ( ++p == pe )
		goto _test_eof378;
case 378:
	switch( (*p) ) {
		case 32: goto tr398;
		case 44: goto tr399;
		case 84: goto tr400;
		case 116: goto tr400;
	}
	goto st0;
tr468:
#line 30 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_day(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_DAY;
      {p++; cs = 39; goto _out;}
    }
    tstr_parsed_set_day(parsed, v);
  }
	goto st39;
tr398:
#line 6 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_year(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_YEAR;
      {p++; cs = 39; goto _out;}
    }
    tstr_parsed_set_year4(parsed, v);
  }
	goto st39;
st39:
	if ( ++p == pe )
		goto _test_eof39;
case 39:
#line 569 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 65: goto st70;
		case 97: goto st70;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr83;
	goto st0;
tr83:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st40;
st40:
	if ( ++p == pe )
		goto _test_eof40;
case 40:
#line 585 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 32: goto tr85;
		case 58: goto tr87;
		case 65: goto tr88;
		case 80: goto tr88;
		case 97: goto tr88;
		case 112: goto tr88;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st62;
	goto st0;
tr85:
#line 46 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_hour(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_HOUR;
      {p++; cs = 41; goto _out;}
    }
    tstr_parsed_set_hour(parsed, v);
  }
	goto st41;
st41:
	if ( ++p == pe )
		goto _test_eof41;
case 41:
#line 611 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 65: goto tr89;
		case 80: goto tr89;
		case 97: goto tr89;
		case 112: goto tr89;
	}
	goto st0;
tr89:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st42;
tr88:
#line 46 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_hour(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_HOUR;
      {p++; cs = 42; goto _out;}
    }
    tstr_parsed_set_hour(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st42;
tr429:
#line 54 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_minute(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_MINUTE;
      {p++; cs = 42; goto _out;}
    }
    tstr_parsed_set_minute(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st42;
tr449:
#line 62 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_second(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_SECOND;
      {p++; cs = 42; goto _out;}
    }
    tstr_parsed_set_second(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st42;
tr459:
#line 70 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_fraction(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_FRACTION;
      {p++; cs = 42; goto _out;}
    }
    tstr_parsed_set_fraction(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st42;
st42:
	if ( ++p == pe )
		goto _test_eof42;
case 42:
#line 675 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 46: goto st43;
		case 77: goto st379;
		case 109: goto st379;
	}
	goto st0;
st43:
	if ( ++p == pe )
		goto _test_eof43;
case 43:
	switch( (*p) ) {
		case 77: goto st44;
		case 109: goto st44;
	}
	goto st0;
st44:
	if ( ++p == pe )
		goto _test_eof44;
case 44:
	if ( (*p) == 46 )
		goto st379;
	goto st0;
st379:
	if ( ++p == pe )
		goto _test_eof379;
case 379:
	switch( (*p) ) {
		case 32: goto tr401;
		case 43: goto tr402;
		case 45: goto tr402;
		case 71: goto tr404;
		case 85: goto tr405;
		case 90: goto tr406;
		case 122: goto tr407;
	}
	if ( 65 <= (*p) && (*p) <= 89 )
		goto tr403;
	goto st0;
tr401:
#line 98 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_meridiem(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_MERIDIEM;
      {p++; cs = 45; goto _out;}
    }
    tstr_parsed_set_meridiem(parsed, v);
  }
	goto st45;
st45:
	if ( ++p == pe )
		goto _test_eof45;
case 45:
#line 728 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 43: goto tr93;
		case 45: goto tr93;
		case 71: goto tr95;
		case 85: goto tr96;
		case 90: goto tr97;
		case 122: goto tr98;
	}
	if ( 65 <= (*p) && (*p) <= 89 )
		goto tr94;
	goto st0;
tr93:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st46;
tr402:
#line 98 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_meridiem(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_MERIDIEM;
      {p++; cs = 46; goto _out;}
    }
    tstr_parsed_set_meridiem(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st46;
tr422:
#line 54 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_minute(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_MINUTE;
      {p++; cs = 46; goto _out;}
    }
    tstr_parsed_set_minute(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st46;
tr442:
#line 62 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_second(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_SECOND;
      {p++; cs = 46; goto _out;}
    }
    tstr_parsed_set_second(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st46;
tr452:
#line 70 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_fraction(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_FRACTION;
      {p++; cs = 46; goto _out;}
    }
    tstr_parsed_set_fraction(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st46;
st46:
	if ( ++p == pe )
		goto _test_eof46;
case 46:
#line 796 "tstr_cparse_datetime.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st47;
	goto st0;
st47:
	if ( ++p == pe )
		goto _test_eof47;
case 47:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st380;
	goto st0;
st380:
	if ( ++p == pe )
		goto _test_eof380;
case 380:
	switch( (*p) ) {
		case 32: goto tr408;
		case 58: goto st54;
		case 91: goto tr410;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st51;
	goto st0;
tr408:
#line 78 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_tz_offset(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_OFFSET;
      {p++; cs = 48; goto _out;}
    }
    tstr_parsed_set_offset(parsed, v);
  }
	goto st48;
tr411:
#line 94 "ragel/tstr_common.rl"
	{
    tstr_parsed_set_tz_annotation(parsed, mark, p - mark);
  }
	goto st48;
tr413:
#line 90 "ragel/tstr_common.rl"
	{
    tstr_parsed_set_tz_abbrev(parsed, mark, p - mark);
  }
	goto st48;
tr418:
#line 86 "ragel/tstr_common.rl"
	{
    tstr_parsed_set_tz_utc(parsed, mark, p - mark);
  }
	goto st48;
tr438:
#line 86 "ragel/tstr_common.rl"
	{
    tstr_parsed_set_tz_utc(parsed, mark, p - mark);
  }
#line 90 "ragel/tstr_common.rl"
	{
    tstr_parsed_set_tz_abbrev(parsed, mark, p - mark);
  }
	goto st48;
st48:
	if ( ++p == pe )
		goto _test_eof48;
case 48:
#line 861 "tstr_cparse_datetime.c"
	if ( (*p) == 40 )
		goto st49;
	goto st0;
st49:
	if ( ++p == pe )
		goto _test_eof49;
case 49:
	if ( 40 <= (*p) && (*p) <= 41 )
		goto st0;
	goto st50;
st50:
	if ( ++p == pe )
		goto _test_eof50;
case 50:
	switch( (*p) ) {
		case 40: goto st0;
		case 41: goto st381;
	}
	goto st50;
st381:
	if ( ++p == pe )
		goto _test_eof381;
case 381:
	goto st0;
st51:
	if ( ++p == pe )
		goto _test_eof51;
case 51:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st382;
	goto st0;
st382:
	if ( ++p == pe )
		goto _test_eof382;
case 382:
	switch( (*p) ) {
		case 32: goto tr408;
		case 91: goto tr410;
	}
	goto st0;
tr410:
#line 78 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_tz_offset(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_OFFSET;
      {p++; cs = 52; goto _out;}
    }
    tstr_parsed_set_offset(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st52;
tr415:
#line 90 "ragel/tstr_common.rl"
	{
    tstr_parsed_set_tz_abbrev(parsed, mark, p - mark);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st52;
tr420:
#line 86 "ragel/tstr_common.rl"
	{
    tstr_parsed_set_tz_utc(parsed, mark, p - mark);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st52;
tr439:
#line 86 "ragel/tstr_common.rl"
	{
    tstr_parsed_set_tz_utc(parsed, mark, p - mark);
  }
#line 90 "ragel/tstr_common.rl"
	{
    tstr_parsed_set_tz_abbrev(parsed, mark, p - mark);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st52;
st52:
	if ( ++p == pe )
		goto _test_eof52;
case 52:
#line 946 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 91: goto st0;
		case 93: goto st0;
	}
	goto st53;
st53:
	if ( ++p == pe )
		goto _test_eof53;
case 53:
	switch( (*p) ) {
		case 91: goto st0;
		case 93: goto st383;
	}
	goto st53;
st383:
	if ( ++p == pe )
		goto _test_eof383;
case 383:
	switch( (*p) ) {
		case 32: goto tr411;
		case 91: goto st52;
	}
	goto st0;
st54:
	if ( ++p == pe )
		goto _test_eof54;
case 54:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st51;
	goto st0;
tr94:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st55;
tr403:
#line 98 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_meridiem(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_MERIDIEM;
      {p++; cs = 55; goto _out;}
    }
    tstr_parsed_set_meridiem(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st55;
tr425:
#line 54 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_minute(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_MINUTE;
      {p++; cs = 55; goto _out;}
    }
    tstr_parsed_set_minute(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st55;
tr445:
#line 62 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_second(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_SECOND;
      {p++; cs = 55; goto _out;}
    }
    tstr_parsed_set_second(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st55;
tr455:
#line 70 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_fraction(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_FRACTION;
      {p++; cs = 55; goto _out;}
    }
    tstr_parsed_set_fraction(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st55;
st55:
	if ( ++p == pe )
		goto _test_eof55;
case 55:
#line 1033 "tstr_cparse_datetime.c"
	if ( (*p) > 90 ) {
		if ( 97 <= (*p) && (*p) <= 122 )
			goto st56;
	} else if ( (*p) >= 65 )
		goto st56;
	goto st0;
st56:
	if ( ++p == pe )
		goto _test_eof56;
case 56:
	if ( 65 <= (*p) && (*p) <= 90 )
		goto st384;
	goto st0;
st384:
	if ( ++p == pe )
		goto _test_eof384;
case 384:
	switch( (*p) ) {
		case 32: goto tr413;
		case 91: goto tr415;
	}
	if ( 65 <= (*p) && (*p) <= 90 )
		goto st385;
	goto st0;
st385:
	if ( ++p == pe )
		goto _test_eof385;
case 385:
	switch( (*p) ) {
		case 32: goto tr413;
		case 91: goto tr415;
	}
	if ( 65 <= (*p) && (*p) <= 90 )
		goto st386;
	goto st0;
st386:
	if ( ++p == pe )
		goto _test_eof386;
case 386:
	switch( (*p) ) {
		case 32: goto tr413;
		case 91: goto tr415;
	}
	if ( 65 <= (*p) && (*p) <= 90 )
		goto st387;
	goto st0;
st387:
	if ( ++p == pe )
		goto _test_eof387;
case 387:
	switch( (*p) ) {
		case 32: goto tr413;
		case 91: goto tr415;
	}
	goto st0;
tr95:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st57;
tr404:
#line 98 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_meridiem(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_MERIDIEM;
      {p++; cs = 57; goto _out;}
    }
    tstr_parsed_set_meridiem(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st57;
tr426:
#line 54 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_minute(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_MINUTE;
      {p++; cs = 57; goto _out;}
    }
    tstr_parsed_set_minute(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st57;
tr446:
#line 62 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_second(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_SECOND;
      {p++; cs = 57; goto _out;}
    }
    tstr_parsed_set_second(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st57;
tr456:
#line 70 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_fraction(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_FRACTION;
      {p++; cs = 57; goto _out;}
    }
    tstr_parsed_set_fraction(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st57;
st57:
	if ( ++p == pe )
		goto _test_eof57;
case 57:
#line 1145 "tstr_cparse_datetime.c"
	if ( (*p) == 77 )
		goto st58;
	if ( (*p) > 90 ) {
		if ( 97 <= (*p) && (*p) <= 122 )
			goto st56;
	} else if ( (*p) >= 65 )
		goto st56;
	goto st0;
st58:
	if ( ++p == pe )
		goto _test_eof58;
case 58:
	if ( (*p) == 84 )
		goto st388;
	if ( 65 <= (*p) && (*p) <= 90 )
		goto st384;
	goto st0;
st388:
	if ( ++p == pe )
		goto _test_eof388;
case 388:
	switch( (*p) ) {
		case 32: goto tr418;
		case 43: goto tr419;
		case 45: goto tr419;
		case 91: goto tr420;
	}
	if ( 65 <= (*p) && (*p) <= 90 )
		goto st385;
	goto st0;
tr419:
#line 86 "ragel/tstr_common.rl"
	{
    tstr_parsed_set_tz_utc(parsed, mark, p - mark);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st59;
st59:
	if ( ++p == pe )
		goto _test_eof59;
case 59:
#line 1188 "tstr_cparse_datetime.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st389;
	goto st0;
st389:
	if ( ++p == pe )
		goto _test_eof389;
case 389:
	switch( (*p) ) {
		case 32: goto tr408;
		case 58: goto st54;
		case 91: goto tr410;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st380;
	goto st0;
tr96:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st60;
tr405:
#line 98 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_meridiem(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_MERIDIEM;
      {p++; cs = 60; goto _out;}
    }
    tstr_parsed_set_meridiem(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st60;
tr427:
#line 54 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_minute(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_MINUTE;
      {p++; cs = 60; goto _out;}
    }
    tstr_parsed_set_minute(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st60;
tr447:
#line 62 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_second(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_SECOND;
      {p++; cs = 60; goto _out;}
    }
    tstr_parsed_set_second(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st60;
tr457:
#line 70 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_fraction(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_FRACTION;
      {p++; cs = 60; goto _out;}
    }
    tstr_parsed_set_fraction(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st60;
st60:
	if ( ++p == pe )
		goto _test_eof60;
case 60:
#line 1260 "tstr_cparse_datetime.c"
	if ( (*p) == 84 )
		goto st61;
	if ( (*p) > 90 ) {
		if ( 97 <= (*p) && (*p) <= 122 )
			goto st56;
	} else if ( (*p) >= 65 )
		goto st56;
	goto st0;
st61:
	if ( ++p == pe )
		goto _test_eof61;
case 61:
	if ( (*p) == 67 )
		goto st388;
	if ( 65 <= (*p) && (*p) <= 90 )
		goto st384;
	goto st0;
tr97:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st390;
tr406:
#line 98 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_meridiem(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_MERIDIEM;
      {p++; cs = 390; goto _out;}
    }
    tstr_parsed_set_meridiem(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st390;
tr428:
#line 54 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_minute(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_MINUTE;
      {p++; cs = 390; goto _out;}
    }
    tstr_parsed_set_minute(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st390;
tr448:
#line 62 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_second(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_SECOND;
      {p++; cs = 390; goto _out;}
    }
    tstr_parsed_set_second(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st390;
tr458:
#line 70 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_fraction(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_FRACTION;
      {p++; cs = 390; goto _out;}
    }
    tstr_parsed_set_fraction(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st390;
st390:
	if ( ++p == pe )
		goto _test_eof390;
case 390:
#line 1334 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 32: goto tr418;
		case 91: goto tr420;
	}
	if ( (*p) > 90 ) {
		if ( 97 <= (*p) && (*p) <= 122 )
			goto st56;
	} else if ( (*p) >= 65 )
		goto st56;
	goto st0;
tr98:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st391;
tr407:
#line 98 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_meridiem(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_MERIDIEM;
      {p++; cs = 391; goto _out;}
    }
    tstr_parsed_set_meridiem(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st391;
tr430:
#line 54 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_minute(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_MINUTE;
      {p++; cs = 391; goto _out;}
    }
    tstr_parsed_set_minute(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st391;
tr450:
#line 62 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_second(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_SECOND;
      {p++; cs = 391; goto _out;}
    }
    tstr_parsed_set_second(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st391;
tr460:
#line 70 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_fraction(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_FRACTION;
      {p++; cs = 391; goto _out;}
    }
    tstr_parsed_set_fraction(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st391;
st391:
	if ( ++p == pe )
		goto _test_eof391;
case 391:
#line 1401 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 32: goto tr418;
		case 91: goto tr420;
	}
	goto st0;
st62:
	if ( ++p == pe )
		goto _test_eof62;
case 62:
	switch( (*p) ) {
		case 32: goto tr85;
		case 58: goto tr87;
		case 65: goto tr88;
		case 80: goto tr88;
		case 97: goto tr88;
		case 112: goto tr88;
	}
	goto st0;
tr87:
#line 46 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_hour(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_HOUR;
      {p++; cs = 63; goto _out;}
    }
    tstr_parsed_set_hour(parsed, v);
  }
	goto st63;
st63:
	if ( ++p == pe )
		goto _test_eof63;
case 63:
#line 1434 "tstr_cparse_datetime.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr114;
	goto st0;
tr114:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st64;
st64:
	if ( ++p == pe )
		goto _test_eof64;
case 64:
#line 1446 "tstr_cparse_datetime.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st392;
	goto st0;
st392:
	if ( ++p == pe )
		goto _test_eof392;
case 392:
	switch( (*p) ) {
		case 32: goto tr421;
		case 43: goto tr422;
		case 45: goto tr422;
		case 58: goto tr423;
		case 65: goto tr424;
		case 71: goto tr426;
		case 80: goto tr424;
		case 85: goto tr427;
		case 90: goto tr428;
		case 97: goto tr429;
		case 112: goto tr429;
		case 122: goto tr430;
	}
	if ( 66 <= (*p) && (*p) <= 89 )
		goto tr425;
	goto st0;
tr421:
#line 54 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_minute(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_MINUTE;
      {p++; cs = 65; goto _out;}
    }
    tstr_parsed_set_minute(parsed, v);
  }
	goto st65;
tr441:
#line 62 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_second(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_SECOND;
      {p++; cs = 65; goto _out;}
    }
    tstr_parsed_set_second(parsed, v);
  }
	goto st65;
tr451:
#line 70 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_fraction(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_FRACTION;
      {p++; cs = 65; goto _out;}
    }
    tstr_parsed_set_fraction(parsed, v);
  }
	goto st65;
st65:
	if ( ++p == pe )
		goto _test_eof65;
case 65:
#line 1505 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 43: goto tr93;
		case 45: goto tr93;
		case 65: goto tr116;
		case 71: goto tr95;
		case 80: goto tr116;
		case 85: goto tr96;
		case 90: goto tr97;
		case 97: goto tr89;
		case 112: goto tr89;
		case 122: goto tr98;
	}
	if ( 66 <= (*p) && (*p) <= 89 )
		goto tr94;
	goto st0;
tr116:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st66;
tr424:
#line 54 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_minute(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_MINUTE;
      {p++; cs = 66; goto _out;}
    }
    tstr_parsed_set_minute(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st66;
tr444:
#line 62 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_second(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_SECOND;
      {p++; cs = 66; goto _out;}
    }
    tstr_parsed_set_second(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st66;
tr454:
#line 70 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_fraction(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_FRACTION;
      {p++; cs = 66; goto _out;}
    }
    tstr_parsed_set_fraction(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st66;
st66:
	if ( ++p == pe )
		goto _test_eof66;
case 66:
#line 1565 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 46: goto st43;
		case 77: goto st393;
		case 109: goto st393;
	}
	if ( (*p) > 90 ) {
		if ( 97 <= (*p) && (*p) <= 122 )
			goto st56;
	} else if ( (*p) >= 65 )
		goto st56;
	goto st0;
st393:
	if ( ++p == pe )
		goto _test_eof393;
case 393:
	switch( (*p) ) {
		case 32: goto tr401;
		case 43: goto tr402;
		case 45: goto tr402;
		case 71: goto tr432;
		case 85: goto tr433;
		case 90: goto tr434;
		case 122: goto tr407;
	}
	if ( 65 <= (*p) && (*p) <= 89 )
		goto tr431;
	goto st0;
tr431:
#line 98 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_meridiem(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_MERIDIEM;
      {p++; cs = 394; goto _out;}
    }
    tstr_parsed_set_meridiem(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st394;
st394:
	if ( ++p == pe )
		goto _test_eof394;
case 394:
#line 1609 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 32: goto tr413;
		case 91: goto tr415;
	}
	if ( (*p) > 90 ) {
		if ( 97 <= (*p) && (*p) <= 122 )
			goto st56;
	} else if ( (*p) >= 65 )
		goto st395;
	goto st0;
st395:
	if ( ++p == pe )
		goto _test_eof395;
case 395:
	switch( (*p) ) {
		case 32: goto tr413;
		case 91: goto tr415;
	}
	if ( 65 <= (*p) && (*p) <= 90 )
		goto st384;
	goto st0;
tr432:
#line 98 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_meridiem(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_MERIDIEM;
      {p++; cs = 396; goto _out;}
    }
    tstr_parsed_set_meridiem(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st396;
st396:
	if ( ++p == pe )
		goto _test_eof396;
case 396:
#line 1647 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 32: goto tr413;
		case 77: goto st397;
		case 91: goto tr415;
	}
	if ( (*p) > 90 ) {
		if ( 97 <= (*p) && (*p) <= 122 )
			goto st56;
	} else if ( (*p) >= 65 )
		goto st395;
	goto st0;
st397:
	if ( ++p == pe )
		goto _test_eof397;
case 397:
	switch( (*p) ) {
		case 32: goto tr413;
		case 84: goto st398;
		case 91: goto tr415;
	}
	if ( 65 <= (*p) && (*p) <= 90 )
		goto st384;
	goto st0;
st398:
	if ( ++p == pe )
		goto _test_eof398;
case 398:
	switch( (*p) ) {
		case 32: goto tr438;
		case 43: goto tr419;
		case 45: goto tr419;
		case 91: goto tr439;
	}
	if ( 65 <= (*p) && (*p) <= 90 )
		goto st385;
	goto st0;
tr433:
#line 98 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_meridiem(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_MERIDIEM;
      {p++; cs = 399; goto _out;}
    }
    tstr_parsed_set_meridiem(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st399;
st399:
	if ( ++p == pe )
		goto _test_eof399;
case 399:
#line 1700 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 32: goto tr413;
		case 84: goto st400;
		case 91: goto tr415;
	}
	if ( (*p) > 90 ) {
		if ( 97 <= (*p) && (*p) <= 122 )
			goto st56;
	} else if ( (*p) >= 65 )
		goto st395;
	goto st0;
st400:
	if ( ++p == pe )
		goto _test_eof400;
case 400:
	switch( (*p) ) {
		case 32: goto tr413;
		case 67: goto st398;
		case 91: goto tr415;
	}
	if ( 65 <= (*p) && (*p) <= 90 )
		goto st384;
	goto st0;
tr434:
#line 98 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_meridiem(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_MERIDIEM;
      {p++; cs = 401; goto _out;}
    }
    tstr_parsed_set_meridiem(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st401;
st401:
	if ( ++p == pe )
		goto _test_eof401;
case 401:
#line 1740 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 32: goto tr438;
		case 91: goto tr439;
	}
	if ( (*p) > 90 ) {
		if ( 97 <= (*p) && (*p) <= 122 )
			goto st56;
	} else if ( (*p) >= 65 )
		goto st395;
	goto st0;
tr423:
#line 54 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_minute(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_MINUTE;
      {p++; cs = 67; goto _out;}
    }
    tstr_parsed_set_minute(parsed, v);
  }
	goto st67;
st67:
	if ( ++p == pe )
		goto _test_eof67;
case 67:
#line 1765 "tstr_cparse_datetime.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr118;
	goto st0;
tr118:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st68;
st68:
	if ( ++p == pe )
		goto _test_eof68;
case 68:
#line 1777 "tstr_cparse_datetime.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st402;
	goto st0;
st402:
	if ( ++p == pe )
		goto _test_eof402;
case 402:
	switch( (*p) ) {
		case 32: goto tr441;
		case 44: goto tr443;
		case 46: goto tr443;
		case 65: goto tr444;
		case 71: goto tr446;
		case 80: goto tr444;
		case 85: goto tr447;
		case 90: goto tr448;
		case 97: goto tr449;
		case 112: goto tr449;
		case 122: goto tr450;
	}
	if ( (*p) > 45 ) {
		if ( 66 <= (*p) && (*p) <= 89 )
			goto tr445;
	} else if ( (*p) >= 43 )
		goto tr442;
	goto st0;
tr443:
#line 62 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_second(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_SECOND;
      {p++; cs = 69; goto _out;}
    }
    tstr_parsed_set_second(parsed, v);
  }
	goto st69;
st69:
	if ( ++p == pe )
		goto _test_eof69;
case 69:
#line 1818 "tstr_cparse_datetime.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr120;
	goto st0;
tr120:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st403;
st403:
	if ( ++p == pe )
		goto _test_eof403;
case 403:
#line 1830 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 32: goto tr451;
		case 43: goto tr452;
		case 45: goto tr452;
		case 65: goto tr454;
		case 71: goto tr456;
		case 80: goto tr454;
		case 85: goto tr457;
		case 90: goto tr458;
		case 97: goto tr459;
		case 112: goto tr459;
		case 122: goto tr460;
	}
	if ( (*p) > 57 ) {
		if ( 66 <= (*p) && (*p) <= 89 )
			goto tr455;
	} else if ( (*p) >= 48 )
		goto st404;
	goto st0;
st404:
	if ( ++p == pe )
		goto _test_eof404;
case 404:
	switch( (*p) ) {
		case 32: goto tr451;
		case 43: goto tr452;
		case 45: goto tr452;
		case 65: goto tr454;
		case 71: goto tr456;
		case 80: goto tr454;
		case 85: goto tr457;
		case 90: goto tr458;
		case 97: goto tr459;
		case 112: goto tr459;
		case 122: goto tr460;
	}
	if ( (*p) > 57 ) {
		if ( 66 <= (*p) && (*p) <= 89 )
			goto tr455;
	} else if ( (*p) >= 48 )
		goto st405;
	goto st0;
st405:
	if ( ++p == pe )
		goto _test_eof405;
case 405:
	switch( (*p) ) {
		case 32: goto tr451;
		case 43: goto tr452;
		case 45: goto tr452;
		case 65: goto tr454;
		case 71: goto tr456;
		case 80: goto tr454;
		case 85: goto tr457;
		case 90: goto tr458;
		case 97: goto tr459;
		case 112: goto tr459;
		case 122: goto tr460;
	}
	if ( (*p) > 57 ) {
		if ( 66 <= (*p) && (*p) <= 89 )
			goto tr455;
	} else if ( (*p) >= 48 )
		goto st406;
	goto st0;
st406:
	if ( ++p == pe )
		goto _test_eof406;
case 406:
	switch( (*p) ) {
		case 32: goto tr451;
		case 43: goto tr452;
		case 45: goto tr452;
		case 65: goto tr454;
		case 71: goto tr456;
		case 80: goto tr454;
		case 85: goto tr457;
		case 90: goto tr458;
		case 97: goto tr459;
		case 112: goto tr459;
		case 122: goto tr460;
	}
	if ( (*p) > 57 ) {
		if ( 66 <= (*p) && (*p) <= 89 )
			goto tr455;
	} else if ( (*p) >= 48 )
		goto st407;
	goto st0;
st407:
	if ( ++p == pe )
		goto _test_eof407;
case 407:
	switch( (*p) ) {
		case 32: goto tr451;
		case 43: goto tr452;
		case 45: goto tr452;
		case 65: goto tr454;
		case 71: goto tr456;
		case 80: goto tr454;
		case 85: goto tr457;
		case 90: goto tr458;
		case 97: goto tr459;
		case 112: goto tr459;
		case 122: goto tr460;
	}
	if ( (*p) > 57 ) {
		if ( 66 <= (*p) && (*p) <= 89 )
			goto tr455;
	} else if ( (*p) >= 48 )
		goto st408;
	goto st0;
st408:
	if ( ++p == pe )
		goto _test_eof408;
case 408:
	switch( (*p) ) {
		case 32: goto tr451;
		case 43: goto tr452;
		case 45: goto tr452;
		case 65: goto tr454;
		case 71: goto tr456;
		case 80: goto tr454;
		case 85: goto tr457;
		case 90: goto tr458;
		case 97: goto tr459;
		case 112: goto tr459;
		case 122: goto tr460;
	}
	if ( (*p) > 57 ) {
		if ( 66 <= (*p) && (*p) <= 89 )
			goto tr455;
	} else if ( (*p) >= 48 )
		goto st409;
	goto st0;
st409:
	if ( ++p == pe )
		goto _test_eof409;
case 409:
	switch( (*p) ) {
		case 32: goto tr451;
		case 43: goto tr452;
		case 45: goto tr452;
		case 65: goto tr454;
		case 71: goto tr456;
		case 80: goto tr454;
		case 85: goto tr457;
		case 90: goto tr458;
		case 97: goto tr459;
		case 112: goto tr459;
		case 122: goto tr460;
	}
	if ( (*p) > 57 ) {
		if ( 66 <= (*p) && (*p) <= 89 )
			goto tr455;
	} else if ( (*p) >= 48 )
		goto st410;
	goto st0;
st410:
	if ( ++p == pe )
		goto _test_eof410;
case 410:
	switch( (*p) ) {
		case 32: goto tr451;
		case 43: goto tr452;
		case 45: goto tr452;
		case 65: goto tr454;
		case 71: goto tr456;
		case 80: goto tr454;
		case 85: goto tr457;
		case 90: goto tr458;
		case 97: goto tr459;
		case 112: goto tr459;
		case 122: goto tr460;
	}
	if ( (*p) > 57 ) {
		if ( 66 <= (*p) && (*p) <= 89 )
			goto tr455;
	} else if ( (*p) >= 48 )
		goto st411;
	goto st0;
st411:
	if ( ++p == pe )
		goto _test_eof411;
case 411:
	switch( (*p) ) {
		case 32: goto tr451;
		case 43: goto tr452;
		case 45: goto tr452;
		case 65: goto tr454;
		case 71: goto tr456;
		case 80: goto tr454;
		case 85: goto tr457;
		case 90: goto tr458;
		case 97: goto tr459;
		case 112: goto tr459;
		case 122: goto tr460;
	}
	if ( 66 <= (*p) && (*p) <= 89 )
		goto tr455;
	goto st0;
st70:
	if ( ++p == pe )
		goto _test_eof70;
case 70:
	switch( (*p) ) {
		case 84: goto st71;
		case 116: goto st71;
	}
	goto st0;
tr469:
#line 30 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_day(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_DAY;
      {p++; cs = 71; goto _out;}
    }
    tstr_parsed_set_day(parsed, v);
  }
	goto st71;
tr399:
#line 6 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_year(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_YEAR;
      {p++; cs = 71; goto _out;}
    }
    tstr_parsed_set_year4(parsed, v);
  }
	goto st71;
st71:
	if ( ++p == pe )
		goto _test_eof71;
case 71:
#line 2064 "tstr_cparse_datetime.c"
	if ( (*p) == 32 )
		goto st72;
	goto st0;
tr471:
#line 30 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_day(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_DAY;
      {p++; cs = 72; goto _out;}
    }
    tstr_parsed_set_day(parsed, v);
  }
	goto st72;
tr400:
#line 6 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_year(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_YEAR;
      {p++; cs = 72; goto _out;}
    }
    tstr_parsed_set_year4(parsed, v);
  }
	goto st72;
st72:
	if ( ++p == pe )
		goto _test_eof72;
case 72:
#line 2092 "tstr_cparse_datetime.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr83;
	goto st0;
tr339:
#line 25 "ragel/tstr_cparse_datetime.rl"
	{
    mark = mark_day;
  }
#line 30 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_day(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_DAY;
      {p++; cs = 73; goto _out;}
    }
    tstr_parsed_set_day(parsed, v);
  }
	goto st73;
tr77:
#line 22 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_month(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_MONTH;
      {p++; cs = 73; goto _out;}
    }
    tstr_parsed_set_month(parsed, v);
  }
	goto st73;
st73:
	if ( ++p == pe )
		goto _test_eof73;
case 73:
#line 2124 "tstr_cparse_datetime.c"
	if ( (*p) == 32 )
		goto st35;
	goto st0;
st74:
	if ( ++p == pe )
		goto _test_eof74;
case 74:
	switch( (*p) ) {
		case 76: goto st75;
		case 108: goto st75;
	}
	goto st0;
st75:
	if ( ++p == pe )
		goto _test_eof75;
case 75:
	switch( (*p) ) {
		case 32: goto tr76;
		case 44: goto tr77;
		case 46: goto tr77;
	}
	goto st0;
st76:
	if ( ++p == pe )
		goto _test_eof76;
case 76:
	switch( (*p) ) {
		case 71: goto st77;
		case 103: goto st77;
	}
	goto st0;
st77:
	if ( ++p == pe )
		goto _test_eof77;
case 77:
	switch( (*p) ) {
		case 32: goto tr76;
		case 44: goto tr77;
		case 46: goto tr77;
		case 85: goto st78;
		case 117: goto st78;
	}
	goto st0;
st78:
	if ( ++p == pe )
		goto _test_eof78;
case 78:
	switch( (*p) ) {
		case 83: goto st79;
		case 115: goto st79;
	}
	goto st0;
st79:
	if ( ++p == pe )
		goto _test_eof79;
case 79:
	switch( (*p) ) {
		case 84: goto st75;
		case 116: goto st75;
	}
	goto st0;
tr63:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st80;
st80:
	if ( ++p == pe )
		goto _test_eof80;
case 80:
#line 2194 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 69: goto st81;
		case 101: goto st81;
	}
	goto st0;
st81:
	if ( ++p == pe )
		goto _test_eof81;
case 81:
	switch( (*p) ) {
		case 67: goto st82;
		case 99: goto st82;
	}
	goto st0;
st82:
	if ( ++p == pe )
		goto _test_eof82;
case 82:
	switch( (*p) ) {
		case 32: goto tr76;
		case 44: goto tr77;
		case 46: goto tr77;
		case 69: goto st83;
		case 101: goto st83;
	}
	goto st0;
st83:
	if ( ++p == pe )
		goto _test_eof83;
case 83:
	switch( (*p) ) {
		case 77: goto st84;
		case 109: goto st84;
	}
	goto st0;
st84:
	if ( ++p == pe )
		goto _test_eof84;
case 84:
	switch( (*p) ) {
		case 66: goto st85;
		case 98: goto st85;
	}
	goto st0;
st85:
	if ( ++p == pe )
		goto _test_eof85;
case 85:
	switch( (*p) ) {
		case 69: goto st86;
		case 101: goto st86;
	}
	goto st0;
st86:
	if ( ++p == pe )
		goto _test_eof86;
case 86:
	switch( (*p) ) {
		case 82: goto st75;
		case 114: goto st75;
	}
	goto st0;
tr64:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st87;
st87:
	if ( ++p == pe )
		goto _test_eof87;
case 87:
#line 2265 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 69: goto st88;
		case 101: goto st88;
	}
	goto st0;
st88:
	if ( ++p == pe )
		goto _test_eof88;
case 88:
	switch( (*p) ) {
		case 66: goto st89;
		case 98: goto st89;
	}
	goto st0;
st89:
	if ( ++p == pe )
		goto _test_eof89;
case 89:
	switch( (*p) ) {
		case 32: goto tr76;
		case 44: goto tr77;
		case 46: goto tr77;
		case 82: goto st90;
		case 114: goto st90;
	}
	goto st0;
st90:
	if ( ++p == pe )
		goto _test_eof90;
case 90:
	switch( (*p) ) {
		case 85: goto st91;
		case 117: goto st91;
	}
	goto st0;
st91:
	if ( ++p == pe )
		goto _test_eof91;
case 91:
	switch( (*p) ) {
		case 65: goto st92;
		case 97: goto st92;
	}
	goto st0;
st92:
	if ( ++p == pe )
		goto _test_eof92;
case 92:
	switch( (*p) ) {
		case 82: goto st93;
		case 114: goto st93;
	}
	goto st0;
st93:
	if ( ++p == pe )
		goto _test_eof93;
case 93:
	switch( (*p) ) {
		case 89: goto st75;
		case 121: goto st75;
	}
	goto st0;
tr65:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st94;
st94:
	if ( ++p == pe )
		goto _test_eof94;
case 94:
#line 2336 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 32: goto tr76;
		case 44: goto tr77;
		case 46: goto tr77;
		case 73: goto st95;
		case 86: goto st75;
		case 88: goto st75;
		case 105: goto st95;
		case 118: goto st75;
		case 120: goto st75;
	}
	goto st0;
st95:
	if ( ++p == pe )
		goto _test_eof95;
case 95:
	switch( (*p) ) {
		case 32: goto tr76;
		case 44: goto tr77;
		case 46: goto tr77;
		case 73: goto st75;
		case 105: goto st75;
	}
	goto st0;
tr66:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st96;
st96:
	if ( ++p == pe )
		goto _test_eof96;
case 96:
#line 2369 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 65: goto st97;
		case 85: goto st99;
		case 97: goto st97;
		case 117: goto st99;
	}
	goto st0;
st97:
	if ( ++p == pe )
		goto _test_eof97;
case 97:
	switch( (*p) ) {
		case 78: goto st98;
		case 110: goto st98;
	}
	goto st0;
st98:
	if ( ++p == pe )
		goto _test_eof98;
case 98:
	switch( (*p) ) {
		case 32: goto tr76;
		case 44: goto tr77;
		case 46: goto tr77;
		case 85: goto st91;
		case 117: goto st91;
	}
	goto st0;
st99:
	if ( ++p == pe )
		goto _test_eof99;
case 99:
	switch( (*p) ) {
		case 76: goto st100;
		case 78: goto st101;
		case 108: goto st100;
		case 110: goto st101;
	}
	goto st0;
st100:
	if ( ++p == pe )
		goto _test_eof100;
case 100:
	switch( (*p) ) {
		case 32: goto tr76;
		case 44: goto tr77;
		case 46: goto tr77;
		case 89: goto st75;
		case 121: goto st75;
	}
	goto st0;
st101:
	if ( ++p == pe )
		goto _test_eof101;
case 101:
	switch( (*p) ) {
		case 32: goto tr76;
		case 44: goto tr77;
		case 46: goto tr77;
		case 69: goto st75;
		case 101: goto st75;
	}
	goto st0;
tr67:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st102;
st102:
	if ( ++p == pe )
		goto _test_eof102;
case 102:
#line 2441 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 65: goto st103;
		case 97: goto st103;
	}
	goto st0;
st103:
	if ( ++p == pe )
		goto _test_eof103;
case 103:
	switch( (*p) ) {
		case 82: goto st104;
		case 89: goto st75;
		case 114: goto st104;
		case 121: goto st75;
	}
	goto st0;
st104:
	if ( ++p == pe )
		goto _test_eof104;
case 104:
	switch( (*p) ) {
		case 32: goto tr76;
		case 44: goto tr77;
		case 46: goto tr77;
		case 67: goto st105;
		case 99: goto st105;
	}
	goto st0;
st105:
	if ( ++p == pe )
		goto _test_eof105;
case 105:
	switch( (*p) ) {
		case 72: goto st75;
		case 104: goto st75;
	}
	goto st0;
tr68:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st106;
st106:
	if ( ++p == pe )
		goto _test_eof106;
case 106:
#line 2487 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 79: goto st107;
		case 111: goto st107;
	}
	goto st0;
st107:
	if ( ++p == pe )
		goto _test_eof107;
case 107:
	switch( (*p) ) {
		case 86: goto st82;
		case 118: goto st82;
	}
	goto st0;
tr69:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st108;
st108:
	if ( ++p == pe )
		goto _test_eof108;
case 108:
#line 2510 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 67: goto st109;
		case 99: goto st109;
	}
	goto st0;
st109:
	if ( ++p == pe )
		goto _test_eof109;
case 109:
	switch( (*p) ) {
		case 84: goto st110;
		case 116: goto st110;
	}
	goto st0;
st110:
	if ( ++p == pe )
		goto _test_eof110;
case 110:
	switch( (*p) ) {
		case 32: goto tr76;
		case 44: goto tr77;
		case 46: goto tr77;
		case 79: goto st84;
		case 111: goto st84;
	}
	goto st0;
tr70:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st111;
st111:
	if ( ++p == pe )
		goto _test_eof111;
case 111:
#line 2545 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 69: goto st112;
		case 101: goto st112;
	}
	goto st0;
st112:
	if ( ++p == pe )
		goto _test_eof112;
case 112:
	switch( (*p) ) {
		case 80: goto st113;
		case 112: goto st113;
	}
	goto st0;
st113:
	if ( ++p == pe )
		goto _test_eof113;
case 113:
	switch( (*p) ) {
		case 32: goto tr76;
		case 44: goto tr77;
		case 46: goto tr77;
		case 84: goto st82;
		case 116: goto st82;
	}
	goto st0;
tr71:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st114;
st114:
	if ( ++p == pe )
		goto _test_eof114;
case 114:
#line 2580 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 32: goto tr76;
		case 44: goto tr77;
		case 46: goto tr77;
		case 73: goto st115;
		case 105: goto st115;
	}
	goto st0;
tr72:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st115;
st115:
	if ( ++p == pe )
		goto _test_eof115;
case 115:
#line 2597 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 32: goto tr76;
		case 44: goto tr77;
		case 46: goto tr77;
		case 73: goto st95;
		case 105: goto st95;
	}
	goto st0;
tr46:
#line 30 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_day(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_DAY;
      {p++; cs = 116; goto _out;}
    }
    tstr_parsed_set_day(parsed, v);
  }
#line 13 "ragel/tstr_cparse_datetime.rl"
	{
    sep_char = (*p);
  }
	goto st116;
st116:
	if ( ++p == pe )
		goto _test_eof116;
case 116:
#line 2624 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 65: goto tr155;
		case 68: goto tr156;
		case 70: goto tr157;
		case 73: goto tr158;
		case 74: goto tr159;
		case 77: goto tr160;
		case 78: goto tr161;
		case 79: goto tr162;
		case 83: goto tr163;
		case 86: goto tr164;
		case 88: goto tr165;
		case 97: goto tr155;
		case 100: goto tr156;
		case 102: goto tr157;
		case 105: goto tr158;
		case 106: goto tr159;
		case 109: goto tr160;
		case 110: goto tr161;
		case 111: goto tr162;
		case 115: goto tr163;
		case 118: goto tr164;
		case 120: goto tr165;
	}
	goto st0;
tr155:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st117;
st117:
	if ( ++p == pe )
		goto _test_eof117;
case 117:
#line 2658 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 80: goto st118;
		case 85: goto st122;
		case 112: goto st118;
		case 117: goto st122;
	}
	goto st0;
st118:
	if ( ++p == pe )
		goto _test_eof118;
case 118:
	switch( (*p) ) {
		case 82: goto st119;
		case 114: goto st119;
	}
	goto st0;
st119:
	if ( ++p == pe )
		goto _test_eof119;
case 119:
	_widec = (*p);
	if ( (*p) < 46 ) {
		if ( 45 <= (*p) && (*p) <= 45 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else if ( (*p) > 46 ) {
		if ( 47 <= (*p) && (*p) <= 47 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else {
		_widec = (short)(128 + ((*p) - -128));
		if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
	}
	switch( _widec ) {
		case 73: goto st120;
		case 105: goto st120;
	}
	if ( 557 <= _widec && _widec <= 559 )
		goto tr76;
	goto st0;
st120:
	if ( ++p == pe )
		goto _test_eof120;
case 120:
	switch( (*p) ) {
		case 76: goto st121;
		case 108: goto st121;
	}
	goto st0;
st121:
	if ( ++p == pe )
		goto _test_eof121;
case 121:
	_widec = (*p);
	if ( (*p) < 46 ) {
		if ( 45 <= (*p) && (*p) <= 45 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else if ( (*p) > 46 ) {
		if ( 47 <= (*p) && (*p) <= 47 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else {
		_widec = (short)(128 + ((*p) - -128));
		if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
	}
	if ( 557 <= _widec && _widec <= 559 )
		goto tr76;
	goto st0;
st122:
	if ( ++p == pe )
		goto _test_eof122;
case 122:
	switch( (*p) ) {
		case 71: goto st123;
		case 103: goto st123;
	}
	goto st0;
st123:
	if ( ++p == pe )
		goto _test_eof123;
case 123:
	_widec = (*p);
	if ( (*p) < 46 ) {
		if ( 45 <= (*p) && (*p) <= 45 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else if ( (*p) > 46 ) {
		if ( 47 <= (*p) && (*p) <= 47 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else {
		_widec = (short)(128 + ((*p) - -128));
		if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
	}
	switch( _widec ) {
		case 85: goto st124;
		case 117: goto st124;
	}
	if ( 557 <= _widec && _widec <= 559 )
		goto tr76;
	goto st0;
st124:
	if ( ++p == pe )
		goto _test_eof124;
case 124:
	switch( (*p) ) {
		case 83: goto st125;
		case 115: goto st125;
	}
	goto st0;
st125:
	if ( ++p == pe )
		goto _test_eof125;
case 125:
	switch( (*p) ) {
		case 84: goto st121;
		case 116: goto st121;
	}
	goto st0;
tr156:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st126;
st126:
	if ( ++p == pe )
		goto _test_eof126;
case 126:
#line 2829 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 69: goto st127;
		case 101: goto st127;
	}
	goto st0;
st127:
	if ( ++p == pe )
		goto _test_eof127;
case 127:
	switch( (*p) ) {
		case 67: goto st128;
		case 99: goto st128;
	}
	goto st0;
st128:
	if ( ++p == pe )
		goto _test_eof128;
case 128:
	_widec = (*p);
	if ( (*p) < 46 ) {
		if ( 45 <= (*p) && (*p) <= 45 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else if ( (*p) > 46 ) {
		if ( 47 <= (*p) && (*p) <= 47 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else {
		_widec = (short)(128 + ((*p) - -128));
		if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
	}
	switch( _widec ) {
		case 69: goto st129;
		case 101: goto st129;
	}
	if ( 557 <= _widec && _widec <= 559 )
		goto tr76;
	goto st0;
st129:
	if ( ++p == pe )
		goto _test_eof129;
case 129:
	switch( (*p) ) {
		case 77: goto st130;
		case 109: goto st130;
	}
	goto st0;
st130:
	if ( ++p == pe )
		goto _test_eof130;
case 130:
	switch( (*p) ) {
		case 66: goto st131;
		case 98: goto st131;
	}
	goto st0;
st131:
	if ( ++p == pe )
		goto _test_eof131;
case 131:
	switch( (*p) ) {
		case 69: goto st132;
		case 101: goto st132;
	}
	goto st0;
st132:
	if ( ++p == pe )
		goto _test_eof132;
case 132:
	switch( (*p) ) {
		case 82: goto st121;
		case 114: goto st121;
	}
	goto st0;
tr157:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st133;
st133:
	if ( ++p == pe )
		goto _test_eof133;
case 133:
#line 2926 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 69: goto st134;
		case 101: goto st134;
	}
	goto st0;
st134:
	if ( ++p == pe )
		goto _test_eof134;
case 134:
	switch( (*p) ) {
		case 66: goto st135;
		case 98: goto st135;
	}
	goto st0;
st135:
	if ( ++p == pe )
		goto _test_eof135;
case 135:
	_widec = (*p);
	if ( (*p) < 46 ) {
		if ( 45 <= (*p) && (*p) <= 45 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else if ( (*p) > 46 ) {
		if ( 47 <= (*p) && (*p) <= 47 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else {
		_widec = (short)(128 + ((*p) - -128));
		if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
	}
	switch( _widec ) {
		case 82: goto st136;
		case 114: goto st136;
	}
	if ( 557 <= _widec && _widec <= 559 )
		goto tr76;
	goto st0;
st136:
	if ( ++p == pe )
		goto _test_eof136;
case 136:
	switch( (*p) ) {
		case 85: goto st137;
		case 117: goto st137;
	}
	goto st0;
st137:
	if ( ++p == pe )
		goto _test_eof137;
case 137:
	switch( (*p) ) {
		case 65: goto st138;
		case 97: goto st138;
	}
	goto st0;
st138:
	if ( ++p == pe )
		goto _test_eof138;
case 138:
	switch( (*p) ) {
		case 82: goto st139;
		case 114: goto st139;
	}
	goto st0;
st139:
	if ( ++p == pe )
		goto _test_eof139;
case 139:
	switch( (*p) ) {
		case 89: goto st121;
		case 121: goto st121;
	}
	goto st0;
tr158:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st140;
st140:
	if ( ++p == pe )
		goto _test_eof140;
case 140:
#line 3023 "tstr_cparse_datetime.c"
	_widec = (*p);
	if ( (*p) < 46 ) {
		if ( 45 <= (*p) && (*p) <= 45 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else if ( (*p) > 46 ) {
		if ( 47 <= (*p) && (*p) <= 47 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else {
		_widec = (short)(128 + ((*p) - -128));
		if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
	}
	switch( _widec ) {
		case 73: goto st141;
		case 86: goto st121;
		case 88: goto st121;
		case 105: goto st141;
		case 118: goto st121;
		case 120: goto st121;
	}
	if ( 557 <= _widec && _widec <= 559 )
		goto tr76;
	goto st0;
st141:
	if ( ++p == pe )
		goto _test_eof141;
case 141:
	_widec = (*p);
	if ( (*p) < 46 ) {
		if ( 45 <= (*p) && (*p) <= 45 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else if ( (*p) > 46 ) {
		if ( 47 <= (*p) && (*p) <= 47 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else {
		_widec = (short)(128 + ((*p) - -128));
		if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
	}
	switch( _widec ) {
		case 73: goto st121;
		case 105: goto st121;
	}
	if ( 557 <= _widec && _widec <= 559 )
		goto tr76;
	goto st0;
tr159:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st142;
st142:
	if ( ++p == pe )
		goto _test_eof142;
case 142:
#line 3108 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 65: goto st143;
		case 85: goto st145;
		case 97: goto st143;
		case 117: goto st145;
	}
	goto st0;
st143:
	if ( ++p == pe )
		goto _test_eof143;
case 143:
	switch( (*p) ) {
		case 78: goto st144;
		case 110: goto st144;
	}
	goto st0;
st144:
	if ( ++p == pe )
		goto _test_eof144;
case 144:
	_widec = (*p);
	if ( (*p) < 46 ) {
		if ( 45 <= (*p) && (*p) <= 45 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else if ( (*p) > 46 ) {
		if ( 47 <= (*p) && (*p) <= 47 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else {
		_widec = (short)(128 + ((*p) - -128));
		if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
	}
	switch( _widec ) {
		case 85: goto st137;
		case 117: goto st137;
	}
	if ( 557 <= _widec && _widec <= 559 )
		goto tr76;
	goto st0;
st145:
	if ( ++p == pe )
		goto _test_eof145;
case 145:
	switch( (*p) ) {
		case 76: goto st146;
		case 78: goto st147;
		case 108: goto st146;
		case 110: goto st147;
	}
	goto st0;
st146:
	if ( ++p == pe )
		goto _test_eof146;
case 146:
	_widec = (*p);
	if ( (*p) < 46 ) {
		if ( 45 <= (*p) && (*p) <= 45 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else if ( (*p) > 46 ) {
		if ( 47 <= (*p) && (*p) <= 47 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else {
		_widec = (short)(128 + ((*p) - -128));
		if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
	}
	switch( _widec ) {
		case 89: goto st121;
		case 121: goto st121;
	}
	if ( 557 <= _widec && _widec <= 559 )
		goto tr76;
	goto st0;
st147:
	if ( ++p == pe )
		goto _test_eof147;
case 147:
	_widec = (*p);
	if ( (*p) < 46 ) {
		if ( 45 <= (*p) && (*p) <= 45 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else if ( (*p) > 46 ) {
		if ( 47 <= (*p) && (*p) <= 47 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else {
		_widec = (short)(128 + ((*p) - -128));
		if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
	}
	switch( _widec ) {
		case 69: goto st121;
		case 101: goto st121;
	}
	if ( 557 <= _widec && _widec <= 559 )
		goto tr76;
	goto st0;
tr160:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st148;
st148:
	if ( ++p == pe )
		goto _test_eof148;
case 148:
#line 3258 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 65: goto st149;
		case 97: goto st149;
	}
	goto st0;
st149:
	if ( ++p == pe )
		goto _test_eof149;
case 149:
	switch( (*p) ) {
		case 82: goto st150;
		case 89: goto st121;
		case 114: goto st150;
		case 121: goto st121;
	}
	goto st0;
st150:
	if ( ++p == pe )
		goto _test_eof150;
case 150:
	_widec = (*p);
	if ( (*p) < 46 ) {
		if ( 45 <= (*p) && (*p) <= 45 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else if ( (*p) > 46 ) {
		if ( 47 <= (*p) && (*p) <= 47 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else {
		_widec = (short)(128 + ((*p) - -128));
		if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
	}
	switch( _widec ) {
		case 67: goto st151;
		case 99: goto st151;
	}
	if ( 557 <= _widec && _widec <= 559 )
		goto tr76;
	goto st0;
st151:
	if ( ++p == pe )
		goto _test_eof151;
case 151:
	switch( (*p) ) {
		case 72: goto st121;
		case 104: goto st121;
	}
	goto st0;
tr161:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st152;
st152:
	if ( ++p == pe )
		goto _test_eof152;
case 152:
#line 3330 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 79: goto st153;
		case 111: goto st153;
	}
	goto st0;
st153:
	if ( ++p == pe )
		goto _test_eof153;
case 153:
	switch( (*p) ) {
		case 86: goto st128;
		case 118: goto st128;
	}
	goto st0;
tr162:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st154;
st154:
	if ( ++p == pe )
		goto _test_eof154;
case 154:
#line 3353 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 67: goto st155;
		case 99: goto st155;
	}
	goto st0;
st155:
	if ( ++p == pe )
		goto _test_eof155;
case 155:
	switch( (*p) ) {
		case 84: goto st156;
		case 116: goto st156;
	}
	goto st0;
st156:
	if ( ++p == pe )
		goto _test_eof156;
case 156:
	_widec = (*p);
	if ( (*p) < 46 ) {
		if ( 45 <= (*p) && (*p) <= 45 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else if ( (*p) > 46 ) {
		if ( 47 <= (*p) && (*p) <= 47 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else {
		_widec = (short)(128 + ((*p) - -128));
		if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
	}
	switch( _widec ) {
		case 79: goto st130;
		case 111: goto st130;
	}
	if ( 557 <= _widec && _widec <= 559 )
		goto tr76;
	goto st0;
tr163:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st157;
st157:
	if ( ++p == pe )
		goto _test_eof157;
case 157:
#line 3414 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 69: goto st158;
		case 101: goto st158;
	}
	goto st0;
st158:
	if ( ++p == pe )
		goto _test_eof158;
case 158:
	switch( (*p) ) {
		case 80: goto st159;
		case 112: goto st159;
	}
	goto st0;
st159:
	if ( ++p == pe )
		goto _test_eof159;
case 159:
	_widec = (*p);
	if ( (*p) < 46 ) {
		if ( 45 <= (*p) && (*p) <= 45 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else if ( (*p) > 46 ) {
		if ( 47 <= (*p) && (*p) <= 47 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else {
		_widec = (short)(128 + ((*p) - -128));
		if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
	}
	switch( _widec ) {
		case 84: goto st128;
		case 116: goto st128;
	}
	if ( 557 <= _widec && _widec <= 559 )
		goto tr76;
	goto st0;
tr164:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st160;
st160:
	if ( ++p == pe )
		goto _test_eof160;
case 160:
#line 3475 "tstr_cparse_datetime.c"
	_widec = (*p);
	if ( (*p) < 46 ) {
		if ( 45 <= (*p) && (*p) <= 45 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else if ( (*p) > 46 ) {
		if ( 47 <= (*p) && (*p) <= 47 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else {
		_widec = (short)(128 + ((*p) - -128));
		if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
	}
	switch( _widec ) {
		case 73: goto st161;
		case 105: goto st161;
	}
	if ( 557 <= _widec && _widec <= 559 )
		goto tr76;
	goto st0;
tr165:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st161;
st161:
	if ( ++p == pe )
		goto _test_eof161;
case 161:
#line 3518 "tstr_cparse_datetime.c"
	_widec = (*p);
	if ( (*p) < 46 ) {
		if ( 45 <= (*p) && (*p) <= 45 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else if ( (*p) > 46 ) {
		if ( 47 <= (*p) && (*p) <= 47 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else {
		_widec = (short)(128 + ((*p) - -128));
		if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
	}
	switch( _widec ) {
		case 73: goto st141;
		case 105: goto st141;
	}
	if ( 557 <= _widec && _widec <= 559 )
		goto tr76;
	goto st0;
tr47:
#line 30 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_day(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_DAY;
      {p++; cs = 162; goto _out;}
    }
    tstr_parsed_set_day(parsed, v);
  }
#line 13 "ragel/tstr_cparse_datetime.rl"
	{
    sep_char = (*p);
  }
#line 25 "ragel/tstr_cparse_datetime.rl"
	{
    mark = mark_day;
  }
	goto st162;
st162:
	if ( ++p == pe )
		goto _test_eof162;
case 162:
#line 3575 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 32: goto st31;
		case 65: goto tr155;
		case 68: goto tr156;
		case 70: goto tr157;
		case 73: goto tr158;
		case 74: goto tr159;
		case 77: goto tr160;
		case 78: goto tr161;
		case 79: goto tr162;
		case 83: goto tr163;
		case 86: goto tr164;
		case 88: goto tr165;
		case 97: goto tr155;
		case 100: goto tr156;
		case 102: goto tr157;
		case 105: goto tr158;
		case 106: goto tr159;
		case 109: goto tr160;
		case 110: goto tr161;
		case 111: goto tr162;
		case 115: goto tr163;
		case 118: goto tr164;
		case 120: goto tr165;
	}
	goto st0;
st163:
	if ( ++p == pe )
		goto _test_eof163;
case 163:
	switch( (*p) ) {
		case 32: goto tr45;
		case 46: goto tr47;
		case 65: goto tr49;
		case 68: goto tr50;
		case 70: goto tr51;
		case 73: goto tr52;
		case 74: goto tr53;
		case 77: goto tr54;
		case 78: goto tr55;
		case 79: goto tr56;
		case 82: goto st293;
		case 83: goto tr58;
		case 84: goto st297;
		case 86: goto tr60;
		case 88: goto tr61;
		case 97: goto tr49;
		case 100: goto tr50;
		case 102: goto tr51;
		case 105: goto tr52;
		case 106: goto tr53;
		case 109: goto tr54;
		case 110: goto tr55;
		case 111: goto tr56;
		case 114: goto st293;
		case 115: goto tr58;
		case 116: goto st297;
		case 118: goto tr60;
		case 120: goto tr61;
	}
	if ( (*p) > 47 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st164;
	} else if ( (*p) >= 45 )
		goto tr46;
	goto st0;
st164:
	if ( ++p == pe )
		goto _test_eof164;
case 164:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st165;
	goto st0;
st165:
	if ( ++p == pe )
		goto _test_eof165;
case 165:
	switch( (*p) ) {
		case 65: goto tr205;
		case 68: goto tr206;
		case 70: goto tr207;
		case 74: goto tr208;
		case 77: goto tr209;
		case 78: goto tr210;
		case 79: goto tr211;
		case 83: goto tr212;
		case 97: goto tr205;
		case 100: goto tr206;
		case 102: goto tr207;
		case 106: goto tr208;
		case 109: goto tr209;
		case 110: goto tr210;
		case 111: goto tr211;
		case 115: goto tr212;
	}
	if ( 45 <= (*p) && (*p) <= 47 )
		goto tr204;
	goto st0;
tr204:
#line 6 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_year(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_YEAR;
      {p++; cs = 166; goto _out;}
    }
    tstr_parsed_set_year4(parsed, v);
  }
#line 13 "ragel/tstr_cparse_datetime.rl"
	{
    sep_char = (*p);
  }
	goto st166;
st166:
	if ( ++p == pe )
		goto _test_eof166;
case 166:
#line 3692 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 65: goto tr214;
		case 68: goto tr215;
		case 70: goto tr216;
		case 74: goto tr217;
		case 77: goto tr218;
		case 78: goto tr219;
		case 79: goto tr220;
		case 83: goto tr221;
		case 97: goto tr214;
		case 100: goto tr215;
		case 102: goto tr216;
		case 106: goto tr217;
		case 109: goto tr218;
		case 110: goto tr219;
		case 111: goto tr220;
		case 115: goto tr221;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr213;
	goto st0;
tr213:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st167;
st167:
	if ( ++p == pe )
		goto _test_eof167;
case 167:
#line 3722 "tstr_cparse_datetime.c"
	_widec = (*p);
	if ( (*p) < 46 ) {
		if ( 45 <= (*p) && (*p) <= 45 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else if ( (*p) > 46 ) {
		if ( 47 <= (*p) && (*p) <= 47 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else {
		_widec = (short)(128 + ((*p) - -128));
		if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
	}
	if ( _widec > 57 ) {
		if ( 557 <= _widec && _widec <= 559 )
			goto tr223;
	} else if ( _widec >= 48 )
		goto st168;
	goto st0;
st168:
	if ( ++p == pe )
		goto _test_eof168;
case 168:
	_widec = (*p);
	if ( (*p) < 46 ) {
		if ( 45 <= (*p) && (*p) <= 45 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else if ( (*p) > 46 ) {
		if ( 47 <= (*p) && (*p) <= 47 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else {
		_widec = (short)(128 + ((*p) - -128));
		if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
	}
	if ( 557 <= _widec && _widec <= 559 )
		goto tr223;
	goto st0;
tr223:
#line 22 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_month(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_MONTH;
      {p++; cs = 169; goto _out;}
    }
    tstr_parsed_set_month(parsed, v);
  }
	goto st169;
st169:
	if ( ++p == pe )
		goto _test_eof169;
case 169:
#line 3804 "tstr_cparse_datetime.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr224;
	goto st0;
tr224:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st412;
tr260:
#line 22 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_month(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_MONTH;
      {p++; cs = 412; goto _out;}
    }
    tstr_parsed_set_month(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st412;
st412:
	if ( ++p == pe )
		goto _test_eof412;
case 412:
#line 3828 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 32: goto tr468;
		case 44: goto tr469;
		case 84: goto tr471;
		case 116: goto tr471;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st413;
	goto st0;
st413:
	if ( ++p == pe )
		goto _test_eof413;
case 413:
	switch( (*p) ) {
		case 32: goto tr468;
		case 44: goto tr469;
		case 84: goto tr471;
		case 116: goto tr471;
	}
	goto st0;
tr214:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st170;
st170:
	if ( ++p == pe )
		goto _test_eof170;
case 170:
#line 3857 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 80: goto st171;
		case 85: goto st174;
		case 112: goto st171;
		case 117: goto st174;
	}
	goto st0;
st171:
	if ( ++p == pe )
		goto _test_eof171;
case 171:
	switch( (*p) ) {
		case 82: goto st172;
		case 114: goto st172;
	}
	goto st0;
st172:
	if ( ++p == pe )
		goto _test_eof172;
case 172:
	_widec = (*p);
	if ( (*p) < 46 ) {
		if ( 45 <= (*p) && (*p) <= 45 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else if ( (*p) > 46 ) {
		if ( 47 <= (*p) && (*p) <= 47 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else {
		_widec = (short)(128 + ((*p) - -128));
		if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
	}
	switch( _widec ) {
		case 73: goto st173;
		case 105: goto st173;
	}
	if ( 557 <= _widec && _widec <= 559 )
		goto tr223;
	goto st0;
st173:
	if ( ++p == pe )
		goto _test_eof173;
case 173:
	switch( (*p) ) {
		case 76: goto st168;
		case 108: goto st168;
	}
	goto st0;
st174:
	if ( ++p == pe )
		goto _test_eof174;
case 174:
	switch( (*p) ) {
		case 71: goto st175;
		case 103: goto st175;
	}
	goto st0;
st175:
	if ( ++p == pe )
		goto _test_eof175;
case 175:
	_widec = (*p);
	if ( (*p) < 46 ) {
		if ( 45 <= (*p) && (*p) <= 45 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else if ( (*p) > 46 ) {
		if ( 47 <= (*p) && (*p) <= 47 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else {
		_widec = (short)(128 + ((*p) - -128));
		if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
	}
	switch( _widec ) {
		case 85: goto st176;
		case 117: goto st176;
	}
	if ( 557 <= _widec && _widec <= 559 )
		goto tr223;
	goto st0;
st176:
	if ( ++p == pe )
		goto _test_eof176;
case 176:
	switch( (*p) ) {
		case 83: goto st177;
		case 115: goto st177;
	}
	goto st0;
st177:
	if ( ++p == pe )
		goto _test_eof177;
case 177:
	switch( (*p) ) {
		case 84: goto st168;
		case 116: goto st168;
	}
	goto st0;
tr215:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st178;
st178:
	if ( ++p == pe )
		goto _test_eof178;
case 178:
#line 3994 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 69: goto st179;
		case 101: goto st179;
	}
	goto st0;
st179:
	if ( ++p == pe )
		goto _test_eof179;
case 179:
	switch( (*p) ) {
		case 67: goto st180;
		case 99: goto st180;
	}
	goto st0;
st180:
	if ( ++p == pe )
		goto _test_eof180;
case 180:
	_widec = (*p);
	if ( (*p) < 46 ) {
		if ( 45 <= (*p) && (*p) <= 45 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else if ( (*p) > 46 ) {
		if ( 47 <= (*p) && (*p) <= 47 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else {
		_widec = (short)(128 + ((*p) - -128));
		if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
	}
	switch( _widec ) {
		case 69: goto st181;
		case 101: goto st181;
	}
	if ( 557 <= _widec && _widec <= 559 )
		goto tr223;
	goto st0;
st181:
	if ( ++p == pe )
		goto _test_eof181;
case 181:
	switch( (*p) ) {
		case 77: goto st182;
		case 109: goto st182;
	}
	goto st0;
st182:
	if ( ++p == pe )
		goto _test_eof182;
case 182:
	switch( (*p) ) {
		case 66: goto st183;
		case 98: goto st183;
	}
	goto st0;
st183:
	if ( ++p == pe )
		goto _test_eof183;
case 183:
	switch( (*p) ) {
		case 69: goto st184;
		case 101: goto st184;
	}
	goto st0;
st184:
	if ( ++p == pe )
		goto _test_eof184;
case 184:
	switch( (*p) ) {
		case 82: goto st168;
		case 114: goto st168;
	}
	goto st0;
tr216:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st185;
st185:
	if ( ++p == pe )
		goto _test_eof185;
case 185:
#line 4091 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 69: goto st186;
		case 101: goto st186;
	}
	goto st0;
st186:
	if ( ++p == pe )
		goto _test_eof186;
case 186:
	switch( (*p) ) {
		case 66: goto st187;
		case 98: goto st187;
	}
	goto st0;
st187:
	if ( ++p == pe )
		goto _test_eof187;
case 187:
	_widec = (*p);
	if ( (*p) < 46 ) {
		if ( 45 <= (*p) && (*p) <= 45 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else if ( (*p) > 46 ) {
		if ( 47 <= (*p) && (*p) <= 47 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else {
		_widec = (short)(128 + ((*p) - -128));
		if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
	}
	switch( _widec ) {
		case 82: goto st188;
		case 114: goto st188;
	}
	if ( 557 <= _widec && _widec <= 559 )
		goto tr223;
	goto st0;
st188:
	if ( ++p == pe )
		goto _test_eof188;
case 188:
	switch( (*p) ) {
		case 85: goto st189;
		case 117: goto st189;
	}
	goto st0;
st189:
	if ( ++p == pe )
		goto _test_eof189;
case 189:
	switch( (*p) ) {
		case 65: goto st190;
		case 97: goto st190;
	}
	goto st0;
st190:
	if ( ++p == pe )
		goto _test_eof190;
case 190:
	switch( (*p) ) {
		case 82: goto st191;
		case 114: goto st191;
	}
	goto st0;
st191:
	if ( ++p == pe )
		goto _test_eof191;
case 191:
	switch( (*p) ) {
		case 89: goto st168;
		case 121: goto st168;
	}
	goto st0;
tr217:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st192;
st192:
	if ( ++p == pe )
		goto _test_eof192;
case 192:
#line 4188 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 65: goto st193;
		case 85: goto st195;
		case 97: goto st193;
		case 117: goto st195;
	}
	goto st0;
st193:
	if ( ++p == pe )
		goto _test_eof193;
case 193:
	switch( (*p) ) {
		case 78: goto st194;
		case 110: goto st194;
	}
	goto st0;
st194:
	if ( ++p == pe )
		goto _test_eof194;
case 194:
	_widec = (*p);
	if ( (*p) < 46 ) {
		if ( 45 <= (*p) && (*p) <= 45 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else if ( (*p) > 46 ) {
		if ( 47 <= (*p) && (*p) <= 47 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else {
		_widec = (short)(128 + ((*p) - -128));
		if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
	}
	switch( _widec ) {
		case 85: goto st189;
		case 117: goto st189;
	}
	if ( 557 <= _widec && _widec <= 559 )
		goto tr223;
	goto st0;
st195:
	if ( ++p == pe )
		goto _test_eof195;
case 195:
	switch( (*p) ) {
		case 76: goto st196;
		case 78: goto st197;
		case 108: goto st196;
		case 110: goto st197;
	}
	goto st0;
st196:
	if ( ++p == pe )
		goto _test_eof196;
case 196:
	_widec = (*p);
	if ( (*p) < 46 ) {
		if ( 45 <= (*p) && (*p) <= 45 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else if ( (*p) > 46 ) {
		if ( 47 <= (*p) && (*p) <= 47 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else {
		_widec = (short)(128 + ((*p) - -128));
		if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
	}
	switch( _widec ) {
		case 89: goto st168;
		case 121: goto st168;
	}
	if ( 557 <= _widec && _widec <= 559 )
		goto tr223;
	goto st0;
st197:
	if ( ++p == pe )
		goto _test_eof197;
case 197:
	_widec = (*p);
	if ( (*p) < 46 ) {
		if ( 45 <= (*p) && (*p) <= 45 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else if ( (*p) > 46 ) {
		if ( 47 <= (*p) && (*p) <= 47 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else {
		_widec = (short)(128 + ((*p) - -128));
		if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
	}
	switch( _widec ) {
		case 69: goto st168;
		case 101: goto st168;
	}
	if ( 557 <= _widec && _widec <= 559 )
		goto tr223;
	goto st0;
tr218:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st198;
st198:
	if ( ++p == pe )
		goto _test_eof198;
case 198:
#line 4338 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 65: goto st199;
		case 97: goto st199;
	}
	goto st0;
st199:
	if ( ++p == pe )
		goto _test_eof199;
case 199:
	switch( (*p) ) {
		case 82: goto st200;
		case 89: goto st168;
		case 114: goto st200;
		case 121: goto st168;
	}
	goto st0;
st200:
	if ( ++p == pe )
		goto _test_eof200;
case 200:
	_widec = (*p);
	if ( (*p) < 46 ) {
		if ( 45 <= (*p) && (*p) <= 45 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else if ( (*p) > 46 ) {
		if ( 47 <= (*p) && (*p) <= 47 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else {
		_widec = (short)(128 + ((*p) - -128));
		if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
	}
	switch( _widec ) {
		case 67: goto st201;
		case 99: goto st201;
	}
	if ( 557 <= _widec && _widec <= 559 )
		goto tr223;
	goto st0;
st201:
	if ( ++p == pe )
		goto _test_eof201;
case 201:
	switch( (*p) ) {
		case 72: goto st168;
		case 104: goto st168;
	}
	goto st0;
tr219:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st202;
st202:
	if ( ++p == pe )
		goto _test_eof202;
case 202:
#line 4410 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 79: goto st203;
		case 111: goto st203;
	}
	goto st0;
st203:
	if ( ++p == pe )
		goto _test_eof203;
case 203:
	switch( (*p) ) {
		case 86: goto st180;
		case 118: goto st180;
	}
	goto st0;
tr220:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st204;
st204:
	if ( ++p == pe )
		goto _test_eof204;
case 204:
#line 4433 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 67: goto st205;
		case 99: goto st205;
	}
	goto st0;
st205:
	if ( ++p == pe )
		goto _test_eof205;
case 205:
	switch( (*p) ) {
		case 84: goto st206;
		case 116: goto st206;
	}
	goto st0;
st206:
	if ( ++p == pe )
		goto _test_eof206;
case 206:
	_widec = (*p);
	if ( (*p) < 46 ) {
		if ( 45 <= (*p) && (*p) <= 45 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else if ( (*p) > 46 ) {
		if ( 47 <= (*p) && (*p) <= 47 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else {
		_widec = (short)(128 + ((*p) - -128));
		if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
	}
	switch( _widec ) {
		case 79: goto st182;
		case 111: goto st182;
	}
	if ( 557 <= _widec && _widec <= 559 )
		goto tr223;
	goto st0;
tr221:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st207;
st207:
	if ( ++p == pe )
		goto _test_eof207;
case 207:
#line 4494 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 69: goto st208;
		case 101: goto st208;
	}
	goto st0;
st208:
	if ( ++p == pe )
		goto _test_eof208;
case 208:
	switch( (*p) ) {
		case 80: goto st209;
		case 112: goto st209;
	}
	goto st0;
st209:
	if ( ++p == pe )
		goto _test_eof209;
case 209:
	_widec = (*p);
	if ( (*p) < 46 ) {
		if ( 45 <= (*p) && (*p) <= 45 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else if ( (*p) > 46 ) {
		if ( 47 <= (*p) && (*p) <= 47 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else {
		_widec = (short)(128 + ((*p) - -128));
		if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
	}
	switch( _widec ) {
		case 84: goto st180;
		case 116: goto st180;
	}
	if ( 557 <= _widec && _widec <= 559 )
		goto tr223;
	goto st0;
tr205:
#line 6 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_year(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_YEAR;
      {p++; cs = 210; goto _out;}
    }
    tstr_parsed_set_year4(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st210;
st210:
	if ( ++p == pe )
		goto _test_eof210;
case 210:
#line 4563 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 80: goto st211;
		case 85: goto st215;
		case 112: goto st211;
		case 117: goto st215;
	}
	goto st0;
st211:
	if ( ++p == pe )
		goto _test_eof211;
case 211:
	switch( (*p) ) {
		case 82: goto st212;
		case 114: goto st212;
	}
	goto st0;
st212:
	if ( ++p == pe )
		goto _test_eof212;
case 212:
	switch( (*p) ) {
		case 73: goto st213;
		case 105: goto st213;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr260;
	goto st0;
st213:
	if ( ++p == pe )
		goto _test_eof213;
case 213:
	switch( (*p) ) {
		case 76: goto st214;
		case 108: goto st214;
	}
	goto st0;
st214:
	if ( ++p == pe )
		goto _test_eof214;
case 214:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr260;
	goto st0;
st215:
	if ( ++p == pe )
		goto _test_eof215;
case 215:
	switch( (*p) ) {
		case 71: goto st216;
		case 103: goto st216;
	}
	goto st0;
st216:
	if ( ++p == pe )
		goto _test_eof216;
case 216:
	switch( (*p) ) {
		case 85: goto st217;
		case 117: goto st217;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr260;
	goto st0;
st217:
	if ( ++p == pe )
		goto _test_eof217;
case 217:
	switch( (*p) ) {
		case 83: goto st218;
		case 115: goto st218;
	}
	goto st0;
st218:
	if ( ++p == pe )
		goto _test_eof218;
case 218:
	switch( (*p) ) {
		case 84: goto st214;
		case 116: goto st214;
	}
	goto st0;
tr206:
#line 6 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_year(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_YEAR;
      {p++; cs = 219; goto _out;}
    }
    tstr_parsed_set_year4(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st219;
st219:
	if ( ++p == pe )
		goto _test_eof219;
case 219:
#line 4661 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 69: goto st220;
		case 101: goto st220;
	}
	goto st0;
st220:
	if ( ++p == pe )
		goto _test_eof220;
case 220:
	switch( (*p) ) {
		case 67: goto st221;
		case 99: goto st221;
	}
	goto st0;
st221:
	if ( ++p == pe )
		goto _test_eof221;
case 221:
	switch( (*p) ) {
		case 69: goto st222;
		case 101: goto st222;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr260;
	goto st0;
st222:
	if ( ++p == pe )
		goto _test_eof222;
case 222:
	switch( (*p) ) {
		case 77: goto st223;
		case 109: goto st223;
	}
	goto st0;
st223:
	if ( ++p == pe )
		goto _test_eof223;
case 223:
	switch( (*p) ) {
		case 66: goto st224;
		case 98: goto st224;
	}
	goto st0;
st224:
	if ( ++p == pe )
		goto _test_eof224;
case 224:
	switch( (*p) ) {
		case 69: goto st225;
		case 101: goto st225;
	}
	goto st0;
st225:
	if ( ++p == pe )
		goto _test_eof225;
case 225:
	switch( (*p) ) {
		case 82: goto st214;
		case 114: goto st214;
	}
	goto st0;
tr207:
#line 6 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_year(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_YEAR;
      {p++; cs = 226; goto _out;}
    }
    tstr_parsed_set_year4(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st226;
st226:
	if ( ++p == pe )
		goto _test_eof226;
case 226:
#line 4739 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 69: goto st227;
		case 101: goto st227;
	}
	goto st0;
st227:
	if ( ++p == pe )
		goto _test_eof227;
case 227:
	switch( (*p) ) {
		case 66: goto st228;
		case 98: goto st228;
	}
	goto st0;
st228:
	if ( ++p == pe )
		goto _test_eof228;
case 228:
	switch( (*p) ) {
		case 82: goto st229;
		case 114: goto st229;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr260;
	goto st0;
st229:
	if ( ++p == pe )
		goto _test_eof229;
case 229:
	switch( (*p) ) {
		case 85: goto st230;
		case 117: goto st230;
	}
	goto st0;
st230:
	if ( ++p == pe )
		goto _test_eof230;
case 230:
	switch( (*p) ) {
		case 65: goto st231;
		case 97: goto st231;
	}
	goto st0;
st231:
	if ( ++p == pe )
		goto _test_eof231;
case 231:
	switch( (*p) ) {
		case 82: goto st232;
		case 114: goto st232;
	}
	goto st0;
st232:
	if ( ++p == pe )
		goto _test_eof232;
case 232:
	switch( (*p) ) {
		case 89: goto st214;
		case 121: goto st214;
	}
	goto st0;
tr208:
#line 6 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_year(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_YEAR;
      {p++; cs = 233; goto _out;}
    }
    tstr_parsed_set_year4(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st233;
st233:
	if ( ++p == pe )
		goto _test_eof233;
case 233:
#line 4817 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 65: goto st234;
		case 85: goto st236;
		case 97: goto st234;
		case 117: goto st236;
	}
	goto st0;
st234:
	if ( ++p == pe )
		goto _test_eof234;
case 234:
	switch( (*p) ) {
		case 78: goto st235;
		case 110: goto st235;
	}
	goto st0;
st235:
	if ( ++p == pe )
		goto _test_eof235;
case 235:
	switch( (*p) ) {
		case 85: goto st230;
		case 117: goto st230;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr260;
	goto st0;
st236:
	if ( ++p == pe )
		goto _test_eof236;
case 236:
	switch( (*p) ) {
		case 76: goto st237;
		case 78: goto st238;
		case 108: goto st237;
		case 110: goto st238;
	}
	goto st0;
st237:
	if ( ++p == pe )
		goto _test_eof237;
case 237:
	switch( (*p) ) {
		case 89: goto st214;
		case 121: goto st214;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr260;
	goto st0;
st238:
	if ( ++p == pe )
		goto _test_eof238;
case 238:
	switch( (*p) ) {
		case 69: goto st214;
		case 101: goto st214;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr260;
	goto st0;
tr209:
#line 6 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_year(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_YEAR;
      {p++; cs = 239; goto _out;}
    }
    tstr_parsed_set_year4(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st239;
st239:
	if ( ++p == pe )
		goto _test_eof239;
case 239:
#line 4894 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 65: goto st240;
		case 97: goto st240;
	}
	goto st0;
st240:
	if ( ++p == pe )
		goto _test_eof240;
case 240:
	switch( (*p) ) {
		case 82: goto st241;
		case 89: goto st214;
		case 114: goto st241;
		case 121: goto st214;
	}
	goto st0;
st241:
	if ( ++p == pe )
		goto _test_eof241;
case 241:
	switch( (*p) ) {
		case 67: goto st242;
		case 99: goto st242;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr260;
	goto st0;
st242:
	if ( ++p == pe )
		goto _test_eof242;
case 242:
	switch( (*p) ) {
		case 72: goto st214;
		case 104: goto st214;
	}
	goto st0;
tr210:
#line 6 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_year(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_YEAR;
      {p++; cs = 243; goto _out;}
    }
    tstr_parsed_set_year4(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st243;
st243:
	if ( ++p == pe )
		goto _test_eof243;
case 243:
#line 4947 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 79: goto st244;
		case 111: goto st244;
	}
	goto st0;
st244:
	if ( ++p == pe )
		goto _test_eof244;
case 244:
	switch( (*p) ) {
		case 86: goto st221;
		case 118: goto st221;
	}
	goto st0;
tr211:
#line 6 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_year(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_YEAR;
      {p++; cs = 245; goto _out;}
    }
    tstr_parsed_set_year4(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st245;
st245:
	if ( ++p == pe )
		goto _test_eof245;
case 245:
#line 4978 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 67: goto st246;
		case 99: goto st246;
	}
	goto st0;
st246:
	if ( ++p == pe )
		goto _test_eof246;
case 246:
	switch( (*p) ) {
		case 84: goto st247;
		case 116: goto st247;
	}
	goto st0;
st247:
	if ( ++p == pe )
		goto _test_eof247;
case 247:
	switch( (*p) ) {
		case 79: goto st223;
		case 111: goto st223;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr260;
	goto st0;
tr212:
#line 6 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_year(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_YEAR;
      {p++; cs = 248; goto _out;}
    }
    tstr_parsed_set_year4(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st248;
st248:
	if ( ++p == pe )
		goto _test_eof248;
case 248:
#line 5020 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 69: goto st249;
		case 101: goto st249;
	}
	goto st0;
st249:
	if ( ++p == pe )
		goto _test_eof249;
case 249:
	switch( (*p) ) {
		case 80: goto st250;
		case 112: goto st250;
	}
	goto st0;
st250:
	if ( ++p == pe )
		goto _test_eof250;
case 250:
	switch( (*p) ) {
		case 84: goto st221;
		case 116: goto st221;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr260;
	goto st0;
tr49:
#line 30 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_day(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_DAY;
      {p++; cs = 251; goto _out;}
    }
    tstr_parsed_set_day(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st251;
st251:
	if ( ++p == pe )
		goto _test_eof251;
case 251:
#line 5062 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 80: goto st252;
		case 85: goto st256;
		case 112: goto st252;
		case 117: goto st256;
	}
	goto st0;
st252:
	if ( ++p == pe )
		goto _test_eof252;
case 252:
	switch( (*p) ) {
		case 82: goto st253;
		case 114: goto st253;
	}
	goto st0;
st253:
	if ( ++p == pe )
		goto _test_eof253;
case 253:
	switch( (*p) ) {
		case 73: goto st254;
		case 105: goto st254;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr294;
	goto st0;
st254:
	if ( ++p == pe )
		goto _test_eof254;
case 254:
	switch( (*p) ) {
		case 76: goto st255;
		case 108: goto st255;
	}
	goto st0;
st255:
	if ( ++p == pe )
		goto _test_eof255;
case 255:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr294;
	goto st0;
st256:
	if ( ++p == pe )
		goto _test_eof256;
case 256:
	switch( (*p) ) {
		case 71: goto st257;
		case 103: goto st257;
	}
	goto st0;
st257:
	if ( ++p == pe )
		goto _test_eof257;
case 257:
	switch( (*p) ) {
		case 85: goto st258;
		case 117: goto st258;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr294;
	goto st0;
st258:
	if ( ++p == pe )
		goto _test_eof258;
case 258:
	switch( (*p) ) {
		case 83: goto st259;
		case 115: goto st259;
	}
	goto st0;
st259:
	if ( ++p == pe )
		goto _test_eof259;
case 259:
	switch( (*p) ) {
		case 84: goto st255;
		case 116: goto st255;
	}
	goto st0;
tr50:
#line 30 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_day(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_DAY;
      {p++; cs = 260; goto _out;}
    }
    tstr_parsed_set_day(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st260;
st260:
	if ( ++p == pe )
		goto _test_eof260;
case 260:
#line 5160 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 69: goto st261;
		case 101: goto st261;
	}
	goto st0;
st261:
	if ( ++p == pe )
		goto _test_eof261;
case 261:
	switch( (*p) ) {
		case 67: goto st262;
		case 99: goto st262;
	}
	goto st0;
st262:
	if ( ++p == pe )
		goto _test_eof262;
case 262:
	switch( (*p) ) {
		case 69: goto st263;
		case 101: goto st263;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr294;
	goto st0;
st263:
	if ( ++p == pe )
		goto _test_eof263;
case 263:
	switch( (*p) ) {
		case 77: goto st264;
		case 109: goto st264;
	}
	goto st0;
st264:
	if ( ++p == pe )
		goto _test_eof264;
case 264:
	switch( (*p) ) {
		case 66: goto st265;
		case 98: goto st265;
	}
	goto st0;
st265:
	if ( ++p == pe )
		goto _test_eof265;
case 265:
	switch( (*p) ) {
		case 69: goto st266;
		case 101: goto st266;
	}
	goto st0;
st266:
	if ( ++p == pe )
		goto _test_eof266;
case 266:
	switch( (*p) ) {
		case 82: goto st255;
		case 114: goto st255;
	}
	goto st0;
tr51:
#line 30 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_day(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_DAY;
      {p++; cs = 267; goto _out;}
    }
    tstr_parsed_set_day(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st267;
st267:
	if ( ++p == pe )
		goto _test_eof267;
case 267:
#line 5238 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 69: goto st268;
		case 101: goto st268;
	}
	goto st0;
st268:
	if ( ++p == pe )
		goto _test_eof268;
case 268:
	switch( (*p) ) {
		case 66: goto st269;
		case 98: goto st269;
	}
	goto st0;
st269:
	if ( ++p == pe )
		goto _test_eof269;
case 269:
	switch( (*p) ) {
		case 82: goto st270;
		case 114: goto st270;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr294;
	goto st0;
st270:
	if ( ++p == pe )
		goto _test_eof270;
case 270:
	switch( (*p) ) {
		case 85: goto st271;
		case 117: goto st271;
	}
	goto st0;
st271:
	if ( ++p == pe )
		goto _test_eof271;
case 271:
	switch( (*p) ) {
		case 65: goto st272;
		case 97: goto st272;
	}
	goto st0;
st272:
	if ( ++p == pe )
		goto _test_eof272;
case 272:
	switch( (*p) ) {
		case 82: goto st273;
		case 114: goto st273;
	}
	goto st0;
st273:
	if ( ++p == pe )
		goto _test_eof273;
case 273:
	switch( (*p) ) {
		case 89: goto st255;
		case 121: goto st255;
	}
	goto st0;
tr52:
#line 30 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_day(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_DAY;
      {p++; cs = 274; goto _out;}
    }
    tstr_parsed_set_day(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st274;
st274:
	if ( ++p == pe )
		goto _test_eof274;
case 274:
#line 5316 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 73: goto st275;
		case 86: goto st255;
		case 88: goto st255;
		case 105: goto st275;
		case 118: goto st255;
		case 120: goto st255;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr294;
	goto st0;
st275:
	if ( ++p == pe )
		goto _test_eof275;
case 275:
	switch( (*p) ) {
		case 73: goto st255;
		case 105: goto st255;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr294;
	goto st0;
tr53:
#line 30 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_day(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_DAY;
      {p++; cs = 276; goto _out;}
    }
    tstr_parsed_set_day(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st276;
st276:
	if ( ++p == pe )
		goto _test_eof276;
case 276:
#line 5355 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 65: goto st277;
		case 85: goto st279;
		case 97: goto st277;
		case 117: goto st279;
	}
	goto st0;
st277:
	if ( ++p == pe )
		goto _test_eof277;
case 277:
	switch( (*p) ) {
		case 78: goto st278;
		case 110: goto st278;
	}
	goto st0;
st278:
	if ( ++p == pe )
		goto _test_eof278;
case 278:
	switch( (*p) ) {
		case 85: goto st271;
		case 117: goto st271;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr294;
	goto st0;
st279:
	if ( ++p == pe )
		goto _test_eof279;
case 279:
	switch( (*p) ) {
		case 76: goto st280;
		case 78: goto st281;
		case 108: goto st280;
		case 110: goto st281;
	}
	goto st0;
st280:
	if ( ++p == pe )
		goto _test_eof280;
case 280:
	switch( (*p) ) {
		case 89: goto st255;
		case 121: goto st255;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr294;
	goto st0;
st281:
	if ( ++p == pe )
		goto _test_eof281;
case 281:
	switch( (*p) ) {
		case 69: goto st255;
		case 101: goto st255;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr294;
	goto st0;
tr54:
#line 30 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_day(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_DAY;
      {p++; cs = 282; goto _out;}
    }
    tstr_parsed_set_day(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st282;
st282:
	if ( ++p == pe )
		goto _test_eof282;
case 282:
#line 5432 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 65: goto st283;
		case 97: goto st283;
	}
	goto st0;
st283:
	if ( ++p == pe )
		goto _test_eof283;
case 283:
	switch( (*p) ) {
		case 82: goto st284;
		case 89: goto st255;
		case 114: goto st284;
		case 121: goto st255;
	}
	goto st0;
st284:
	if ( ++p == pe )
		goto _test_eof284;
case 284:
	switch( (*p) ) {
		case 67: goto st285;
		case 99: goto st285;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr294;
	goto st0;
st285:
	if ( ++p == pe )
		goto _test_eof285;
case 285:
	switch( (*p) ) {
		case 72: goto st255;
		case 104: goto st255;
	}
	goto st0;
tr55:
#line 30 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_day(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_DAY;
      {p++; cs = 286; goto _out;}
    }
    tstr_parsed_set_day(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st286;
st286:
	if ( ++p == pe )
		goto _test_eof286;
case 286:
#line 5485 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 68: goto st287;
		case 79: goto st289;
		case 100: goto st287;
		case 111: goto st289;
	}
	goto st0;
st287:
	if ( ++p == pe )
		goto _test_eof287;
case 287:
	switch( (*p) ) {
		case 32: goto tr45;
		case 46: goto tr323;
	}
	goto st0;
tr323:
#line 25 "ragel/tstr_cparse_datetime.rl"
	{
    mark = mark_day;
  }
#line 30 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_day(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_DAY;
      {p++; cs = 288; goto _out;}
    }
    tstr_parsed_set_day(parsed, v);
  }
	goto st288;
st288:
	if ( ++p == pe )
		goto _test_eof288;
case 288:
#line 5520 "tstr_cparse_datetime.c"
	if ( (*p) == 32 )
		goto st31;
	goto st0;
st289:
	if ( ++p == pe )
		goto _test_eof289;
case 289:
	switch( (*p) ) {
		case 86: goto st262;
		case 118: goto st262;
	}
	goto st0;
tr56:
#line 30 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_day(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_DAY;
      {p++; cs = 290; goto _out;}
    }
    tstr_parsed_set_day(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st290;
st290:
	if ( ++p == pe )
		goto _test_eof290;
case 290:
#line 5549 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 67: goto st291;
		case 99: goto st291;
	}
	goto st0;
st291:
	if ( ++p == pe )
		goto _test_eof291;
case 291:
	switch( (*p) ) {
		case 84: goto st292;
		case 116: goto st292;
	}
	goto st0;
st292:
	if ( ++p == pe )
		goto _test_eof292;
case 292:
	switch( (*p) ) {
		case 79: goto st264;
		case 111: goto st264;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr294;
	goto st0;
st293:
	if ( ++p == pe )
		goto _test_eof293;
case 293:
	switch( (*p) ) {
		case 68: goto st287;
		case 100: goto st287;
	}
	goto st0;
tr58:
#line 30 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_day(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_DAY;
      {p++; cs = 294; goto _out;}
    }
    tstr_parsed_set_day(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st294;
st294:
	if ( ++p == pe )
		goto _test_eof294;
case 294:
#line 5600 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 69: goto st295;
		case 84: goto st287;
		case 101: goto st295;
		case 116: goto st287;
	}
	goto st0;
st295:
	if ( ++p == pe )
		goto _test_eof295;
case 295:
	switch( (*p) ) {
		case 80: goto st296;
		case 112: goto st296;
	}
	goto st0;
st296:
	if ( ++p == pe )
		goto _test_eof296;
case 296:
	switch( (*p) ) {
		case 84: goto st262;
		case 116: goto st262;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr294;
	goto st0;
st297:
	if ( ++p == pe )
		goto _test_eof297;
case 297:
	switch( (*p) ) {
		case 72: goto st287;
		case 104: goto st287;
	}
	goto st0;
tr60:
#line 30 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_day(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_DAY;
      {p++; cs = 298; goto _out;}
    }
    tstr_parsed_set_day(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st298;
st298:
	if ( ++p == pe )
		goto _test_eof298;
case 298:
#line 5653 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 73: goto st299;
		case 105: goto st299;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr294;
	goto st0;
tr61:
#line 30 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_day(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_DAY;
      {p++; cs = 299; goto _out;}
    }
    tstr_parsed_set_day(parsed, v);
  }
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st299;
st299:
	if ( ++p == pe )
		goto _test_eof299;
case 299:
#line 5677 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 73: goto st275;
		case 105: goto st275;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr294;
	goto st0;
tr3:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st300;
st300:
	if ( ++p == pe )
		goto _test_eof300;
case 300:
#line 5693 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 80: goto st301;
		case 85: goto st317;
		case 112: goto st301;
		case 117: goto st317;
	}
	goto st0;
st301:
	if ( ++p == pe )
		goto _test_eof301;
case 301:
	switch( (*p) ) {
		case 82: goto st302;
		case 114: goto st302;
	}
	goto st0;
st302:
	if ( ++p == pe )
		goto _test_eof302;
case 302:
	switch( (*p) ) {
		case 32: goto tr332;
		case 44: goto tr333;
		case 46: goto tr335;
		case 73: goto st315;
		case 105: goto st315;
	}
	if ( 45 <= (*p) && (*p) <= 47 )
		goto tr334;
	goto st0;
tr332:
#line 22 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_month(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_MONTH;
      {p++; cs = 303; goto _out;}
    }
    tstr_parsed_set_month(parsed, v);
  }
	goto st303;
st303:
	if ( ++p == pe )
		goto _test_eof303;
case 303:
#line 5738 "tstr_cparse_datetime.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr337;
	goto st0;
tr337:
#line 21 "ragel/tstr_cparse_datetime.rl"
	{
    mark_day = p;
  }
	goto st304;
st304:
	if ( ++p == pe )
		goto _test_eof304;
case 304:
#line 5752 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 32: goto tr338;
		case 44: goto tr339;
		case 78: goto st306;
		case 82: goto st306;
		case 83: goto st308;
		case 84: goto st309;
		case 110: goto st306;
		case 114: goto st306;
		case 115: goto st308;
		case 116: goto st309;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st305;
	goto st0;
st305:
	if ( ++p == pe )
		goto _test_eof305;
case 305:
	switch( (*p) ) {
		case 32: goto tr338;
		case 44: goto tr339;
		case 78: goto st306;
		case 82: goto st306;
		case 83: goto st308;
		case 84: goto st309;
		case 110: goto st306;
		case 114: goto st306;
		case 115: goto st308;
		case 116: goto st309;
	}
	goto st0;
st306:
	if ( ++p == pe )
		goto _test_eof306;
case 306:
	switch( (*p) ) {
		case 68: goto st307;
		case 100: goto st307;
	}
	goto st0;
st307:
	if ( ++p == pe )
		goto _test_eof307;
case 307:
	switch( (*p) ) {
		case 32: goto tr338;
		case 44: goto tr339;
	}
	goto st0;
st308:
	if ( ++p == pe )
		goto _test_eof308;
case 308:
	switch( (*p) ) {
		case 84: goto st307;
		case 116: goto st307;
	}
	goto st0;
st309:
	if ( ++p == pe )
		goto _test_eof309;
case 309:
	switch( (*p) ) {
		case 72: goto st307;
		case 104: goto st307;
	}
	goto st0;
tr333:
#line 22 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_month(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_MONTH;
      {p++; cs = 310; goto _out;}
    }
    tstr_parsed_set_month(parsed, v);
  }
	goto st310;
st310:
	if ( ++p == pe )
		goto _test_eof310;
case 310:
#line 5835 "tstr_cparse_datetime.c"
	if ( (*p) == 32 )
		goto st303;
	goto st0;
tr334:
#line 22 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_month(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_MONTH;
      {p++; cs = 311; goto _out;}
    }
    tstr_parsed_set_month(parsed, v);
  }
#line 13 "ragel/tstr_cparse_datetime.rl"
	{
    sep_char = (*p);
  }
	goto st311;
st311:
	if ( ++p == pe )
		goto _test_eof311;
case 311:
#line 5857 "tstr_cparse_datetime.c"
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr346;
	goto st0;
tr346:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st312;
st312:
	if ( ++p == pe )
		goto _test_eof312;
case 312:
#line 5869 "tstr_cparse_datetime.c"
	_widec = (*p);
	if ( (*p) < 46 ) {
		if ( 45 <= (*p) && (*p) <= 45 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else if ( (*p) > 46 ) {
		if ( 47 <= (*p) && (*p) <= 47 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else {
		_widec = (short)(128 + ((*p) - -128));
		if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
	}
	if ( _widec > 57 ) {
		if ( 557 <= _widec && _widec <= 559 )
			goto tr348;
	} else if ( _widec >= 48 )
		goto st313;
	goto st0;
st313:
	if ( ++p == pe )
		goto _test_eof313;
case 313:
	_widec = (*p);
	if ( (*p) < 46 ) {
		if ( 45 <= (*p) && (*p) <= 45 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else if ( (*p) > 46 ) {
		if ( 47 <= (*p) && (*p) <= 47 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
		}
	} else {
		_widec = (short)(128 + ((*p) - -128));
		if ( 
#line 17 "ragel/tstr_cparse_datetime.rl"

    (*p) == sep_char
   ) _widec += 256;
	}
	if ( 557 <= _widec && _widec <= 559 )
		goto tr348;
	goto st0;
tr335:
#line 22 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_month(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_MONTH;
      {p++; cs = 314; goto _out;}
    }
    tstr_parsed_set_month(parsed, v);
  }
#line 13 "ragel/tstr_cparse_datetime.rl"
	{
    sep_char = (*p);
  }
	goto st314;
st314:
	if ( ++p == pe )
		goto _test_eof314;
case 314:
#line 5955 "tstr_cparse_datetime.c"
	if ( (*p) == 32 )
		goto st303;
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr346;
	goto st0;
st315:
	if ( ++p == pe )
		goto _test_eof315;
case 315:
	switch( (*p) ) {
		case 76: goto st316;
		case 108: goto st316;
	}
	goto st0;
st316:
	if ( ++p == pe )
		goto _test_eof316;
case 316:
	switch( (*p) ) {
		case 32: goto tr332;
		case 44: goto tr333;
		case 46: goto tr335;
	}
	if ( 45 <= (*p) && (*p) <= 47 )
		goto tr334;
	goto st0;
st317:
	if ( ++p == pe )
		goto _test_eof317;
case 317:
	switch( (*p) ) {
		case 71: goto st318;
		case 103: goto st318;
	}
	goto st0;
st318:
	if ( ++p == pe )
		goto _test_eof318;
case 318:
	switch( (*p) ) {
		case 32: goto tr332;
		case 44: goto tr333;
		case 46: goto tr335;
		case 85: goto st319;
		case 117: goto st319;
	}
	if ( 45 <= (*p) && (*p) <= 47 )
		goto tr334;
	goto st0;
st319:
	if ( ++p == pe )
		goto _test_eof319;
case 319:
	switch( (*p) ) {
		case 83: goto st320;
		case 115: goto st320;
	}
	goto st0;
st320:
	if ( ++p == pe )
		goto _test_eof320;
case 320:
	switch( (*p) ) {
		case 84: goto st316;
		case 116: goto st316;
	}
	goto st0;
tr4:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st321;
st321:
	if ( ++p == pe )
		goto _test_eof321;
case 321:
#line 6031 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 69: goto st322;
		case 101: goto st322;
	}
	goto st0;
st322:
	if ( ++p == pe )
		goto _test_eof322;
case 322:
	switch( (*p) ) {
		case 67: goto st323;
		case 99: goto st323;
	}
	goto st0;
st323:
	if ( ++p == pe )
		goto _test_eof323;
case 323:
	switch( (*p) ) {
		case 32: goto tr332;
		case 44: goto tr333;
		case 46: goto tr335;
		case 69: goto st324;
		case 101: goto st324;
	}
	if ( 45 <= (*p) && (*p) <= 47 )
		goto tr334;
	goto st0;
st324:
	if ( ++p == pe )
		goto _test_eof324;
case 324:
	switch( (*p) ) {
		case 77: goto st325;
		case 109: goto st325;
	}
	goto st0;
st325:
	if ( ++p == pe )
		goto _test_eof325;
case 325:
	switch( (*p) ) {
		case 66: goto st326;
		case 98: goto st326;
	}
	goto st0;
st326:
	if ( ++p == pe )
		goto _test_eof326;
case 326:
	switch( (*p) ) {
		case 69: goto st327;
		case 101: goto st327;
	}
	goto st0;
st327:
	if ( ++p == pe )
		goto _test_eof327;
case 327:
	switch( (*p) ) {
		case 82: goto st316;
		case 114: goto st316;
	}
	goto st0;
tr42:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st328;
st328:
	if ( ++p == pe )
		goto _test_eof328;
case 328:
#line 6104 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 69: goto st329;
		case 101: goto st329;
	}
	goto st0;
st329:
	if ( ++p == pe )
		goto _test_eof329;
case 329:
	switch( (*p) ) {
		case 66: goto st330;
		case 98: goto st330;
	}
	goto st0;
st330:
	if ( ++p == pe )
		goto _test_eof330;
case 330:
	switch( (*p) ) {
		case 32: goto tr332;
		case 44: goto tr333;
		case 46: goto tr335;
		case 82: goto st331;
		case 114: goto st331;
	}
	if ( 45 <= (*p) && (*p) <= 47 )
		goto tr334;
	goto st0;
st331:
	if ( ++p == pe )
		goto _test_eof331;
case 331:
	switch( (*p) ) {
		case 85: goto st332;
		case 117: goto st332;
	}
	goto st0;
st332:
	if ( ++p == pe )
		goto _test_eof332;
case 332:
	switch( (*p) ) {
		case 65: goto st333;
		case 97: goto st333;
	}
	goto st0;
st333:
	if ( ++p == pe )
		goto _test_eof333;
case 333:
	switch( (*p) ) {
		case 82: goto st334;
		case 114: goto st334;
	}
	goto st0;
st334:
	if ( ++p == pe )
		goto _test_eof334;
case 334:
	switch( (*p) ) {
		case 89: goto st316;
		case 121: goto st316;
	}
	goto st0;
tr6:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st335;
st335:
	if ( ++p == pe )
		goto _test_eof335;
case 335:
#line 6177 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 65: goto st336;
		case 85: goto st338;
		case 97: goto st336;
		case 117: goto st338;
	}
	goto st0;
st336:
	if ( ++p == pe )
		goto _test_eof336;
case 336:
	switch( (*p) ) {
		case 78: goto st337;
		case 110: goto st337;
	}
	goto st0;
st337:
	if ( ++p == pe )
		goto _test_eof337;
case 337:
	switch( (*p) ) {
		case 32: goto tr332;
		case 44: goto tr333;
		case 46: goto tr335;
		case 85: goto st332;
		case 117: goto st332;
	}
	if ( 45 <= (*p) && (*p) <= 47 )
		goto tr334;
	goto st0;
st338:
	if ( ++p == pe )
		goto _test_eof338;
case 338:
	switch( (*p) ) {
		case 76: goto st339;
		case 78: goto st340;
		case 108: goto st339;
		case 110: goto st340;
	}
	goto st0;
st339:
	if ( ++p == pe )
		goto _test_eof339;
case 339:
	switch( (*p) ) {
		case 32: goto tr332;
		case 44: goto tr333;
		case 46: goto tr335;
		case 89: goto st316;
		case 121: goto st316;
	}
	if ( 45 <= (*p) && (*p) <= 47 )
		goto tr334;
	goto st0;
st340:
	if ( ++p == pe )
		goto _test_eof340;
case 340:
	switch( (*p) ) {
		case 32: goto tr332;
		case 44: goto tr333;
		case 46: goto tr335;
		case 69: goto st316;
		case 101: goto st316;
	}
	if ( 45 <= (*p) && (*p) <= 47 )
		goto tr334;
	goto st0;
tr43:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st341;
st341:
	if ( ++p == pe )
		goto _test_eof341;
case 341:
#line 6255 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 65: goto st342;
		case 97: goto st342;
	}
	goto st0;
st342:
	if ( ++p == pe )
		goto _test_eof342;
case 342:
	switch( (*p) ) {
		case 82: goto st343;
		case 89: goto st316;
		case 114: goto st343;
		case 121: goto st316;
	}
	goto st0;
st343:
	if ( ++p == pe )
		goto _test_eof343;
case 343:
	switch( (*p) ) {
		case 32: goto tr332;
		case 44: goto tr333;
		case 46: goto tr335;
		case 67: goto st344;
		case 99: goto st344;
	}
	if ( 45 <= (*p) && (*p) <= 47 )
		goto tr334;
	goto st0;
st344:
	if ( ++p == pe )
		goto _test_eof344;
case 344:
	switch( (*p) ) {
		case 72: goto st316;
		case 104: goto st316;
	}
	goto st0;
tr8:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st345;
st345:
	if ( ++p == pe )
		goto _test_eof345;
case 345:
#line 6303 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 79: goto st346;
		case 111: goto st346;
	}
	goto st0;
st346:
	if ( ++p == pe )
		goto _test_eof346;
case 346:
	switch( (*p) ) {
		case 86: goto st323;
		case 118: goto st323;
	}
	goto st0;
tr9:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st347;
st347:
	if ( ++p == pe )
		goto _test_eof347;
case 347:
#line 6326 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 67: goto st348;
		case 99: goto st348;
	}
	goto st0;
st348:
	if ( ++p == pe )
		goto _test_eof348;
case 348:
	switch( (*p) ) {
		case 84: goto st349;
		case 116: goto st349;
	}
	goto st0;
st349:
	if ( ++p == pe )
		goto _test_eof349;
case 349:
	switch( (*p) ) {
		case 32: goto tr332;
		case 44: goto tr333;
		case 46: goto tr335;
		case 79: goto st325;
		case 111: goto st325;
	}
	if ( 45 <= (*p) && (*p) <= 47 )
		goto tr334;
	goto st0;
tr44:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st350;
st350:
	if ( ++p == pe )
		goto _test_eof350;
case 350:
#line 6363 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 69: goto st351;
		case 101: goto st351;
	}
	goto st0;
st351:
	if ( ++p == pe )
		goto _test_eof351;
case 351:
	switch( (*p) ) {
		case 80: goto st352;
		case 112: goto st352;
	}
	goto st0;
st352:
	if ( ++p == pe )
		goto _test_eof352;
case 352:
	switch( (*p) ) {
		case 32: goto tr332;
		case 44: goto tr333;
		case 46: goto tr335;
		case 84: goto st323;
		case 116: goto st323;
	}
	if ( 45 <= (*p) && (*p) <= 47 )
		goto tr334;
	goto st0;
tr40:
#line 38 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_day_name(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_DAY_NAME;
      {p++; cs = 353; goto _out;}
    }
    tstr_parsed_set_day_name(parsed, v);
  }
	goto st353;
st353:
	if ( ++p == pe )
		goto _test_eof353;
case 353:
#line 6406 "tstr_cparse_datetime.c"
	if ( (*p) == 32 )
		goto st29;
	goto st0;
tr41:
#line 38 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_day_name(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_DAY_NAME;
      {p++; cs = 354; goto _out;}
    }
    tstr_parsed_set_day_name(parsed, v);
  }
	goto st354;
st354:
	if ( ++p == pe )
		goto _test_eof354;
case 354:
#line 6424 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 32: goto st29;
		case 44: goto st353;
	}
	goto st0;
tr5:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st355;
st355:
	if ( ++p == pe )
		goto _test_eof355;
case 355:
#line 6438 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 69: goto st329;
		case 82: goto st356;
		case 101: goto st329;
		case 114: goto st356;
	}
	goto st0;
st356:
	if ( ++p == pe )
		goto _test_eof356;
case 356:
	switch( (*p) ) {
		case 73: goto st357;
		case 105: goto st357;
	}
	goto st0;
st357:
	if ( ++p == pe )
		goto _test_eof357;
case 357:
	switch( (*p) ) {
		case 68: goto st358;
		case 100: goto st358;
	}
	goto st0;
st358:
	if ( ++p == pe )
		goto _test_eof358;
case 358:
	switch( (*p) ) {
		case 65: goto st359;
		case 97: goto st359;
	}
	goto st0;
st359:
	if ( ++p == pe )
		goto _test_eof359;
case 359:
	switch( (*p) ) {
		case 89: goto st28;
		case 121: goto st28;
	}
	goto st0;
tr7:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st360;
st360:
	if ( ++p == pe )
		goto _test_eof360;
case 360:
#line 6490 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 65: goto st342;
		case 79: goto st361;
		case 97: goto st342;
		case 111: goto st361;
	}
	goto st0;
st361:
	if ( ++p == pe )
		goto _test_eof361;
case 361:
	switch( (*p) ) {
		case 78: goto st362;
		case 110: goto st362;
	}
	goto st0;
st362:
	if ( ++p == pe )
		goto _test_eof362;
case 362:
	switch( (*p) ) {
		case 32: goto tr39;
		case 44: goto tr40;
		case 46: goto tr41;
		case 68: goto st358;
		case 100: goto st358;
	}
	goto st0;
tr10:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st363;
st363:
	if ( ++p == pe )
		goto _test_eof363;
case 363:
#line 6527 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 65: goto st364;
		case 69: goto st351;
		case 85: goto st361;
		case 97: goto st364;
		case 101: goto st351;
		case 117: goto st361;
	}
	goto st0;
st364:
	if ( ++p == pe )
		goto _test_eof364;
case 364:
	switch( (*p) ) {
		case 84: goto st365;
		case 116: goto st365;
	}
	goto st0;
st365:
	if ( ++p == pe )
		goto _test_eof365;
case 365:
	switch( (*p) ) {
		case 32: goto tr39;
		case 44: goto tr40;
		case 46: goto tr41;
		case 85: goto st366;
		case 117: goto st366;
	}
	goto st0;
st366:
	if ( ++p == pe )
		goto _test_eof366;
case 366:
	switch( (*p) ) {
		case 82: goto st357;
		case 114: goto st357;
	}
	goto st0;
tr11:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st367;
st367:
	if ( ++p == pe )
		goto _test_eof367;
case 367:
#line 6575 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 72: goto st368;
		case 85: goto st371;
		case 104: goto st368;
		case 117: goto st371;
	}
	goto st0;
st368:
	if ( ++p == pe )
		goto _test_eof368;
case 368:
	switch( (*p) ) {
		case 85: goto st369;
		case 117: goto st369;
	}
	goto st0;
st369:
	if ( ++p == pe )
		goto _test_eof369;
case 369:
	switch( (*p) ) {
		case 32: goto tr39;
		case 44: goto tr40;
		case 46: goto tr41;
		case 82: goto st370;
		case 114: goto st370;
	}
	goto st0;
st370:
	if ( ++p == pe )
		goto _test_eof370;
case 370:
	switch( (*p) ) {
		case 83: goto st362;
		case 115: goto st362;
	}
	goto st0;
st371:
	if ( ++p == pe )
		goto _test_eof371;
case 371:
	switch( (*p) ) {
		case 69: goto st372;
		case 101: goto st372;
	}
	goto st0;
st372:
	if ( ++p == pe )
		goto _test_eof372;
case 372:
	switch( (*p) ) {
		case 32: goto tr39;
		case 44: goto tr40;
		case 46: goto tr41;
		case 83: goto st362;
		case 115: goto st362;
	}
	goto st0;
tr12:
#line 4 "ragel/tstr_common.rl"
	{ mark = p; }
	goto st373;
st373:
	if ( ++p == pe )
		goto _test_eof373;
case 373:
#line 6642 "tstr_cparse_datetime.c"
	switch( (*p) ) {
		case 69: goto st374;
		case 101: goto st374;
	}
	goto st0;
st374:
	if ( ++p == pe )
		goto _test_eof374;
case 374:
	switch( (*p) ) {
		case 68: goto st375;
		case 100: goto st375;
	}
	goto st0;
st375:
	if ( ++p == pe )
		goto _test_eof375;
case 375:
	switch( (*p) ) {
		case 32: goto tr39;
		case 44: goto tr40;
		case 46: goto tr41;
		case 78: goto st376;
		case 110: goto st376;
	}
	goto st0;
st376:
	if ( ++p == pe )
		goto _test_eof376;
case 376:
	switch( (*p) ) {
		case 69: goto st377;
		case 101: goto st377;
	}
	goto st0;
st377:
	if ( ++p == pe )
		goto _test_eof377;
case 377:
	switch( (*p) ) {
		case 83: goto st357;
		case 115: goto st357;
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
	_test_eof23: cs = 23; goto _test_eof; 
	_test_eof24: cs = 24; goto _test_eof; 
	_test_eof25: cs = 25; goto _test_eof; 
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
	_test_eof36: cs = 36; goto _test_eof; 
	_test_eof37: cs = 37; goto _test_eof; 
	_test_eof38: cs = 38; goto _test_eof; 
	_test_eof378: cs = 378; goto _test_eof; 
	_test_eof39: cs = 39; goto _test_eof; 
	_test_eof40: cs = 40; goto _test_eof; 
	_test_eof41: cs = 41; goto _test_eof; 
	_test_eof42: cs = 42; goto _test_eof; 
	_test_eof43: cs = 43; goto _test_eof; 
	_test_eof44: cs = 44; goto _test_eof; 
	_test_eof379: cs = 379; goto _test_eof; 
	_test_eof45: cs = 45; goto _test_eof; 
	_test_eof46: cs = 46; goto _test_eof; 
	_test_eof47: cs = 47; goto _test_eof; 
	_test_eof380: cs = 380; goto _test_eof; 
	_test_eof48: cs = 48; goto _test_eof; 
	_test_eof49: cs = 49; goto _test_eof; 
	_test_eof50: cs = 50; goto _test_eof; 
	_test_eof381: cs = 381; goto _test_eof; 
	_test_eof51: cs = 51; goto _test_eof; 
	_test_eof382: cs = 382; goto _test_eof; 
	_test_eof52: cs = 52; goto _test_eof; 
	_test_eof53: cs = 53; goto _test_eof; 
	_test_eof383: cs = 383; goto _test_eof; 
	_test_eof54: cs = 54; goto _test_eof; 
	_test_eof55: cs = 55; goto _test_eof; 
	_test_eof56: cs = 56; goto _test_eof; 
	_test_eof384: cs = 384; goto _test_eof; 
	_test_eof385: cs = 385; goto _test_eof; 
	_test_eof386: cs = 386; goto _test_eof; 
	_test_eof387: cs = 387; goto _test_eof; 
	_test_eof57: cs = 57; goto _test_eof; 
	_test_eof58: cs = 58; goto _test_eof; 
	_test_eof388: cs = 388; goto _test_eof; 
	_test_eof59: cs = 59; goto _test_eof; 
	_test_eof389: cs = 389; goto _test_eof; 
	_test_eof60: cs = 60; goto _test_eof; 
	_test_eof61: cs = 61; goto _test_eof; 
	_test_eof390: cs = 390; goto _test_eof; 
	_test_eof391: cs = 391; goto _test_eof; 
	_test_eof62: cs = 62; goto _test_eof; 
	_test_eof63: cs = 63; goto _test_eof; 
	_test_eof64: cs = 64; goto _test_eof; 
	_test_eof392: cs = 392; goto _test_eof; 
	_test_eof65: cs = 65; goto _test_eof; 
	_test_eof66: cs = 66; goto _test_eof; 
	_test_eof393: cs = 393; goto _test_eof; 
	_test_eof394: cs = 394; goto _test_eof; 
	_test_eof395: cs = 395; goto _test_eof; 
	_test_eof396: cs = 396; goto _test_eof; 
	_test_eof397: cs = 397; goto _test_eof; 
	_test_eof398: cs = 398; goto _test_eof; 
	_test_eof399: cs = 399; goto _test_eof; 
	_test_eof400: cs = 400; goto _test_eof; 
	_test_eof401: cs = 401; goto _test_eof; 
	_test_eof67: cs = 67; goto _test_eof; 
	_test_eof68: cs = 68; goto _test_eof; 
	_test_eof402: cs = 402; goto _test_eof; 
	_test_eof69: cs = 69; goto _test_eof; 
	_test_eof403: cs = 403; goto _test_eof; 
	_test_eof404: cs = 404; goto _test_eof; 
	_test_eof405: cs = 405; goto _test_eof; 
	_test_eof406: cs = 406; goto _test_eof; 
	_test_eof407: cs = 407; goto _test_eof; 
	_test_eof408: cs = 408; goto _test_eof; 
	_test_eof409: cs = 409; goto _test_eof; 
	_test_eof410: cs = 410; goto _test_eof; 
	_test_eof411: cs = 411; goto _test_eof; 
	_test_eof70: cs = 70; goto _test_eof; 
	_test_eof71: cs = 71; goto _test_eof; 
	_test_eof72: cs = 72; goto _test_eof; 
	_test_eof73: cs = 73; goto _test_eof; 
	_test_eof74: cs = 74; goto _test_eof; 
	_test_eof75: cs = 75; goto _test_eof; 
	_test_eof76: cs = 76; goto _test_eof; 
	_test_eof77: cs = 77; goto _test_eof; 
	_test_eof78: cs = 78; goto _test_eof; 
	_test_eof79: cs = 79; goto _test_eof; 
	_test_eof80: cs = 80; goto _test_eof; 
	_test_eof81: cs = 81; goto _test_eof; 
	_test_eof82: cs = 82; goto _test_eof; 
	_test_eof83: cs = 83; goto _test_eof; 
	_test_eof84: cs = 84; goto _test_eof; 
	_test_eof85: cs = 85; goto _test_eof; 
	_test_eof86: cs = 86; goto _test_eof; 
	_test_eof87: cs = 87; goto _test_eof; 
	_test_eof88: cs = 88; goto _test_eof; 
	_test_eof89: cs = 89; goto _test_eof; 
	_test_eof90: cs = 90; goto _test_eof; 
	_test_eof91: cs = 91; goto _test_eof; 
	_test_eof92: cs = 92; goto _test_eof; 
	_test_eof93: cs = 93; goto _test_eof; 
	_test_eof94: cs = 94; goto _test_eof; 
	_test_eof95: cs = 95; goto _test_eof; 
	_test_eof96: cs = 96; goto _test_eof; 
	_test_eof97: cs = 97; goto _test_eof; 
	_test_eof98: cs = 98; goto _test_eof; 
	_test_eof99: cs = 99; goto _test_eof; 
	_test_eof100: cs = 100; goto _test_eof; 
	_test_eof101: cs = 101; goto _test_eof; 
	_test_eof102: cs = 102; goto _test_eof; 
	_test_eof103: cs = 103; goto _test_eof; 
	_test_eof104: cs = 104; goto _test_eof; 
	_test_eof105: cs = 105; goto _test_eof; 
	_test_eof106: cs = 106; goto _test_eof; 
	_test_eof107: cs = 107; goto _test_eof; 
	_test_eof108: cs = 108; goto _test_eof; 
	_test_eof109: cs = 109; goto _test_eof; 
	_test_eof110: cs = 110; goto _test_eof; 
	_test_eof111: cs = 111; goto _test_eof; 
	_test_eof112: cs = 112; goto _test_eof; 
	_test_eof113: cs = 113; goto _test_eof; 
	_test_eof114: cs = 114; goto _test_eof; 
	_test_eof115: cs = 115; goto _test_eof; 
	_test_eof116: cs = 116; goto _test_eof; 
	_test_eof117: cs = 117; goto _test_eof; 
	_test_eof118: cs = 118; goto _test_eof; 
	_test_eof119: cs = 119; goto _test_eof; 
	_test_eof120: cs = 120; goto _test_eof; 
	_test_eof121: cs = 121; goto _test_eof; 
	_test_eof122: cs = 122; goto _test_eof; 
	_test_eof123: cs = 123; goto _test_eof; 
	_test_eof124: cs = 124; goto _test_eof; 
	_test_eof125: cs = 125; goto _test_eof; 
	_test_eof126: cs = 126; goto _test_eof; 
	_test_eof127: cs = 127; goto _test_eof; 
	_test_eof128: cs = 128; goto _test_eof; 
	_test_eof129: cs = 129; goto _test_eof; 
	_test_eof130: cs = 130; goto _test_eof; 
	_test_eof131: cs = 131; goto _test_eof; 
	_test_eof132: cs = 132; goto _test_eof; 
	_test_eof133: cs = 133; goto _test_eof; 
	_test_eof134: cs = 134; goto _test_eof; 
	_test_eof135: cs = 135; goto _test_eof; 
	_test_eof136: cs = 136; goto _test_eof; 
	_test_eof137: cs = 137; goto _test_eof; 
	_test_eof138: cs = 138; goto _test_eof; 
	_test_eof139: cs = 139; goto _test_eof; 
	_test_eof140: cs = 140; goto _test_eof; 
	_test_eof141: cs = 141; goto _test_eof; 
	_test_eof142: cs = 142; goto _test_eof; 
	_test_eof143: cs = 143; goto _test_eof; 
	_test_eof144: cs = 144; goto _test_eof; 
	_test_eof145: cs = 145; goto _test_eof; 
	_test_eof146: cs = 146; goto _test_eof; 
	_test_eof147: cs = 147; goto _test_eof; 
	_test_eof148: cs = 148; goto _test_eof; 
	_test_eof149: cs = 149; goto _test_eof; 
	_test_eof150: cs = 150; goto _test_eof; 
	_test_eof151: cs = 151; goto _test_eof; 
	_test_eof152: cs = 152; goto _test_eof; 
	_test_eof153: cs = 153; goto _test_eof; 
	_test_eof154: cs = 154; goto _test_eof; 
	_test_eof155: cs = 155; goto _test_eof; 
	_test_eof156: cs = 156; goto _test_eof; 
	_test_eof157: cs = 157; goto _test_eof; 
	_test_eof158: cs = 158; goto _test_eof; 
	_test_eof159: cs = 159; goto _test_eof; 
	_test_eof160: cs = 160; goto _test_eof; 
	_test_eof161: cs = 161; goto _test_eof; 
	_test_eof162: cs = 162; goto _test_eof; 
	_test_eof163: cs = 163; goto _test_eof; 
	_test_eof164: cs = 164; goto _test_eof; 
	_test_eof165: cs = 165; goto _test_eof; 
	_test_eof166: cs = 166; goto _test_eof; 
	_test_eof167: cs = 167; goto _test_eof; 
	_test_eof168: cs = 168; goto _test_eof; 
	_test_eof169: cs = 169; goto _test_eof; 
	_test_eof412: cs = 412; goto _test_eof; 
	_test_eof413: cs = 413; goto _test_eof; 
	_test_eof170: cs = 170; goto _test_eof; 
	_test_eof171: cs = 171; goto _test_eof; 
	_test_eof172: cs = 172; goto _test_eof; 
	_test_eof173: cs = 173; goto _test_eof; 
	_test_eof174: cs = 174; goto _test_eof; 
	_test_eof175: cs = 175; goto _test_eof; 
	_test_eof176: cs = 176; goto _test_eof; 
	_test_eof177: cs = 177; goto _test_eof; 
	_test_eof178: cs = 178; goto _test_eof; 
	_test_eof179: cs = 179; goto _test_eof; 
	_test_eof180: cs = 180; goto _test_eof; 
	_test_eof181: cs = 181; goto _test_eof; 
	_test_eof182: cs = 182; goto _test_eof; 
	_test_eof183: cs = 183; goto _test_eof; 
	_test_eof184: cs = 184; goto _test_eof; 
	_test_eof185: cs = 185; goto _test_eof; 
	_test_eof186: cs = 186; goto _test_eof; 
	_test_eof187: cs = 187; goto _test_eof; 
	_test_eof188: cs = 188; goto _test_eof; 
	_test_eof189: cs = 189; goto _test_eof; 
	_test_eof190: cs = 190; goto _test_eof; 
	_test_eof191: cs = 191; goto _test_eof; 
	_test_eof192: cs = 192; goto _test_eof; 
	_test_eof193: cs = 193; goto _test_eof; 
	_test_eof194: cs = 194; goto _test_eof; 
	_test_eof195: cs = 195; goto _test_eof; 
	_test_eof196: cs = 196; goto _test_eof; 
	_test_eof197: cs = 197; goto _test_eof; 
	_test_eof198: cs = 198; goto _test_eof; 
	_test_eof199: cs = 199; goto _test_eof; 
	_test_eof200: cs = 200; goto _test_eof; 
	_test_eof201: cs = 201; goto _test_eof; 
	_test_eof202: cs = 202; goto _test_eof; 
	_test_eof203: cs = 203; goto _test_eof; 
	_test_eof204: cs = 204; goto _test_eof; 
	_test_eof205: cs = 205; goto _test_eof; 
	_test_eof206: cs = 206; goto _test_eof; 
	_test_eof207: cs = 207; goto _test_eof; 
	_test_eof208: cs = 208; goto _test_eof; 
	_test_eof209: cs = 209; goto _test_eof; 
	_test_eof210: cs = 210; goto _test_eof; 
	_test_eof211: cs = 211; goto _test_eof; 
	_test_eof212: cs = 212; goto _test_eof; 
	_test_eof213: cs = 213; goto _test_eof; 
	_test_eof214: cs = 214; goto _test_eof; 
	_test_eof215: cs = 215; goto _test_eof; 
	_test_eof216: cs = 216; goto _test_eof; 
	_test_eof217: cs = 217; goto _test_eof; 
	_test_eof218: cs = 218; goto _test_eof; 
	_test_eof219: cs = 219; goto _test_eof; 
	_test_eof220: cs = 220; goto _test_eof; 
	_test_eof221: cs = 221; goto _test_eof; 
	_test_eof222: cs = 222; goto _test_eof; 
	_test_eof223: cs = 223; goto _test_eof; 
	_test_eof224: cs = 224; goto _test_eof; 
	_test_eof225: cs = 225; goto _test_eof; 
	_test_eof226: cs = 226; goto _test_eof; 
	_test_eof227: cs = 227; goto _test_eof; 
	_test_eof228: cs = 228; goto _test_eof; 
	_test_eof229: cs = 229; goto _test_eof; 
	_test_eof230: cs = 230; goto _test_eof; 
	_test_eof231: cs = 231; goto _test_eof; 
	_test_eof232: cs = 232; goto _test_eof; 
	_test_eof233: cs = 233; goto _test_eof; 
	_test_eof234: cs = 234; goto _test_eof; 
	_test_eof235: cs = 235; goto _test_eof; 
	_test_eof236: cs = 236; goto _test_eof; 
	_test_eof237: cs = 237; goto _test_eof; 
	_test_eof238: cs = 238; goto _test_eof; 
	_test_eof239: cs = 239; goto _test_eof; 
	_test_eof240: cs = 240; goto _test_eof; 
	_test_eof241: cs = 241; goto _test_eof; 
	_test_eof242: cs = 242; goto _test_eof; 
	_test_eof243: cs = 243; goto _test_eof; 
	_test_eof244: cs = 244; goto _test_eof; 
	_test_eof245: cs = 245; goto _test_eof; 
	_test_eof246: cs = 246; goto _test_eof; 
	_test_eof247: cs = 247; goto _test_eof; 
	_test_eof248: cs = 248; goto _test_eof; 
	_test_eof249: cs = 249; goto _test_eof; 
	_test_eof250: cs = 250; goto _test_eof; 
	_test_eof251: cs = 251; goto _test_eof; 
	_test_eof252: cs = 252; goto _test_eof; 
	_test_eof253: cs = 253; goto _test_eof; 
	_test_eof254: cs = 254; goto _test_eof; 
	_test_eof255: cs = 255; goto _test_eof; 
	_test_eof256: cs = 256; goto _test_eof; 
	_test_eof257: cs = 257; goto _test_eof; 
	_test_eof258: cs = 258; goto _test_eof; 
	_test_eof259: cs = 259; goto _test_eof; 
	_test_eof260: cs = 260; goto _test_eof; 
	_test_eof261: cs = 261; goto _test_eof; 
	_test_eof262: cs = 262; goto _test_eof; 
	_test_eof263: cs = 263; goto _test_eof; 
	_test_eof264: cs = 264; goto _test_eof; 
	_test_eof265: cs = 265; goto _test_eof; 
	_test_eof266: cs = 266; goto _test_eof; 
	_test_eof267: cs = 267; goto _test_eof; 
	_test_eof268: cs = 268; goto _test_eof; 
	_test_eof269: cs = 269; goto _test_eof; 
	_test_eof270: cs = 270; goto _test_eof; 
	_test_eof271: cs = 271; goto _test_eof; 
	_test_eof272: cs = 272; goto _test_eof; 
	_test_eof273: cs = 273; goto _test_eof; 
	_test_eof274: cs = 274; goto _test_eof; 
	_test_eof275: cs = 275; goto _test_eof; 
	_test_eof276: cs = 276; goto _test_eof; 
	_test_eof277: cs = 277; goto _test_eof; 
	_test_eof278: cs = 278; goto _test_eof; 
	_test_eof279: cs = 279; goto _test_eof; 
	_test_eof280: cs = 280; goto _test_eof; 
	_test_eof281: cs = 281; goto _test_eof; 
	_test_eof282: cs = 282; goto _test_eof; 
	_test_eof283: cs = 283; goto _test_eof; 
	_test_eof284: cs = 284; goto _test_eof; 
	_test_eof285: cs = 285; goto _test_eof; 
	_test_eof286: cs = 286; goto _test_eof; 
	_test_eof287: cs = 287; goto _test_eof; 
	_test_eof288: cs = 288; goto _test_eof; 
	_test_eof289: cs = 289; goto _test_eof; 
	_test_eof290: cs = 290; goto _test_eof; 
	_test_eof291: cs = 291; goto _test_eof; 
	_test_eof292: cs = 292; goto _test_eof; 
	_test_eof293: cs = 293; goto _test_eof; 
	_test_eof294: cs = 294; goto _test_eof; 
	_test_eof295: cs = 295; goto _test_eof; 
	_test_eof296: cs = 296; goto _test_eof; 
	_test_eof297: cs = 297; goto _test_eof; 
	_test_eof298: cs = 298; goto _test_eof; 
	_test_eof299: cs = 299; goto _test_eof; 
	_test_eof300: cs = 300; goto _test_eof; 
	_test_eof301: cs = 301; goto _test_eof; 
	_test_eof302: cs = 302; goto _test_eof; 
	_test_eof303: cs = 303; goto _test_eof; 
	_test_eof304: cs = 304; goto _test_eof; 
	_test_eof305: cs = 305; goto _test_eof; 
	_test_eof306: cs = 306; goto _test_eof; 
	_test_eof307: cs = 307; goto _test_eof; 
	_test_eof308: cs = 308; goto _test_eof; 
	_test_eof309: cs = 309; goto _test_eof; 
	_test_eof310: cs = 310; goto _test_eof; 
	_test_eof311: cs = 311; goto _test_eof; 
	_test_eof312: cs = 312; goto _test_eof; 
	_test_eof313: cs = 313; goto _test_eof; 
	_test_eof314: cs = 314; goto _test_eof; 
	_test_eof315: cs = 315; goto _test_eof; 
	_test_eof316: cs = 316; goto _test_eof; 
	_test_eof317: cs = 317; goto _test_eof; 
	_test_eof318: cs = 318; goto _test_eof; 
	_test_eof319: cs = 319; goto _test_eof; 
	_test_eof320: cs = 320; goto _test_eof; 
	_test_eof321: cs = 321; goto _test_eof; 
	_test_eof322: cs = 322; goto _test_eof; 
	_test_eof323: cs = 323; goto _test_eof; 
	_test_eof324: cs = 324; goto _test_eof; 
	_test_eof325: cs = 325; goto _test_eof; 
	_test_eof326: cs = 326; goto _test_eof; 
	_test_eof327: cs = 327; goto _test_eof; 
	_test_eof328: cs = 328; goto _test_eof; 
	_test_eof329: cs = 329; goto _test_eof; 
	_test_eof330: cs = 330; goto _test_eof; 
	_test_eof331: cs = 331; goto _test_eof; 
	_test_eof332: cs = 332; goto _test_eof; 
	_test_eof333: cs = 333; goto _test_eof; 
	_test_eof334: cs = 334; goto _test_eof; 
	_test_eof335: cs = 335; goto _test_eof; 
	_test_eof336: cs = 336; goto _test_eof; 
	_test_eof337: cs = 337; goto _test_eof; 
	_test_eof338: cs = 338; goto _test_eof; 
	_test_eof339: cs = 339; goto _test_eof; 
	_test_eof340: cs = 340; goto _test_eof; 
	_test_eof341: cs = 341; goto _test_eof; 
	_test_eof342: cs = 342; goto _test_eof; 
	_test_eof343: cs = 343; goto _test_eof; 
	_test_eof344: cs = 344; goto _test_eof; 
	_test_eof345: cs = 345; goto _test_eof; 
	_test_eof346: cs = 346; goto _test_eof; 
	_test_eof347: cs = 347; goto _test_eof; 
	_test_eof348: cs = 348; goto _test_eof; 
	_test_eof349: cs = 349; goto _test_eof; 
	_test_eof350: cs = 350; goto _test_eof; 
	_test_eof351: cs = 351; goto _test_eof; 
	_test_eof352: cs = 352; goto _test_eof; 
	_test_eof353: cs = 353; goto _test_eof; 
	_test_eof354: cs = 354; goto _test_eof; 
	_test_eof355: cs = 355; goto _test_eof; 
	_test_eof356: cs = 356; goto _test_eof; 
	_test_eof357: cs = 357; goto _test_eof; 
	_test_eof358: cs = 358; goto _test_eof; 
	_test_eof359: cs = 359; goto _test_eof; 
	_test_eof360: cs = 360; goto _test_eof; 
	_test_eof361: cs = 361; goto _test_eof; 
	_test_eof362: cs = 362; goto _test_eof; 
	_test_eof363: cs = 363; goto _test_eof; 
	_test_eof364: cs = 364; goto _test_eof; 
	_test_eof365: cs = 365; goto _test_eof; 
	_test_eof366: cs = 366; goto _test_eof; 
	_test_eof367: cs = 367; goto _test_eof; 
	_test_eof368: cs = 368; goto _test_eof; 
	_test_eof369: cs = 369; goto _test_eof; 
	_test_eof370: cs = 370; goto _test_eof; 
	_test_eof371: cs = 371; goto _test_eof; 
	_test_eof372: cs = 372; goto _test_eof; 
	_test_eof373: cs = 373; goto _test_eof; 
	_test_eof374: cs = 374; goto _test_eof; 
	_test_eof375: cs = 375; goto _test_eof; 
	_test_eof376: cs = 376; goto _test_eof; 
	_test_eof377: cs = 377; goto _test_eof; 

	_test_eof: {}
	if ( p == eof )
	{
	switch ( cs ) {
	case 378: 
#line 6 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_year(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_YEAR;
      {p++; cs = 0; goto _out;}
    }
    tstr_parsed_set_year4(parsed, v);
  }
	break;
	case 412: 
	case 413: 
#line 30 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_day(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_DAY;
      {p++; cs = 0; goto _out;}
    }
    tstr_parsed_set_day(parsed, v);
  }
	break;
	case 392: 
#line 54 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_minute(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_MINUTE;
      {p++; cs = 0; goto _out;}
    }
    tstr_parsed_set_minute(parsed, v);
  }
	break;
	case 402: 
#line 62 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_second(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_SECOND;
      {p++; cs = 0; goto _out;}
    }
    tstr_parsed_set_second(parsed, v);
  }
	break;
	case 403: 
	case 404: 
	case 405: 
	case 406: 
	case 407: 
	case 408: 
	case 409: 
	case 410: 
	case 411: 
#line 70 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_fraction(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_FRACTION;
      {p++; cs = 0; goto _out;}
    }
    tstr_parsed_set_fraction(parsed, v);
  }
	break;
	case 380: 
	case 382: 
	case 389: 
#line 78 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_tz_offset(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_OFFSET;
      {p++; cs = 0; goto _out;}
    }
    tstr_parsed_set_offset(parsed, v);
  }
	break;
	case 388: 
	case 390: 
	case 391: 
#line 86 "ragel/tstr_common.rl"
	{
    tstr_parsed_set_tz_utc(parsed, mark, p - mark);
  }
	break;
	case 384: 
	case 385: 
	case 386: 
	case 387: 
	case 394: 
	case 395: 
	case 396: 
	case 397: 
	case 399: 
	case 400: 
#line 90 "ragel/tstr_common.rl"
	{
    tstr_parsed_set_tz_abbrev(parsed, mark, p - mark);
  }
	break;
	case 383: 
#line 94 "ragel/tstr_common.rl"
	{
    tstr_parsed_set_tz_annotation(parsed, mark, p - mark);
  }
	break;
	case 379: 
	case 393: 
#line 98 "ragel/tstr_common.rl"
	{
    if (!tstr_token_parse_meridiem(mark, p - mark, &v)) {
      result = TSTR_PARSE_ERR_MERIDIEM;
      {p++; cs = 0; goto _out;}
    }
    tstr_parsed_set_meridiem(parsed, v);
  }
	break;
	case 398: 
	case 401: 
#line 86 "ragel/tstr_common.rl"
	{
    tstr_parsed_set_tz_utc(parsed, mark, p - mark);
  }
#line 90 "ragel/tstr_common.rl"
	{
    tstr_parsed_set_tz_abbrev(parsed, mark, p - mark);
  }
	break;
#line 7227 "tstr_cparse_datetime.c"
	}
	}

	_out: {}
	}

#line 127 "ragel/tstr_cparse_datetime.rl"

  if (result != TSTR_PARSE_OK)
    return result;

  return (cs >= datetime_first_final) ? TSTR_PARSE_OK : TSTR_PARSE_NOMATCH;
}
