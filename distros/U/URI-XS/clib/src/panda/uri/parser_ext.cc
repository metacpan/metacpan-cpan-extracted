
#line 1 "src/panda/uri/parser_ext.rl"
#include "parser.h"

namespace panda { namespace uri {

// ============== RFC3986 compliant parser ===================


#line 11 "src/panda/uri/parser_ext.cc"
static const int uri_parser_ext_start = 171;
static const int uri_parser_ext_first_final = 171;
static const int uri_parser_ext_error = 0;

static const int uri_parser_ext_en_uri = 171;


#line 20 "src/panda/uri/parser_ext.rl"


bool URI::_parse_ext (const string& str, bool& authority_has_pct) {
    const char* ps  = str.data();
    const char* p   = ps;
    const char* pe  = p + str.length();
    const char* eof = pe;
    int         cs  = uri_parser_ext_start;
    size_t      mark;
    int acc = 0;
    bool ext_chars = false;
    
    
#line 33 "src/panda/uri/parser_ext.cc"
	{
	if ( p == pe )
		goto _test_eof;
	switch ( cs )
	{
case 171:
	switch( (*p) ) {
		case 33: goto tr172;
		case 35: goto st173;
		case 37: goto tr174;
		case 47: goto tr175;
		case 59: goto tr172;
		case 61: goto tr172;
		case 63: goto st176;
		case 64: goto tr172;
		case 95: goto tr172;
		case 126: goto tr172;
	}
	if ( (*p) < 65 ) {
		if ( 36 <= (*p) && (*p) <= 57 )
			goto tr172;
	} else if ( (*p) > 90 ) {
		if ( 97 <= (*p) && (*p) <= 122 )
			goto tr177;
	} else
		goto tr177;
	goto st0;
st0:
cs = 0;
	goto _out;
tr172:
#line 10 "src/panda/uri/parser.rl"
	{
        mark = p - ps;
    }
	goto st172;
st172:
	if ( ++p == pe )
		goto _test_eof172;
case 172:
#line 74 "src/panda/uri/parser_ext.cc"
	switch( (*p) ) {
		case 33: goto st172;
		case 35: goto tr178;
		case 37: goto st3;
		case 47: goto st175;
		case 59: goto st172;
		case 61: goto st172;
		case 63: goto tr180;
		case 95: goto st172;
		case 126: goto st172;
	}
	if ( (*p) < 64 ) {
		if ( 36 <= (*p) && (*p) <= 57 )
			goto st172;
	} else if ( (*p) > 90 ) {
		if ( 97 <= (*p) && (*p) <= 122 )
			goto st172;
	} else
		goto st172;
	goto st0;
tr178:
#line 23 "src/panda/uri/parser.rl"
	{ SAVE(_path); }
	goto st173;
tr187:
#line 10 "src/panda/uri/parser.rl"
	{
        mark = p - ps;
    }
#line 24 "src/panda/uri/parser.rl"
	{ SAVE(_qstr); }
	goto st173;
tr190:
#line 24 "src/panda/uri/parser.rl"
	{ SAVE(_qstr); }
	goto st173;
tr194:
#line 11 "src/panda/uri/parser_ext.rl"
	{ ext_chars = true; }
#line 24 "src/panda/uri/parser.rl"
	{ SAVE(_qstr); }
	goto st173;
tr198:
#line 10 "src/panda/uri/parser.rl"
	{
        mark = p - ps;
    }
#line 20 "src/panda/uri/parser.rl"
	{ SAVE(_host); }
#line 23 "src/panda/uri/parser.rl"
	{ SAVE(_path); }
	goto st173;
tr205:
#line 20 "src/panda/uri/parser.rl"
	{ SAVE(_host); }
#line 10 "src/panda/uri/parser.rl"
	{
        mark = p - ps;
    }
#line 23 "src/panda/uri/parser.rl"
	{ SAVE(_path); }
	goto st173;
tr210:
#line 21 "src/panda/uri/parser.rl"
	{ NSAVE(_port); }
#line 10 "src/panda/uri/parser.rl"
	{
        mark = p - ps;
    }
#line 23 "src/panda/uri/parser.rl"
	{ SAVE(_path); }
	goto st173;
st173:
	if ( ++p == pe )
		goto _test_eof173;
case 173:
#line 151 "src/panda/uri/parser_ext.cc"
	switch( (*p) ) {
		case 33: goto tr181;
		case 37: goto tr182;
		case 61: goto tr181;
		case 95: goto tr181;
		case 126: goto tr181;
	}
	if ( (*p) < 63 ) {
		if ( 36 <= (*p) && (*p) <= 59 )
			goto tr181;
	} else if ( (*p) > 90 ) {
		if ( 97 <= (*p) && (*p) <= 122 )
			goto tr181;
	} else
		goto tr181;
	goto st0;
tr181:
#line 10 "src/panda/uri/parser.rl"
	{
        mark = p - ps;
    }
	goto st174;
st174:
	if ( ++p == pe )
		goto _test_eof174;
case 174:
#line 178 "src/panda/uri/parser_ext.cc"
	switch( (*p) ) {
		case 33: goto st174;
		case 37: goto st1;
		case 61: goto st174;
		case 95: goto st174;
		case 126: goto st174;
	}
	if ( (*p) < 63 ) {
		if ( 36 <= (*p) && (*p) <= 59 )
			goto st174;
	} else if ( (*p) > 90 ) {
		if ( 97 <= (*p) && (*p) <= 122 )
			goto st174;
	} else
		goto st174;
	goto st0;
tr182:
#line 10 "src/panda/uri/parser.rl"
	{
        mark = p - ps;
    }
	goto st1;
st1:
	if ( ++p == pe )
		goto _test_eof1;
case 1:
#line 205 "src/panda/uri/parser_ext.cc"
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st2;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st2;
	} else
		goto st2;
	goto st0;
st2:
	if ( ++p == pe )
		goto _test_eof2;
case 2:
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st174;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st174;
	} else
		goto st174;
	goto st0;
tr174:
#line 10 "src/panda/uri/parser.rl"
	{
        mark = p - ps;
    }
	goto st3;
st3:
	if ( ++p == pe )
		goto _test_eof3;
case 3:
#line 238 "src/panda/uri/parser_ext.cc"
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st4;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st4;
	} else
		goto st4;
	goto st0;
st4:
	if ( ++p == pe )
		goto _test_eof4;
case 4:
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st172;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st172;
	} else
		goto st172;
	goto st0;
tr222:
#line 10 "src/panda/uri/parser.rl"
	{
        mark = p - ps;
    }
	goto st175;
tr200:
#line 10 "src/panda/uri/parser.rl"
	{
        mark = p - ps;
    }
#line 20 "src/panda/uri/parser.rl"
	{ SAVE(_host); }
	goto st175;
tr207:
#line 20 "src/panda/uri/parser.rl"
	{ SAVE(_host); }
#line 10 "src/panda/uri/parser.rl"
	{
        mark = p - ps;
    }
	goto st175;
tr211:
#line 21 "src/panda/uri/parser.rl"
	{ NSAVE(_port); }
#line 10 "src/panda/uri/parser.rl"
	{
        mark = p - ps;
    }
	goto st175;
st175:
	if ( ++p == pe )
		goto _test_eof175;
case 175:
#line 295 "src/panda/uri/parser_ext.cc"
	switch( (*p) ) {
		case 33: goto st175;
		case 35: goto tr178;
		case 37: goto st5;
		case 61: goto st175;
		case 63: goto tr180;
		case 95: goto st175;
		case 126: goto st175;
	}
	if ( (*p) < 64 ) {
		if ( 36 <= (*p) && (*p) <= 59 )
			goto st175;
	} else if ( (*p) > 90 ) {
		if ( 97 <= (*p) && (*p) <= 122 )
			goto st175;
	} else
		goto st175;
	goto st0;
tr223:
#line 10 "src/panda/uri/parser.rl"
	{
        mark = p - ps;
    }
	goto st5;
st5:
	if ( ++p == pe )
		goto _test_eof5;
case 5:
#line 324 "src/panda/uri/parser_ext.cc"
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st6;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st6;
	} else
		goto st6;
	goto st0;
st6:
	if ( ++p == pe )
		goto _test_eof6;
case 6:
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st175;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st175;
	} else
		goto st175;
	goto st0;
tr180:
#line 23 "src/panda/uri/parser.rl"
	{ SAVE(_path); }
	goto st176;
tr202:
#line 10 "src/panda/uri/parser.rl"
	{
        mark = p - ps;
    }
#line 20 "src/panda/uri/parser.rl"
	{ SAVE(_host); }
#line 23 "src/panda/uri/parser.rl"
	{ SAVE(_path); }
	goto st176;
tr209:
#line 20 "src/panda/uri/parser.rl"
	{ SAVE(_host); }
#line 10 "src/panda/uri/parser.rl"
	{
        mark = p - ps;
    }
#line 23 "src/panda/uri/parser.rl"
	{ SAVE(_path); }
	goto st176;
tr213:
#line 21 "src/panda/uri/parser.rl"
	{ NSAVE(_port); }
#line 10 "src/panda/uri/parser.rl"
	{
        mark = p - ps;
    }
#line 23 "src/panda/uri/parser.rl"
	{ SAVE(_path); }
	goto st176;
st176:
	if ( ++p == pe )
		goto _test_eof176;
case 176:
#line 385 "src/panda/uri/parser_ext.cc"
	switch( (*p) ) {
		case 34: goto tr186;
		case 35: goto tr187;
		case 37: goto tr188;
		case 61: goto tr185;
		case 95: goto tr185;
		case 126: goto tr185;
	}
	if ( (*p) < 63 ) {
		if ( 33 <= (*p) && (*p) <= 59 )
			goto tr185;
	} else if ( (*p) > 90 ) {
		if ( (*p) > 122 ) {
			if ( 123 <= (*p) && (*p) <= 125 )
				goto tr186;
		} else if ( (*p) >= 97 )
			goto tr185;
	} else
		goto tr185;
	goto st0;
tr185:
#line 10 "src/panda/uri/parser.rl"
	{
        mark = p - ps;
    }
	goto st177;
tr192:
#line 11 "src/panda/uri/parser_ext.rl"
	{ ext_chars = true; }
	goto st177;
st177:
	if ( ++p == pe )
		goto _test_eof177;
case 177:
#line 420 "src/panda/uri/parser_ext.cc"
	switch( (*p) ) {
		case 34: goto st178;
		case 35: goto tr190;
		case 37: goto st7;
		case 61: goto st177;
		case 95: goto st177;
		case 126: goto st177;
	}
	if ( (*p) < 63 ) {
		if ( 33 <= (*p) && (*p) <= 59 )
			goto st177;
	} else if ( (*p) > 90 ) {
		if ( (*p) > 122 ) {
			if ( 123 <= (*p) && (*p) <= 125 )
				goto st178;
		} else if ( (*p) >= 97 )
			goto st177;
	} else
		goto st177;
	goto st0;
tr186:
#line 10 "src/panda/uri/parser.rl"
	{
        mark = p - ps;
    }
	goto st178;
tr193:
#line 11 "src/panda/uri/parser_ext.rl"
	{ ext_chars = true; }
	goto st178;
st178:
	if ( ++p == pe )
		goto _test_eof178;
case 178:
#line 455 "src/panda/uri/parser_ext.cc"
	switch( (*p) ) {
		case 34: goto tr193;
		case 35: goto tr194;
		case 37: goto tr195;
		case 61: goto tr192;
		case 95: goto tr192;
		case 126: goto tr192;
	}
	if ( (*p) < 63 ) {
		if ( 33 <= (*p) && (*p) <= 59 )
			goto tr192;
	} else if ( (*p) > 90 ) {
		if ( (*p) > 122 ) {
			if ( 123 <= (*p) && (*p) <= 125 )
				goto tr193;
		} else if ( (*p) >= 97 )
			goto tr192;
	} else
		goto tr192;
	goto st0;
tr188:
#line 10 "src/panda/uri/parser.rl"
	{
        mark = p - ps;
    }
	goto st7;
tr195:
#line 11 "src/panda/uri/parser_ext.rl"
	{ ext_chars = true; }
	goto st7;
st7:
	if ( ++p == pe )
		goto _test_eof7;
case 7:
#line 490 "src/panda/uri/parser_ext.cc"
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st8;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st8;
	} else
		goto st8;
	goto st0;
st8:
	if ( ++p == pe )
		goto _test_eof8;
case 8:
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st177;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st177;
	} else
		goto st177;
	goto st0;
tr175:
#line 10 "src/panda/uri/parser.rl"
	{
        mark = p - ps;
    }
	goto st179;
st179:
	if ( ++p == pe )
		goto _test_eof179;
case 179:
#line 523 "src/panda/uri/parser_ext.cc"
	switch( (*p) ) {
		case 33: goto st175;
		case 35: goto tr178;
		case 37: goto st5;
		case 47: goto st180;
		case 61: goto st175;
		case 63: goto tr180;
		case 95: goto st175;
		case 126: goto st175;
	}
	if ( (*p) < 64 ) {
		if ( 36 <= (*p) && (*p) <= 59 )
			goto st175;
	} else if ( (*p) > 90 ) {
		if ( 97 <= (*p) && (*p) <= 122 )
			goto st175;
	} else
		goto st175;
	goto st0;
st180:
	if ( ++p == pe )
		goto _test_eof180;
case 180:
	switch( (*p) ) {
		case 33: goto tr197;
		case 35: goto tr198;
		case 37: goto tr199;
		case 47: goto tr200;
		case 58: goto tr201;
		case 61: goto tr197;
		case 63: goto tr202;
		case 64: goto tr203;
		case 91: goto tr204;
		case 95: goto tr197;
		case 126: goto tr197;
	}
	if ( (*p) < 65 ) {
		if ( 36 <= (*p) && (*p) <= 59 )
			goto tr197;
	} else if ( (*p) > 90 ) {
		if ( 97 <= (*p) && (*p) <= 122 )
			goto tr197;
	} else
		goto tr197;
	goto st0;
tr197:
#line 10 "src/panda/uri/parser.rl"
	{
        mark = p - ps;
    }
	goto st181;
st181:
	if ( ++p == pe )
		goto _test_eof181;
case 181:
#line 579 "src/panda/uri/parser_ext.cc"
	switch( (*p) ) {
		case 33: goto st181;
		case 35: goto tr205;
		case 37: goto tr206;
		case 47: goto tr207;
		case 58: goto tr208;
		case 61: goto st181;
		case 63: goto tr209;
		case 64: goto tr13;
		case 95: goto st181;
		case 126: goto st181;
	}
	if ( (*p) < 65 ) {
		if ( 36 <= (*p) && (*p) <= 59 )
			goto st181;
	} else if ( (*p) > 90 ) {
		if ( 97 <= (*p) && (*p) <= 122 )
			goto st181;
	} else
		goto st181;
	goto st0;
tr206:
#line 27 "src/panda/uri/parser.rl"
	{ authority_has_pct = true; }
	goto st9;
tr199:
#line 10 "src/panda/uri/parser.rl"
	{
        mark = p - ps;
    }
#line 27 "src/panda/uri/parser.rl"
	{ authority_has_pct = true; }
	goto st9;
st9:
	if ( ++p == pe )
		goto _test_eof9;
case 9:
#line 617 "src/panda/uri/parser_ext.cc"
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st10;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st10;
	} else
		goto st10;
	goto st0;
st10:
	if ( ++p == pe )
		goto _test_eof10;
case 10:
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st181;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st181;
	} else
		goto st181;
	goto st0;
tr201:
#line 10 "src/panda/uri/parser.rl"
	{
        mark = p - ps;
    }
#line 20 "src/panda/uri/parser.rl"
	{ SAVE(_host); }
	goto st182;
tr208:
#line 20 "src/panda/uri/parser.rl"
	{ SAVE(_host); }
	goto st182;
tr212:
#line 14 "src/panda/uri/parser.rl"
	{
        acc *= 10;
        acc += *p - '0';
    }
	goto st182;
st182:
	if ( ++p == pe )
		goto _test_eof182;
case 182:
#line 663 "src/panda/uri/parser_ext.cc"
	switch( (*p) ) {
		case 33: goto st11;
		case 35: goto tr210;
		case 37: goto tr12;
		case 47: goto tr211;
		case 61: goto st11;
		case 63: goto tr213;
		case 64: goto tr13;
		case 95: goto st11;
		case 126: goto st11;
	}
	if ( (*p) < 58 ) {
		if ( (*p) > 46 ) {
			if ( 48 <= (*p) && (*p) <= 57 )
				goto tr212;
		} else if ( (*p) >= 36 )
			goto st11;
	} else if ( (*p) > 59 ) {
		if ( (*p) > 90 ) {
			if ( 97 <= (*p) && (*p) <= 122 )
				goto st11;
		} else if ( (*p) >= 65 )
			goto st11;
	} else
		goto st11;
	goto st0;
st11:
	if ( ++p == pe )
		goto _test_eof11;
case 11:
	switch( (*p) ) {
		case 33: goto st11;
		case 37: goto tr12;
		case 61: goto st11;
		case 64: goto tr13;
		case 95: goto st11;
		case 126: goto st11;
	}
	if ( (*p) < 48 ) {
		if ( 36 <= (*p) && (*p) <= 46 )
			goto st11;
	} else if ( (*p) > 59 ) {
		if ( (*p) > 90 ) {
			if ( 97 <= (*p) && (*p) <= 122 )
				goto st11;
		} else if ( (*p) >= 65 )
			goto st11;
	} else
		goto st11;
	goto st0;
tr12:
#line 27 "src/panda/uri/parser.rl"
	{ authority_has_pct = true; }
	goto st12;
st12:
	if ( ++p == pe )
		goto _test_eof12;
case 12:
#line 722 "src/panda/uri/parser_ext.cc"
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st13;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st13;
	} else
		goto st13;
	goto st0;
st13:
	if ( ++p == pe )
		goto _test_eof13;
case 13:
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st11;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st11;
	} else
		goto st11;
	goto st0;
tr13:
#line 22 "src/panda/uri/parser.rl"
	{ SAVE(_user_info); }
	goto st183;
tr203:
#line 10 "src/panda/uri/parser.rl"
	{
        mark = p - ps;
    }
#line 22 "src/panda/uri/parser.rl"
	{ SAVE(_user_info); }
	goto st183;
st183:
	if ( ++p == pe )
		goto _test_eof183;
case 183:
#line 761 "src/panda/uri/parser_ext.cc"
	switch( (*p) ) {
		case 33: goto tr214;
		case 35: goto tr198;
		case 37: goto tr215;
		case 47: goto tr200;
		case 58: goto tr216;
		case 61: goto tr214;
		case 63: goto tr202;
		case 91: goto tr204;
		case 95: goto tr214;
		case 126: goto tr214;
	}
	if ( (*p) < 65 ) {
		if ( 36 <= (*p) && (*p) <= 59 )
			goto tr214;
	} else if ( (*p) > 90 ) {
		if ( 97 <= (*p) && (*p) <= 122 )
			goto tr214;
	} else
		goto tr214;
	goto st0;
tr214:
#line 10 "src/panda/uri/parser.rl"
	{
        mark = p - ps;
    }
	goto st184;
st184:
	if ( ++p == pe )
		goto _test_eof184;
case 184:
#line 793 "src/panda/uri/parser_ext.cc"
	switch( (*p) ) {
		case 33: goto st184;
		case 35: goto tr205;
		case 37: goto tr217;
		case 47: goto tr207;
		case 58: goto tr218;
		case 61: goto st184;
		case 63: goto tr209;
		case 95: goto st184;
		case 126: goto st184;
	}
	if ( (*p) < 65 ) {
		if ( 36 <= (*p) && (*p) <= 59 )
			goto st184;
	} else if ( (*p) > 90 ) {
		if ( 97 <= (*p) && (*p) <= 122 )
			goto st184;
	} else
		goto st184;
	goto st0;
tr217:
#line 27 "src/panda/uri/parser.rl"
	{ authority_has_pct = true; }
	goto st14;
tr215:
#line 10 "src/panda/uri/parser.rl"
	{
        mark = p - ps;
    }
#line 27 "src/panda/uri/parser.rl"
	{ authority_has_pct = true; }
	goto st14;
st14:
	if ( ++p == pe )
		goto _test_eof14;
case 14:
#line 830 "src/panda/uri/parser_ext.cc"
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st15;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st15;
	} else
		goto st15;
	goto st0;
st15:
	if ( ++p == pe )
		goto _test_eof15;
case 15:
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st184;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st184;
	} else
		goto st184;
	goto st0;
tr216:
#line 10 "src/panda/uri/parser.rl"
	{
        mark = p - ps;
    }
#line 20 "src/panda/uri/parser.rl"
	{ SAVE(_host); }
	goto st185;
tr218:
#line 20 "src/panda/uri/parser.rl"
	{ SAVE(_host); }
	goto st185;
tr219:
#line 14 "src/panda/uri/parser.rl"
	{
        acc *= 10;
        acc += *p - '0';
    }
	goto st185;
st185:
	if ( ++p == pe )
		goto _test_eof185;
case 185:
#line 876 "src/panda/uri/parser_ext.cc"
	switch( (*p) ) {
		case 35: goto tr210;
		case 47: goto tr211;
		case 63: goto tr213;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr219;
	goto st0;
tr204:
#line 10 "src/panda/uri/parser.rl"
	{
        mark = p - ps;
    }
	goto st16;
st16:
	if ( ++p == pe )
		goto _test_eof16;
case 16:
#line 895 "src/panda/uri/parser_ext.cc"
	switch( (*p) ) {
		case 58: goto st152;
		case 118: goto st167;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st17;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st17;
	} else
		goto st17;
	goto st0;
st17:
	if ( ++p == pe )
		goto _test_eof17;
case 17:
	if ( (*p) == 58 )
		goto st21;
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st18;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st18;
	} else
		goto st18;
	goto st0;
st18:
	if ( ++p == pe )
		goto _test_eof18;
case 18:
	if ( (*p) == 58 )
		goto st21;
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st19;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st19;
	} else
		goto st19;
	goto st0;
st19:
	if ( ++p == pe )
		goto _test_eof19;
case 19:
	if ( (*p) == 58 )
		goto st21;
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st20;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st20;
	} else
		goto st20;
	goto st0;
st20:
	if ( ++p == pe )
		goto _test_eof20;
case 20:
	if ( (*p) == 58 )
		goto st21;
	goto st0;
st21:
	if ( ++p == pe )
		goto _test_eof21;
case 21:
	if ( (*p) == 58 )
		goto st138;
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st22;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st22;
	} else
		goto st22;
	goto st0;
st22:
	if ( ++p == pe )
		goto _test_eof22;
case 22:
	if ( (*p) == 58 )
		goto st26;
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st23;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st23;
	} else
		goto st23;
	goto st0;
st23:
	if ( ++p == pe )
		goto _test_eof23;
case 23:
	if ( (*p) == 58 )
		goto st26;
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st24;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st24;
	} else
		goto st24;
	goto st0;
st24:
	if ( ++p == pe )
		goto _test_eof24;
case 24:
	if ( (*p) == 58 )
		goto st26;
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st25;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st25;
	} else
		goto st25;
	goto st0;
st25:
	if ( ++p == pe )
		goto _test_eof25;
case 25:
	if ( (*p) == 58 )
		goto st26;
	goto st0;
st26:
	if ( ++p == pe )
		goto _test_eof26;
case 26:
	if ( (*p) == 58 )
		goto st124;
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st27;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st27;
	} else
		goto st27;
	goto st0;
st27:
	if ( ++p == pe )
		goto _test_eof27;
case 27:
	if ( (*p) == 58 )
		goto st31;
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st28;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st28;
	} else
		goto st28;
	goto st0;
st28:
	if ( ++p == pe )
		goto _test_eof28;
case 28:
	if ( (*p) == 58 )
		goto st31;
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st29;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st29;
	} else
		goto st29;
	goto st0;
st29:
	if ( ++p == pe )
		goto _test_eof29;
case 29:
	if ( (*p) == 58 )
		goto st31;
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st30;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st30;
	} else
		goto st30;
	goto st0;
st30:
	if ( ++p == pe )
		goto _test_eof30;
case 30:
	if ( (*p) == 58 )
		goto st31;
	goto st0;
st31:
	if ( ++p == pe )
		goto _test_eof31;
case 31:
	if ( (*p) == 58 )
		goto st110;
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st32;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st32;
	} else
		goto st32;
	goto st0;
st32:
	if ( ++p == pe )
		goto _test_eof32;
case 32:
	if ( (*p) == 58 )
		goto st36;
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st33;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st33;
	} else
		goto st33;
	goto st0;
st33:
	if ( ++p == pe )
		goto _test_eof33;
case 33:
	if ( (*p) == 58 )
		goto st36;
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st34;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st34;
	} else
		goto st34;
	goto st0;
st34:
	if ( ++p == pe )
		goto _test_eof34;
case 34:
	if ( (*p) == 58 )
		goto st36;
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st35;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st35;
	} else
		goto st35;
	goto st0;
st35:
	if ( ++p == pe )
		goto _test_eof35;
case 35:
	if ( (*p) == 58 )
		goto st36;
	goto st0;
st36:
	if ( ++p == pe )
		goto _test_eof36;
case 36:
	if ( (*p) == 58 )
		goto st96;
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st37;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st37;
	} else
		goto st37;
	goto st0;
st37:
	if ( ++p == pe )
		goto _test_eof37;
case 37:
	if ( (*p) == 58 )
		goto st41;
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st38;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st38;
	} else
		goto st38;
	goto st0;
st38:
	if ( ++p == pe )
		goto _test_eof38;
case 38:
	if ( (*p) == 58 )
		goto st41;
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st39;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st39;
	} else
		goto st39;
	goto st0;
st39:
	if ( ++p == pe )
		goto _test_eof39;
case 39:
	if ( (*p) == 58 )
		goto st41;
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st40;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st40;
	} else
		goto st40;
	goto st0;
st40:
	if ( ++p == pe )
		goto _test_eof40;
case 40:
	if ( (*p) == 58 )
		goto st41;
	goto st0;
st41:
	if ( ++p == pe )
		goto _test_eof41;
case 41:
	if ( (*p) == 58 )
		goto st82;
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st42;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st42;
	} else
		goto st42;
	goto st0;
st42:
	if ( ++p == pe )
		goto _test_eof42;
case 42:
	if ( (*p) == 58 )
		goto st46;
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st43;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st43;
	} else
		goto st43;
	goto st0;
st43:
	if ( ++p == pe )
		goto _test_eof43;
case 43:
	if ( (*p) == 58 )
		goto st46;
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st44;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st44;
	} else
		goto st44;
	goto st0;
st44:
	if ( ++p == pe )
		goto _test_eof44;
case 44:
	if ( (*p) == 58 )
		goto st46;
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st45;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st45;
	} else
		goto st45;
	goto st0;
st45:
	if ( ++p == pe )
		goto _test_eof45;
case 45:
	if ( (*p) == 58 )
		goto st46;
	goto st0;
st46:
	if ( ++p == pe )
		goto _test_eof46;
case 46:
	switch( (*p) ) {
		case 48: goto st47;
		case 49: goto st73;
		case 50: goto st76;
		case 58: goto st80;
	}
	if ( (*p) < 65 ) {
		if ( 51 <= (*p) && (*p) <= 57 )
			goto st79;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st81;
	} else
		goto st81;
	goto st0;
st47:
	if ( ++p == pe )
		goto _test_eof47;
case 47:
	switch( (*p) ) {
		case 46: goto st48;
		case 58: goto st69;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st66;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st66;
	} else
		goto st66;
	goto st0;
st48:
	if ( ++p == pe )
		goto _test_eof48;
case 48:
	switch( (*p) ) {
		case 48: goto st49;
		case 49: goto st62;
		case 50: goto st64;
	}
	if ( 51 <= (*p) && (*p) <= 57 )
		goto st63;
	goto st0;
st49:
	if ( ++p == pe )
		goto _test_eof49;
case 49:
	if ( (*p) == 46 )
		goto st50;
	goto st0;
st50:
	if ( ++p == pe )
		goto _test_eof50;
case 50:
	switch( (*p) ) {
		case 48: goto st51;
		case 49: goto st58;
		case 50: goto st60;
	}
	if ( 51 <= (*p) && (*p) <= 57 )
		goto st59;
	goto st0;
st51:
	if ( ++p == pe )
		goto _test_eof51;
case 51:
	if ( (*p) == 46 )
		goto st52;
	goto st0;
st52:
	if ( ++p == pe )
		goto _test_eof52;
case 52:
	switch( (*p) ) {
		case 48: goto st53;
		case 49: goto st54;
		case 50: goto st56;
	}
	if ( 51 <= (*p) && (*p) <= 57 )
		goto st55;
	goto st0;
st53:
	if ( ++p == pe )
		goto _test_eof53;
case 53:
	if ( (*p) == 93 )
		goto st186;
	goto st0;
st186:
	if ( ++p == pe )
		goto _test_eof186;
case 186:
	switch( (*p) ) {
		case 35: goto tr205;
		case 47: goto tr207;
		case 58: goto tr218;
		case 63: goto tr209;
	}
	goto st0;
st54:
	if ( ++p == pe )
		goto _test_eof54;
case 54:
	if ( (*p) == 93 )
		goto st186;
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st55;
	goto st0;
st55:
	if ( ++p == pe )
		goto _test_eof55;
case 55:
	if ( (*p) == 93 )
		goto st186;
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st53;
	goto st0;
st56:
	if ( ++p == pe )
		goto _test_eof56;
case 56:
	switch( (*p) ) {
		case 53: goto st57;
		case 93: goto st186;
	}
	if ( (*p) > 52 ) {
		if ( 54 <= (*p) && (*p) <= 57 )
			goto st53;
	} else if ( (*p) >= 48 )
		goto st55;
	goto st0;
st57:
	if ( ++p == pe )
		goto _test_eof57;
case 57:
	if ( (*p) == 93 )
		goto st186;
	if ( 48 <= (*p) && (*p) <= 53 )
		goto st53;
	goto st0;
st58:
	if ( ++p == pe )
		goto _test_eof58;
case 58:
	if ( (*p) == 46 )
		goto st52;
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st59;
	goto st0;
st59:
	if ( ++p == pe )
		goto _test_eof59;
case 59:
	if ( (*p) == 46 )
		goto st52;
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st51;
	goto st0;
st60:
	if ( ++p == pe )
		goto _test_eof60;
case 60:
	switch( (*p) ) {
		case 46: goto st52;
		case 53: goto st61;
	}
	if ( (*p) > 52 ) {
		if ( 54 <= (*p) && (*p) <= 57 )
			goto st51;
	} else if ( (*p) >= 48 )
		goto st59;
	goto st0;
st61:
	if ( ++p == pe )
		goto _test_eof61;
case 61:
	if ( (*p) == 46 )
		goto st52;
	if ( 48 <= (*p) && (*p) <= 53 )
		goto st51;
	goto st0;
st62:
	if ( ++p == pe )
		goto _test_eof62;
case 62:
	if ( (*p) == 46 )
		goto st50;
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st63;
	goto st0;
st63:
	if ( ++p == pe )
		goto _test_eof63;
case 63:
	if ( (*p) == 46 )
		goto st50;
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st49;
	goto st0;
st64:
	if ( ++p == pe )
		goto _test_eof64;
case 64:
	switch( (*p) ) {
		case 46: goto st50;
		case 53: goto st65;
	}
	if ( (*p) > 52 ) {
		if ( 54 <= (*p) && (*p) <= 57 )
			goto st49;
	} else if ( (*p) >= 48 )
		goto st63;
	goto st0;
st65:
	if ( ++p == pe )
		goto _test_eof65;
case 65:
	if ( (*p) == 46 )
		goto st50;
	if ( 48 <= (*p) && (*p) <= 53 )
		goto st49;
	goto st0;
st66:
	if ( ++p == pe )
		goto _test_eof66;
case 66:
	if ( (*p) == 58 )
		goto st69;
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st67;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st67;
	} else
		goto st67;
	goto st0;
st67:
	if ( ++p == pe )
		goto _test_eof67;
case 67:
	if ( (*p) == 58 )
		goto st69;
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st68;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st68;
	} else
		goto st68;
	goto st0;
st68:
	if ( ++p == pe )
		goto _test_eof68;
case 68:
	if ( (*p) == 58 )
		goto st69;
	goto st0;
st69:
	if ( ++p == pe )
		goto _test_eof69;
case 69:
	if ( (*p) == 58 )
		goto st53;
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st70;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st70;
	} else
		goto st70;
	goto st0;
st70:
	if ( ++p == pe )
		goto _test_eof70;
case 70:
	if ( (*p) == 93 )
		goto st186;
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st71;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st71;
	} else
		goto st71;
	goto st0;
st71:
	if ( ++p == pe )
		goto _test_eof71;
case 71:
	if ( (*p) == 93 )
		goto st186;
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st72;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st72;
	} else
		goto st72;
	goto st0;
st72:
	if ( ++p == pe )
		goto _test_eof72;
case 72:
	if ( (*p) == 93 )
		goto st186;
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st53;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st53;
	} else
		goto st53;
	goto st0;
st73:
	if ( ++p == pe )
		goto _test_eof73;
case 73:
	switch( (*p) ) {
		case 46: goto st48;
		case 58: goto st69;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st74;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st66;
	} else
		goto st66;
	goto st0;
st74:
	if ( ++p == pe )
		goto _test_eof74;
case 74:
	switch( (*p) ) {
		case 46: goto st48;
		case 58: goto st69;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st75;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st67;
	} else
		goto st67;
	goto st0;
st75:
	if ( ++p == pe )
		goto _test_eof75;
case 75:
	switch( (*p) ) {
		case 46: goto st48;
		case 58: goto st69;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st68;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st68;
	} else
		goto st68;
	goto st0;
st76:
	if ( ++p == pe )
		goto _test_eof76;
case 76:
	switch( (*p) ) {
		case 46: goto st48;
		case 53: goto st77;
		case 58: goto st69;
	}
	if ( (*p) < 54 ) {
		if ( 48 <= (*p) && (*p) <= 52 )
			goto st74;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto st66;
		} else if ( (*p) >= 65 )
			goto st66;
	} else
		goto st78;
	goto st0;
st77:
	if ( ++p == pe )
		goto _test_eof77;
case 77:
	switch( (*p) ) {
		case 46: goto st48;
		case 58: goto st69;
	}
	if ( (*p) < 54 ) {
		if ( 48 <= (*p) && (*p) <= 53 )
			goto st75;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto st67;
		} else if ( (*p) >= 65 )
			goto st67;
	} else
		goto st67;
	goto st0;
st78:
	if ( ++p == pe )
		goto _test_eof78;
case 78:
	switch( (*p) ) {
		case 46: goto st48;
		case 58: goto st69;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st67;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st67;
	} else
		goto st67;
	goto st0;
st79:
	if ( ++p == pe )
		goto _test_eof79;
case 79:
	switch( (*p) ) {
		case 46: goto st48;
		case 58: goto st69;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st78;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st66;
	} else
		goto st66;
	goto st0;
st80:
	if ( ++p == pe )
		goto _test_eof80;
case 80:
	if ( (*p) == 93 )
		goto st186;
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st70;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st70;
	} else
		goto st70;
	goto st0;
st81:
	if ( ++p == pe )
		goto _test_eof81;
case 81:
	if ( (*p) == 58 )
		goto st69;
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st66;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st66;
	} else
		goto st66;
	goto st0;
st82:
	if ( ++p == pe )
		goto _test_eof82;
case 82:
	switch( (*p) ) {
		case 48: goto st83;
		case 49: goto st88;
		case 50: goto st91;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 51 <= (*p) && (*p) <= 57 )
			goto st94;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st95;
	} else
		goto st95;
	goto st0;
st83:
	if ( ++p == pe )
		goto _test_eof83;
case 83:
	switch( (*p) ) {
		case 46: goto st48;
		case 58: goto st87;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st84;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st84;
	} else
		goto st84;
	goto st0;
st84:
	if ( ++p == pe )
		goto _test_eof84;
case 84:
	switch( (*p) ) {
		case 58: goto st87;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st85;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st85;
	} else
		goto st85;
	goto st0;
st85:
	if ( ++p == pe )
		goto _test_eof85;
case 85:
	switch( (*p) ) {
		case 58: goto st87;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st86;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st86;
	} else
		goto st86;
	goto st0;
st86:
	if ( ++p == pe )
		goto _test_eof86;
case 86:
	switch( (*p) ) {
		case 58: goto st87;
		case 93: goto st186;
	}
	goto st0;
st87:
	if ( ++p == pe )
		goto _test_eof87;
case 87:
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st70;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st70;
	} else
		goto st70;
	goto st0;
st88:
	if ( ++p == pe )
		goto _test_eof88;
case 88:
	switch( (*p) ) {
		case 46: goto st48;
		case 58: goto st87;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st89;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st84;
	} else
		goto st84;
	goto st0;
st89:
	if ( ++p == pe )
		goto _test_eof89;
case 89:
	switch( (*p) ) {
		case 46: goto st48;
		case 58: goto st87;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st90;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st85;
	} else
		goto st85;
	goto st0;
st90:
	if ( ++p == pe )
		goto _test_eof90;
case 90:
	switch( (*p) ) {
		case 46: goto st48;
		case 58: goto st87;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st86;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st86;
	} else
		goto st86;
	goto st0;
st91:
	if ( ++p == pe )
		goto _test_eof91;
case 91:
	switch( (*p) ) {
		case 46: goto st48;
		case 53: goto st92;
		case 58: goto st87;
		case 93: goto st186;
	}
	if ( (*p) < 54 ) {
		if ( 48 <= (*p) && (*p) <= 52 )
			goto st89;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto st84;
		} else if ( (*p) >= 65 )
			goto st84;
	} else
		goto st93;
	goto st0;
st92:
	if ( ++p == pe )
		goto _test_eof92;
case 92:
	switch( (*p) ) {
		case 46: goto st48;
		case 58: goto st87;
		case 93: goto st186;
	}
	if ( (*p) < 54 ) {
		if ( 48 <= (*p) && (*p) <= 53 )
			goto st90;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto st85;
		} else if ( (*p) >= 65 )
			goto st85;
	} else
		goto st85;
	goto st0;
st93:
	if ( ++p == pe )
		goto _test_eof93;
case 93:
	switch( (*p) ) {
		case 46: goto st48;
		case 58: goto st87;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st85;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st85;
	} else
		goto st85;
	goto st0;
st94:
	if ( ++p == pe )
		goto _test_eof94;
case 94:
	switch( (*p) ) {
		case 46: goto st48;
		case 58: goto st87;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st93;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st84;
	} else
		goto st84;
	goto st0;
st95:
	if ( ++p == pe )
		goto _test_eof95;
case 95:
	switch( (*p) ) {
		case 58: goto st87;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st84;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st84;
	} else
		goto st84;
	goto st0;
st96:
	if ( ++p == pe )
		goto _test_eof96;
case 96:
	switch( (*p) ) {
		case 48: goto st97;
		case 49: goto st102;
		case 50: goto st105;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 51 <= (*p) && (*p) <= 57 )
			goto st108;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st109;
	} else
		goto st109;
	goto st0;
st97:
	if ( ++p == pe )
		goto _test_eof97;
case 97:
	switch( (*p) ) {
		case 46: goto st48;
		case 58: goto st101;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st98;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st98;
	} else
		goto st98;
	goto st0;
st98:
	if ( ++p == pe )
		goto _test_eof98;
case 98:
	switch( (*p) ) {
		case 58: goto st101;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st99;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st99;
	} else
		goto st99;
	goto st0;
st99:
	if ( ++p == pe )
		goto _test_eof99;
case 99:
	switch( (*p) ) {
		case 58: goto st101;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st100;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st100;
	} else
		goto st100;
	goto st0;
st100:
	if ( ++p == pe )
		goto _test_eof100;
case 100:
	switch( (*p) ) {
		case 58: goto st101;
		case 93: goto st186;
	}
	goto st0;
st101:
	if ( ++p == pe )
		goto _test_eof101;
case 101:
	switch( (*p) ) {
		case 48: goto st83;
		case 49: goto st88;
		case 50: goto st91;
	}
	if ( (*p) < 65 ) {
		if ( 51 <= (*p) && (*p) <= 57 )
			goto st94;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st95;
	} else
		goto st95;
	goto st0;
st102:
	if ( ++p == pe )
		goto _test_eof102;
case 102:
	switch( (*p) ) {
		case 46: goto st48;
		case 58: goto st101;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st103;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st98;
	} else
		goto st98;
	goto st0;
st103:
	if ( ++p == pe )
		goto _test_eof103;
case 103:
	switch( (*p) ) {
		case 46: goto st48;
		case 58: goto st101;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st104;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st99;
	} else
		goto st99;
	goto st0;
st104:
	if ( ++p == pe )
		goto _test_eof104;
case 104:
	switch( (*p) ) {
		case 46: goto st48;
		case 58: goto st101;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st100;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st100;
	} else
		goto st100;
	goto st0;
st105:
	if ( ++p == pe )
		goto _test_eof105;
case 105:
	switch( (*p) ) {
		case 46: goto st48;
		case 53: goto st106;
		case 58: goto st101;
		case 93: goto st186;
	}
	if ( (*p) < 54 ) {
		if ( 48 <= (*p) && (*p) <= 52 )
			goto st103;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto st98;
		} else if ( (*p) >= 65 )
			goto st98;
	} else
		goto st107;
	goto st0;
st106:
	if ( ++p == pe )
		goto _test_eof106;
case 106:
	switch( (*p) ) {
		case 46: goto st48;
		case 58: goto st101;
		case 93: goto st186;
	}
	if ( (*p) < 54 ) {
		if ( 48 <= (*p) && (*p) <= 53 )
			goto st104;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto st99;
		} else if ( (*p) >= 65 )
			goto st99;
	} else
		goto st99;
	goto st0;
st107:
	if ( ++p == pe )
		goto _test_eof107;
case 107:
	switch( (*p) ) {
		case 46: goto st48;
		case 58: goto st101;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st99;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st99;
	} else
		goto st99;
	goto st0;
st108:
	if ( ++p == pe )
		goto _test_eof108;
case 108:
	switch( (*p) ) {
		case 46: goto st48;
		case 58: goto st101;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st107;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st98;
	} else
		goto st98;
	goto st0;
st109:
	if ( ++p == pe )
		goto _test_eof109;
case 109:
	switch( (*p) ) {
		case 58: goto st101;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st98;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st98;
	} else
		goto st98;
	goto st0;
st110:
	if ( ++p == pe )
		goto _test_eof110;
case 110:
	switch( (*p) ) {
		case 48: goto st111;
		case 49: goto st116;
		case 50: goto st119;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 51 <= (*p) && (*p) <= 57 )
			goto st122;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st123;
	} else
		goto st123;
	goto st0;
st111:
	if ( ++p == pe )
		goto _test_eof111;
case 111:
	switch( (*p) ) {
		case 46: goto st48;
		case 58: goto st115;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st112;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st112;
	} else
		goto st112;
	goto st0;
st112:
	if ( ++p == pe )
		goto _test_eof112;
case 112:
	switch( (*p) ) {
		case 58: goto st115;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st113;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st113;
	} else
		goto st113;
	goto st0;
st113:
	if ( ++p == pe )
		goto _test_eof113;
case 113:
	switch( (*p) ) {
		case 58: goto st115;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st114;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st114;
	} else
		goto st114;
	goto st0;
st114:
	if ( ++p == pe )
		goto _test_eof114;
case 114:
	switch( (*p) ) {
		case 58: goto st115;
		case 93: goto st186;
	}
	goto st0;
st115:
	if ( ++p == pe )
		goto _test_eof115;
case 115:
	switch( (*p) ) {
		case 48: goto st97;
		case 49: goto st102;
		case 50: goto st105;
	}
	if ( (*p) < 65 ) {
		if ( 51 <= (*p) && (*p) <= 57 )
			goto st108;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st109;
	} else
		goto st109;
	goto st0;
st116:
	if ( ++p == pe )
		goto _test_eof116;
case 116:
	switch( (*p) ) {
		case 46: goto st48;
		case 58: goto st115;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st117;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st112;
	} else
		goto st112;
	goto st0;
st117:
	if ( ++p == pe )
		goto _test_eof117;
case 117:
	switch( (*p) ) {
		case 46: goto st48;
		case 58: goto st115;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st118;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st113;
	} else
		goto st113;
	goto st0;
st118:
	if ( ++p == pe )
		goto _test_eof118;
case 118:
	switch( (*p) ) {
		case 46: goto st48;
		case 58: goto st115;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st114;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st114;
	} else
		goto st114;
	goto st0;
st119:
	if ( ++p == pe )
		goto _test_eof119;
case 119:
	switch( (*p) ) {
		case 46: goto st48;
		case 53: goto st120;
		case 58: goto st115;
		case 93: goto st186;
	}
	if ( (*p) < 54 ) {
		if ( 48 <= (*p) && (*p) <= 52 )
			goto st117;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto st112;
		} else if ( (*p) >= 65 )
			goto st112;
	} else
		goto st121;
	goto st0;
st120:
	if ( ++p == pe )
		goto _test_eof120;
case 120:
	switch( (*p) ) {
		case 46: goto st48;
		case 58: goto st115;
		case 93: goto st186;
	}
	if ( (*p) < 54 ) {
		if ( 48 <= (*p) && (*p) <= 53 )
			goto st118;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto st113;
		} else if ( (*p) >= 65 )
			goto st113;
	} else
		goto st113;
	goto st0;
st121:
	if ( ++p == pe )
		goto _test_eof121;
case 121:
	switch( (*p) ) {
		case 46: goto st48;
		case 58: goto st115;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st113;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st113;
	} else
		goto st113;
	goto st0;
st122:
	if ( ++p == pe )
		goto _test_eof122;
case 122:
	switch( (*p) ) {
		case 46: goto st48;
		case 58: goto st115;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st121;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st112;
	} else
		goto st112;
	goto st0;
st123:
	if ( ++p == pe )
		goto _test_eof123;
case 123:
	switch( (*p) ) {
		case 58: goto st115;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st112;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st112;
	} else
		goto st112;
	goto st0;
st124:
	if ( ++p == pe )
		goto _test_eof124;
case 124:
	switch( (*p) ) {
		case 48: goto st125;
		case 49: goto st130;
		case 50: goto st133;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 51 <= (*p) && (*p) <= 57 )
			goto st136;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st137;
	} else
		goto st137;
	goto st0;
st125:
	if ( ++p == pe )
		goto _test_eof125;
case 125:
	switch( (*p) ) {
		case 46: goto st48;
		case 58: goto st129;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st126;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st126;
	} else
		goto st126;
	goto st0;
st126:
	if ( ++p == pe )
		goto _test_eof126;
case 126:
	switch( (*p) ) {
		case 58: goto st129;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st127;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st127;
	} else
		goto st127;
	goto st0;
st127:
	if ( ++p == pe )
		goto _test_eof127;
case 127:
	switch( (*p) ) {
		case 58: goto st129;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st128;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st128;
	} else
		goto st128;
	goto st0;
st128:
	if ( ++p == pe )
		goto _test_eof128;
case 128:
	switch( (*p) ) {
		case 58: goto st129;
		case 93: goto st186;
	}
	goto st0;
st129:
	if ( ++p == pe )
		goto _test_eof129;
case 129:
	switch( (*p) ) {
		case 48: goto st111;
		case 49: goto st116;
		case 50: goto st119;
	}
	if ( (*p) < 65 ) {
		if ( 51 <= (*p) && (*p) <= 57 )
			goto st122;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st123;
	} else
		goto st123;
	goto st0;
st130:
	if ( ++p == pe )
		goto _test_eof130;
case 130:
	switch( (*p) ) {
		case 46: goto st48;
		case 58: goto st129;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st131;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st126;
	} else
		goto st126;
	goto st0;
st131:
	if ( ++p == pe )
		goto _test_eof131;
case 131:
	switch( (*p) ) {
		case 46: goto st48;
		case 58: goto st129;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st132;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st127;
	} else
		goto st127;
	goto st0;
st132:
	if ( ++p == pe )
		goto _test_eof132;
case 132:
	switch( (*p) ) {
		case 46: goto st48;
		case 58: goto st129;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st128;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st128;
	} else
		goto st128;
	goto st0;
st133:
	if ( ++p == pe )
		goto _test_eof133;
case 133:
	switch( (*p) ) {
		case 46: goto st48;
		case 53: goto st134;
		case 58: goto st129;
		case 93: goto st186;
	}
	if ( (*p) < 54 ) {
		if ( 48 <= (*p) && (*p) <= 52 )
			goto st131;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto st126;
		} else if ( (*p) >= 65 )
			goto st126;
	} else
		goto st135;
	goto st0;
st134:
	if ( ++p == pe )
		goto _test_eof134;
case 134:
	switch( (*p) ) {
		case 46: goto st48;
		case 58: goto st129;
		case 93: goto st186;
	}
	if ( (*p) < 54 ) {
		if ( 48 <= (*p) && (*p) <= 53 )
			goto st132;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto st127;
		} else if ( (*p) >= 65 )
			goto st127;
	} else
		goto st127;
	goto st0;
st135:
	if ( ++p == pe )
		goto _test_eof135;
case 135:
	switch( (*p) ) {
		case 46: goto st48;
		case 58: goto st129;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st127;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st127;
	} else
		goto st127;
	goto st0;
st136:
	if ( ++p == pe )
		goto _test_eof136;
case 136:
	switch( (*p) ) {
		case 46: goto st48;
		case 58: goto st129;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st135;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st126;
	} else
		goto st126;
	goto st0;
st137:
	if ( ++p == pe )
		goto _test_eof137;
case 137:
	switch( (*p) ) {
		case 58: goto st129;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st126;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st126;
	} else
		goto st126;
	goto st0;
st138:
	if ( ++p == pe )
		goto _test_eof138;
case 138:
	switch( (*p) ) {
		case 48: goto st139;
		case 49: goto st144;
		case 50: goto st147;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 51 <= (*p) && (*p) <= 57 )
			goto st150;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st151;
	} else
		goto st151;
	goto st0;
st139:
	if ( ++p == pe )
		goto _test_eof139;
case 139:
	switch( (*p) ) {
		case 46: goto st48;
		case 58: goto st143;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st140;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st140;
	} else
		goto st140;
	goto st0;
st140:
	if ( ++p == pe )
		goto _test_eof140;
case 140:
	switch( (*p) ) {
		case 58: goto st143;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st141;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st141;
	} else
		goto st141;
	goto st0;
st141:
	if ( ++p == pe )
		goto _test_eof141;
case 141:
	switch( (*p) ) {
		case 58: goto st143;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st142;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st142;
	} else
		goto st142;
	goto st0;
st142:
	if ( ++p == pe )
		goto _test_eof142;
case 142:
	switch( (*p) ) {
		case 58: goto st143;
		case 93: goto st186;
	}
	goto st0;
st143:
	if ( ++p == pe )
		goto _test_eof143;
case 143:
	switch( (*p) ) {
		case 48: goto st125;
		case 49: goto st130;
		case 50: goto st133;
	}
	if ( (*p) < 65 ) {
		if ( 51 <= (*p) && (*p) <= 57 )
			goto st136;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st137;
	} else
		goto st137;
	goto st0;
st144:
	if ( ++p == pe )
		goto _test_eof144;
case 144:
	switch( (*p) ) {
		case 46: goto st48;
		case 58: goto st143;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st145;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st140;
	} else
		goto st140;
	goto st0;
st145:
	if ( ++p == pe )
		goto _test_eof145;
case 145:
	switch( (*p) ) {
		case 46: goto st48;
		case 58: goto st143;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st146;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st141;
	} else
		goto st141;
	goto st0;
st146:
	if ( ++p == pe )
		goto _test_eof146;
case 146:
	switch( (*p) ) {
		case 46: goto st48;
		case 58: goto st143;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st142;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st142;
	} else
		goto st142;
	goto st0;
st147:
	if ( ++p == pe )
		goto _test_eof147;
case 147:
	switch( (*p) ) {
		case 46: goto st48;
		case 53: goto st148;
		case 58: goto st143;
		case 93: goto st186;
	}
	if ( (*p) < 54 ) {
		if ( 48 <= (*p) && (*p) <= 52 )
			goto st145;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto st140;
		} else if ( (*p) >= 65 )
			goto st140;
	} else
		goto st149;
	goto st0;
st148:
	if ( ++p == pe )
		goto _test_eof148;
case 148:
	switch( (*p) ) {
		case 46: goto st48;
		case 58: goto st143;
		case 93: goto st186;
	}
	if ( (*p) < 54 ) {
		if ( 48 <= (*p) && (*p) <= 53 )
			goto st146;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto st141;
		} else if ( (*p) >= 65 )
			goto st141;
	} else
		goto st141;
	goto st0;
st149:
	if ( ++p == pe )
		goto _test_eof149;
case 149:
	switch( (*p) ) {
		case 46: goto st48;
		case 58: goto st143;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st141;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st141;
	} else
		goto st141;
	goto st0;
st150:
	if ( ++p == pe )
		goto _test_eof150;
case 150:
	switch( (*p) ) {
		case 46: goto st48;
		case 58: goto st143;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st149;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st140;
	} else
		goto st140;
	goto st0;
st151:
	if ( ++p == pe )
		goto _test_eof151;
case 151:
	switch( (*p) ) {
		case 58: goto st143;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st140;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st140;
	} else
		goto st140;
	goto st0;
st152:
	if ( ++p == pe )
		goto _test_eof152;
case 152:
	if ( (*p) == 58 )
		goto st153;
	goto st0;
st153:
	if ( ++p == pe )
		goto _test_eof153;
case 153:
	switch( (*p) ) {
		case 48: goto st154;
		case 49: goto st159;
		case 50: goto st162;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 51 <= (*p) && (*p) <= 57 )
			goto st165;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st166;
	} else
		goto st166;
	goto st0;
st154:
	if ( ++p == pe )
		goto _test_eof154;
case 154:
	switch( (*p) ) {
		case 46: goto st48;
		case 58: goto st158;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st155;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st155;
	} else
		goto st155;
	goto st0;
st155:
	if ( ++p == pe )
		goto _test_eof155;
case 155:
	switch( (*p) ) {
		case 58: goto st158;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st156;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st156;
	} else
		goto st156;
	goto st0;
st156:
	if ( ++p == pe )
		goto _test_eof156;
case 156:
	switch( (*p) ) {
		case 58: goto st158;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st157;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st157;
	} else
		goto st157;
	goto st0;
st157:
	if ( ++p == pe )
		goto _test_eof157;
case 157:
	switch( (*p) ) {
		case 58: goto st158;
		case 93: goto st186;
	}
	goto st0;
st158:
	if ( ++p == pe )
		goto _test_eof158;
case 158:
	switch( (*p) ) {
		case 48: goto st139;
		case 49: goto st144;
		case 50: goto st147;
	}
	if ( (*p) < 65 ) {
		if ( 51 <= (*p) && (*p) <= 57 )
			goto st150;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st151;
	} else
		goto st151;
	goto st0;
st159:
	if ( ++p == pe )
		goto _test_eof159;
case 159:
	switch( (*p) ) {
		case 46: goto st48;
		case 58: goto st158;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st160;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st155;
	} else
		goto st155;
	goto st0;
st160:
	if ( ++p == pe )
		goto _test_eof160;
case 160:
	switch( (*p) ) {
		case 46: goto st48;
		case 58: goto st158;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st161;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st156;
	} else
		goto st156;
	goto st0;
st161:
	if ( ++p == pe )
		goto _test_eof161;
case 161:
	switch( (*p) ) {
		case 46: goto st48;
		case 58: goto st158;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st157;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st157;
	} else
		goto st157;
	goto st0;
st162:
	if ( ++p == pe )
		goto _test_eof162;
case 162:
	switch( (*p) ) {
		case 46: goto st48;
		case 53: goto st163;
		case 58: goto st158;
		case 93: goto st186;
	}
	if ( (*p) < 54 ) {
		if ( 48 <= (*p) && (*p) <= 52 )
			goto st160;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto st155;
		} else if ( (*p) >= 65 )
			goto st155;
	} else
		goto st164;
	goto st0;
st163:
	if ( ++p == pe )
		goto _test_eof163;
case 163:
	switch( (*p) ) {
		case 46: goto st48;
		case 58: goto st158;
		case 93: goto st186;
	}
	if ( (*p) < 54 ) {
		if ( 48 <= (*p) && (*p) <= 53 )
			goto st161;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 70 ) {
			if ( 97 <= (*p) && (*p) <= 102 )
				goto st156;
		} else if ( (*p) >= 65 )
			goto st156;
	} else
		goto st156;
	goto st0;
st164:
	if ( ++p == pe )
		goto _test_eof164;
case 164:
	switch( (*p) ) {
		case 46: goto st48;
		case 58: goto st158;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st156;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st156;
	} else
		goto st156;
	goto st0;
st165:
	if ( ++p == pe )
		goto _test_eof165;
case 165:
	switch( (*p) ) {
		case 46: goto st48;
		case 58: goto st158;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st164;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st155;
	} else
		goto st155;
	goto st0;
st166:
	if ( ++p == pe )
		goto _test_eof166;
case 166:
	switch( (*p) ) {
		case 58: goto st158;
		case 93: goto st186;
	}
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st155;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st155;
	} else
		goto st155;
	goto st0;
st167:
	if ( ++p == pe )
		goto _test_eof167;
case 167:
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st168;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st168;
	} else
		goto st168;
	goto st0;
st168:
	if ( ++p == pe )
		goto _test_eof168;
case 168:
	if ( (*p) == 46 )
		goto st169;
	if ( (*p) < 65 ) {
		if ( 48 <= (*p) && (*p) <= 57 )
			goto st168;
	} else if ( (*p) > 70 ) {
		if ( 97 <= (*p) && (*p) <= 102 )
			goto st168;
	} else
		goto st168;
	goto st0;
st169:
	if ( ++p == pe )
		goto _test_eof169;
case 169:
	switch( (*p) ) {
		case 33: goto st170;
		case 36: goto st170;
		case 61: goto st170;
		case 95: goto st170;
		case 126: goto st170;
	}
	if ( (*p) < 48 ) {
		if ( 38 <= (*p) && (*p) <= 46 )
			goto st170;
	} else if ( (*p) > 59 ) {
		if ( (*p) > 90 ) {
			if ( 97 <= (*p) && (*p) <= 122 )
				goto st170;
		} else if ( (*p) >= 65 )
			goto st170;
	} else
		goto st170;
	goto st0;
st170:
	if ( ++p == pe )
		goto _test_eof170;
case 170:
	switch( (*p) ) {
		case 33: goto st170;
		case 36: goto st170;
		case 61: goto st170;
		case 93: goto st186;
		case 95: goto st170;
		case 126: goto st170;
	}
	if ( (*p) < 48 ) {
		if ( 38 <= (*p) && (*p) <= 46 )
			goto st170;
	} else if ( (*p) > 59 ) {
		if ( (*p) > 90 ) {
			if ( 97 <= (*p) && (*p) <= 122 )
				goto st170;
		} else if ( (*p) >= 65 )
			goto st170;
	} else
		goto st170;
	goto st0;
tr177:
#line 10 "src/panda/uri/parser.rl"
	{
        mark = p - ps;
    }
	goto st187;
st187:
	if ( ++p == pe )
		goto _test_eof187;
case 187:
#line 3351 "src/panda/uri/parser_ext.cc"
	switch( (*p) ) {
		case 33: goto st172;
		case 35: goto tr178;
		case 37: goto st3;
		case 43: goto st187;
		case 47: goto st175;
		case 58: goto tr221;
		case 59: goto st172;
		case 61: goto st172;
		case 63: goto tr180;
		case 64: goto st172;
		case 95: goto st172;
		case 126: goto st172;
	}
	if ( (*p) < 45 ) {
		if ( 36 <= (*p) && (*p) <= 44 )
			goto st172;
	} else if ( (*p) > 57 ) {
		if ( (*p) > 90 ) {
			if ( 97 <= (*p) && (*p) <= 122 )
				goto st187;
		} else if ( (*p) >= 65 )
			goto st187;
	} else
		goto st187;
	goto st0;
tr221:
#line 19 "src/panda/uri/parser.rl"
	{ SAVE(_scheme); }
	goto st188;
st188:
	if ( ++p == pe )
		goto _test_eof188;
case 188:
#line 3386 "src/panda/uri/parser_ext.cc"
	switch( (*p) ) {
		case 33: goto tr222;
		case 35: goto st173;
		case 37: goto tr223;
		case 47: goto tr175;
		case 61: goto tr222;
		case 63: goto st176;
		case 95: goto tr222;
		case 126: goto tr222;
	}
	if ( (*p) < 64 ) {
		if ( 36 <= (*p) && (*p) <= 59 )
			goto tr222;
	} else if ( (*p) > 90 ) {
		if ( 97 <= (*p) && (*p) <= 122 )
			goto tr222;
	} else
		goto tr222;
	goto st0;
	}
	_test_eof172: cs = 172; goto _test_eof; 
	_test_eof173: cs = 173; goto _test_eof; 
	_test_eof174: cs = 174; goto _test_eof; 
	_test_eof1: cs = 1; goto _test_eof; 
	_test_eof2: cs = 2; goto _test_eof; 
	_test_eof3: cs = 3; goto _test_eof; 
	_test_eof4: cs = 4; goto _test_eof; 
	_test_eof175: cs = 175; goto _test_eof; 
	_test_eof5: cs = 5; goto _test_eof; 
	_test_eof6: cs = 6; goto _test_eof; 
	_test_eof176: cs = 176; goto _test_eof; 
	_test_eof177: cs = 177; goto _test_eof; 
	_test_eof178: cs = 178; goto _test_eof; 
	_test_eof7: cs = 7; goto _test_eof; 
	_test_eof8: cs = 8; goto _test_eof; 
	_test_eof179: cs = 179; goto _test_eof; 
	_test_eof180: cs = 180; goto _test_eof; 
	_test_eof181: cs = 181; goto _test_eof; 
	_test_eof9: cs = 9; goto _test_eof; 
	_test_eof10: cs = 10; goto _test_eof; 
	_test_eof182: cs = 182; goto _test_eof; 
	_test_eof11: cs = 11; goto _test_eof; 
	_test_eof12: cs = 12; goto _test_eof; 
	_test_eof13: cs = 13; goto _test_eof; 
	_test_eof183: cs = 183; goto _test_eof; 
	_test_eof184: cs = 184; goto _test_eof; 
	_test_eof14: cs = 14; goto _test_eof; 
	_test_eof15: cs = 15; goto _test_eof; 
	_test_eof185: cs = 185; goto _test_eof; 
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
	_test_eof186: cs = 186; goto _test_eof; 
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
	_test_eof65: cs = 65; goto _test_eof; 
	_test_eof66: cs = 66; goto _test_eof; 
	_test_eof67: cs = 67; goto _test_eof; 
	_test_eof68: cs = 68; goto _test_eof; 
	_test_eof69: cs = 69; goto _test_eof; 
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
	_test_eof170: cs = 170; goto _test_eof; 
	_test_eof187: cs = 187; goto _test_eof; 
	_test_eof188: cs = 188; goto _test_eof; 

	_test_eof: {}
	if ( p == eof )
	{
	switch ( cs ) {
	case 172: 
	case 175: 
	case 179: 
	case 187: 
#line 23 "src/panda/uri/parser.rl"
	{ SAVE(_path); }
	break;
	case 177: 
#line 24 "src/panda/uri/parser.rl"
	{ SAVE(_qstr); }
	break;
	case 174: 
#line 25 "src/panda/uri/parser.rl"
	{ SAVE(_fragment); }
	break;
	case 176: 
#line 10 "src/panda/uri/parser.rl"
	{
        mark = p - ps;
    }
#line 24 "src/panda/uri/parser.rl"
	{ SAVE(_qstr); }
	break;
	case 173: 
#line 10 "src/panda/uri/parser.rl"
	{
        mark = p - ps;
    }
#line 25 "src/panda/uri/parser.rl"
	{ SAVE(_fragment); }
	break;
	case 178: 
#line 11 "src/panda/uri/parser_ext.rl"
	{ ext_chars = true; }
#line 24 "src/panda/uri/parser.rl"
	{ SAVE(_qstr); }
	break;
	case 180: 
	case 183: 
#line 10 "src/panda/uri/parser.rl"
	{
        mark = p - ps;
    }
#line 20 "src/panda/uri/parser.rl"
	{ SAVE(_host); }
#line 23 "src/panda/uri/parser.rl"
	{ SAVE(_path); }
	break;
	case 181: 
	case 184: 
	case 186: 
#line 20 "src/panda/uri/parser.rl"
	{ SAVE(_host); }
#line 10 "src/panda/uri/parser.rl"
	{
        mark = p - ps;
    }
#line 23 "src/panda/uri/parser.rl"
	{ SAVE(_path); }
	break;
	case 182: 
	case 185: 
#line 21 "src/panda/uri/parser.rl"
	{ NSAVE(_port); }
#line 10 "src/panda/uri/parser.rl"
	{
        mark = p - ps;
    }
#line 23 "src/panda/uri/parser.rl"
	{ SAVE(_path); }
	break;
#line 3670 "src/panda/uri/parser_ext.cc"
	}
	}

	_out: {}
	}

#line 33 "src/panda/uri/parser_ext.rl"
    
    if (ext_chars) { // we must parse and invalidate source query string to produce valid uri on output
        parse_query();
        _qstr.clear();
        ok_query();
    }
    
    return cs >= uri_parser_ext_first_final;
}

}}