#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define Inline_Stack_Vars dXSARGS
#define Inline_Stack_Items items
#define Inline_Stack_Item(x) ST(x)
#define Inline_Stack_Reset sp = mark
#define Inline_Stack_Push(x) XPUSHs(x)
#define Inline_Stack_Done PUTBACK
#define Inline_Stack_Return(x) XSRETURN(x)
#define Inline_Stack_Void XSRETURN(0)

#define INLINE_STACK_VARS Inline_Stack_Vars
#define INLINE_STACK_ITEMS Inline_Stack_Items
#define INLINE_STACK_ITEM(x) Inline_Stack_Item(x)
#define INLINE_STACK_RESET Inline_Stack_Reset
#define INLINE_STACK_PUSH(x) Inline_Stack_Push(x)
#define INLINE_STACK_DONE Inline_Stack_Done
#define INLINE_STACK_RETURN(x) Inline_Stack_Return(x)
#define INLINE_STACK_VOID Inline_Stack_Void

#define inline_stack_vars Inline_Stack_Vars
#define inline_stack_items Inline_Stack_Items
#define inline_stack_item(x) Inline_Stack_Item(x)
#define inline_stack_reset Inline_Stack_Reset
#define inline_stack_push(x) Inline_Stack_Push(x)
#define inline_stack_done Inline_Stack_Done
#define inline_stack_return(x) Inline_Stack_Return(x)
#define inline_stack_void Inline_Stack_Void

#line 1 "/tmp/DIwPodyP1J/input"



#line 7 "/tmp/DIwPodyP1J/output"
static const int egc_scanner_start = 209;
static const int egc_scanner_first_final = 209;
static const int egc_scanner_error = 0;

static const int egc_scanner_en_main = 209;


#line 7 "/tmp/DIwPodyP1J/input"



static void _scan_egc(char *input, size_t len, size_t trunc_size, int *truncation_required_out, size_t *cut_len_out, int *error_occurred_out) {
  size_t cut_len = 0;
  int truncation_required = 0, error_occurred = 0;

  char *p, *pe, *eof, *ts, *te;
  int cs, act;
 
  ts = p = input;
  te = eof = pe = p + len;

  
#line 30 "/tmp/DIwPodyP1J/output"
	{
	cs = egc_scanner_start;
	ts = 0;
	te = 0;
	act = 0;
	}

#line 38 "/tmp/DIwPodyP1J/output"
	{
	if ( p == pe )
		goto _test_eof;
	switch ( cs )
	{
tr0:
#line 21 "/tmp/DIwPodyP1J/input"
	{te = p+1;{
      if (p - input >= trunc_size) {
        truncation_required = 1;
        goto done;
      }

      cut_len = te - input;
    }}
	goto st209;
tr3:
#line 21 "/tmp/DIwPodyP1J/input"
	{{p = ((te))-1;}{
      if (p - input >= trunc_size) {
        truncation_required = 1;
        goto done;
      }

      cut_len = te - input;
    }}
	goto st209;
tr189:
#line 21 "/tmp/DIwPodyP1J/input"
	{te = p;p--;{
      if (p - input >= trunc_size) {
        truncation_required = 1;
        goto done;
      }

      cut_len = te - input;
    }}
	goto st209;
tr218:
#line 21 "/tmp/DIwPodyP1J/input"
	{te = p+1;{
      if (p - input >= trunc_size) {
        truncation_required = 1;
        goto done;
      }

      cut_len = te - input;
    }}
	goto st209;
st209:
#line 1 "NONE"
	{ts = 0;}
	if ( ++p == pe )
		goto _test_eof209;
case 209:
#line 1 "NONE"
	{ts = p;}
#line 96 "/tmp/DIwPodyP1J/output"
	switch( (*p) ) {
		case -62: goto st1;
		case -40: goto st131;
		case -37: goto st132;
		case -36: goto st133;
		case -32: goto st134;
		case -31: goto st135;
		case -30: goto st170;
		case -22: goto st174;
		case -21: goto st183;
		case -20: goto st184;
		case -19: goto st185;
		case -17: goto st188;
		case -16: goto st191;
		case -13: goto st204;
		case -12: goto st208;
		case 13: goto tr188;
		case 127: goto tr0;
	}
	if ( (*p) < -15 ) {
		if ( (*p) < -61 ) {
			if ( (*p) <= -63 )
				goto st0;
		} else if ( (*p) > -33 ) {
			if ( -29 <= (*p) && (*p) <= -18 )
				goto st173;
		} else
			goto st130;
	} else if ( (*p) > -14 ) {
		if ( (*p) < 0 ) {
			if ( -11 <= (*p) && (*p) <= -1 )
				goto st0;
		} else if ( (*p) > 9 ) {
			if ( 11 <= (*p) && (*p) <= 31 )
				goto tr0;
		} else
			goto tr0;
	} else
		goto st203;
	goto tr1;
st0:
cs = 0;
	goto _out;
st1:
	if ( ++p == pe )
		goto _test_eof1;
case 1:
	if ( (*p) == -83 )
		goto tr0;
	if ( (*p) > -97 ) {
		if ( -96 <= (*p) && (*p) <= -65 )
			goto tr1;
	} else
		goto tr0;
	goto st0;
tr1:
#line 1 "NONE"
	{te = p+1;}
	goto st210;
st210:
	if ( ++p == pe )
		goto _test_eof210;
case 210:
#line 160 "/tmp/DIwPodyP1J/output"
	switch( (*p) ) {
		case -52: goto st2;
		case -51: goto st3;
		case -46: goto st4;
		case -42: goto st5;
		case -41: goto st6;
		case -40: goto st7;
		case -39: goto st8;
		case -37: goto st9;
		case -36: goto st10;
		case -35: goto st11;
		case -34: goto st12;
		case -33: goto st13;
		case -32: goto st14;
		case -31: goto st41;
		case -30: goto st64;
		case -29: goto st70;
		case -22: goto st73;
		case -17: goto st89;
		case -16: goto st93;
		case -13: goto st128;
	}
	goto tr189;
st2:
	if ( ++p == pe )
		goto _test_eof2;
case 2:
	if ( (*p) <= -65 )
		goto tr1;
	goto tr3;
st3:
	if ( ++p == pe )
		goto _test_eof3;
case 3:
	if ( (*p) <= -81 )
		goto tr1;
	goto tr3;
st4:
	if ( ++p == pe )
		goto _test_eof4;
case 4:
	if ( -125 <= (*p) && (*p) <= -119 )
		goto tr1;
	goto tr3;
st5:
	if ( ++p == pe )
		goto _test_eof5;
case 5:
	if ( (*p) == -65 )
		goto tr1;
	if ( -111 <= (*p) && (*p) <= -67 )
		goto tr1;
	goto tr3;
st6:
	if ( ++p == pe )
		goto _test_eof6;
case 6:
	if ( (*p) == -121 )
		goto tr1;
	if ( (*p) > -126 ) {
		if ( -124 <= (*p) && (*p) <= -123 )
			goto tr1;
	} else if ( (*p) >= -127 )
		goto tr1;
	goto tr3;
st7:
	if ( ++p == pe )
		goto _test_eof7;
case 7:
	if ( -112 <= (*p) && (*p) <= -102 )
		goto tr1;
	goto tr3;
st8:
	if ( ++p == pe )
		goto _test_eof8;
case 8:
	if ( (*p) == -80 )
		goto tr1;
	if ( -117 <= (*p) && (*p) <= -97 )
		goto tr1;
	goto tr3;
st9:
	if ( ++p == pe )
		goto _test_eof9;
case 9:
	if ( (*p) < -97 ) {
		if ( -106 <= (*p) && (*p) <= -100 )
			goto tr1;
	} else if ( (*p) > -92 ) {
		if ( (*p) > -88 ) {
			if ( -86 <= (*p) && (*p) <= -83 )
				goto tr1;
		} else if ( (*p) >= -89 )
			goto tr1;
	} else
		goto tr1;
	goto tr3;
st10:
	if ( ++p == pe )
		goto _test_eof10;
case 10:
	if ( (*p) == -111 )
		goto tr1;
	if ( -80 <= (*p) && (*p) <= -65 )
		goto tr1;
	goto tr3;
st11:
	if ( ++p == pe )
		goto _test_eof11;
case 11:
	if ( (*p) <= -118 )
		goto tr1;
	goto tr3;
st12:
	if ( ++p == pe )
		goto _test_eof12;
case 12:
	if ( -90 <= (*p) && (*p) <= -80 )
		goto tr1;
	goto tr3;
st13:
	if ( ++p == pe )
		goto _test_eof13;
case 13:
	if ( -85 <= (*p) && (*p) <= -77 )
		goto tr1;
	goto tr3;
st14:
	if ( ++p == pe )
		goto _test_eof14;
case 14:
	switch( (*p) ) {
		case -96: goto st15;
		case -95: goto st16;
		case -93: goto st17;
		case -92: goto st18;
		case -91: goto st19;
		case -89: goto st21;
		case -87: goto st22;
		case -85: goto st23;
		case -83: goto st24;
		case -82: goto st25;
		case -81: goto st26;
		case -80: goto st27;
		case -79: goto st28;
		case -77: goto st28;
		case -76: goto st29;
		case -75: goto st30;
		case -74: goto st31;
		case -73: goto st32;
		case -72: goto st33;
		case -71: goto st34;
		case -70: goto st35;
		case -69: goto st36;
		case -68: goto st37;
		case -67: goto st38;
		case -66: goto st39;
		case -65: goto st40;
	}
	if ( -90 <= (*p) && (*p) <= -78 )
		goto st20;
	goto tr3;
st15:
	if ( ++p == pe )
		goto _test_eof15;
case 15:
	if ( (*p) < -101 ) {
		if ( -106 <= (*p) && (*p) <= -103 )
			goto tr1;
	} else if ( (*p) > -93 ) {
		if ( (*p) > -89 ) {
			if ( -87 <= (*p) && (*p) <= -83 )
				goto tr1;
		} else if ( (*p) >= -91 )
			goto tr1;
	} else
		goto tr1;
	goto tr3;
st16:
	if ( ++p == pe )
		goto _test_eof16;
case 16:
	if ( -103 <= (*p) && (*p) <= -101 )
		goto tr1;
	goto tr3;
st17:
	if ( ++p == pe )
		goto _test_eof17;
case 17:
	if ( -92 <= (*p) && (*p) <= -65 )
		goto tr1;
	goto tr3;
st18:
	if ( ++p == pe )
		goto _test_eof18;
case 18:
	if ( (*p) < -70 ) {
		if ( (*p) <= -125 )
			goto tr1;
	} else if ( (*p) > -68 ) {
		if ( -66 <= (*p) && (*p) <= -65 )
			goto tr1;
	} else
		goto tr1;
	goto tr3;
st19:
	if ( ++p == pe )
		goto _test_eof19;
case 19:
	if ( (*p) < -111 ) {
		if ( (*p) <= -113 )
			goto tr1;
	} else if ( (*p) > -105 ) {
		if ( -94 <= (*p) && (*p) <= -93 )
			goto tr1;
	} else
		goto tr1;
	goto tr3;
st20:
	if ( ++p == pe )
		goto _test_eof20;
case 20:
	if ( (*p) == -68 )
		goto tr1;
	if ( (*p) > -125 ) {
		if ( -66 <= (*p) && (*p) <= -65 )
			goto tr1;
	} else if ( (*p) >= -127 )
		goto tr1;
	goto tr3;
st21:
	if ( ++p == pe )
		goto _test_eof21;
case 21:
	if ( (*p) == -105 )
		goto tr1;
	if ( (*p) < -121 ) {
		if ( (*p) <= -124 )
			goto tr1;
	} else if ( (*p) > -120 ) {
		if ( (*p) > -115 ) {
			if ( -94 <= (*p) && (*p) <= -93 )
				goto tr1;
		} else if ( (*p) >= -117 )
			goto tr1;
	} else
		goto tr1;
	goto tr3;
st22:
	if ( ++p == pe )
		goto _test_eof22;
case 22:
	switch( (*p) ) {
		case -111: goto tr1;
		case -75: goto tr1;
	}
	if ( (*p) < -121 ) {
		if ( (*p) <= -126 )
			goto tr1;
	} else if ( (*p) > -120 ) {
		if ( (*p) > -115 ) {
			if ( -80 <= (*p) && (*p) <= -79 )
				goto tr1;
		} else if ( (*p) >= -117 )
			goto tr1;
	} else
		goto tr1;
	goto tr3;
st23:
	if ( ++p == pe )
		goto _test_eof23;
case 23:
	if ( (*p) < -121 ) {
		if ( (*p) <= -123 )
			goto tr1;
	} else if ( (*p) > -119 ) {
		if ( (*p) > -115 ) {
			if ( -94 <= (*p) && (*p) <= -93 )
				goto tr1;
		} else if ( (*p) >= -117 )
			goto tr1;
	} else
		goto tr1;
	goto tr3;
st24:
	if ( ++p == pe )
		goto _test_eof24;
case 24:
	if ( (*p) < -117 ) {
		if ( (*p) > -124 ) {
			if ( -121 <= (*p) && (*p) <= -120 )
				goto tr1;
		} else
			goto tr1;
	} else if ( (*p) > -115 ) {
		if ( (*p) > -105 ) {
			if ( -94 <= (*p) && (*p) <= -93 )
				goto tr1;
		} else if ( (*p) >= -106 )
			goto tr1;
	} else
		goto tr1;
	goto tr3;
st25:
	if ( ++p == pe )
		goto _test_eof25;
case 25:
	if ( (*p) == -126 )
		goto tr1;
	if ( -66 <= (*p) && (*p) <= -65 )
		goto tr1;
	goto tr3;
st26:
	if ( ++p == pe )
		goto _test_eof26;
case 26:
	if ( (*p) == -105 )
		goto tr1;
	if ( (*p) < -122 ) {
		if ( (*p) <= -126 )
			goto tr1;
	} else if ( (*p) > -120 ) {
		if ( -118 <= (*p) && (*p) <= -115 )
			goto tr1;
	} else
		goto tr1;
	goto tr3;
st27:
	if ( ++p == pe )
		goto _test_eof27;
case 27:
	if ( (*p) > -125 ) {
		if ( -66 <= (*p) && (*p) <= -65 )
			goto tr1;
	} else
		goto tr1;
	goto tr3;
st28:
	if ( ++p == pe )
		goto _test_eof28;
case 28:
	if ( (*p) < -118 ) {
		if ( (*p) > -124 ) {
			if ( -122 <= (*p) && (*p) <= -120 )
				goto tr1;
		} else
			goto tr1;
	} else if ( (*p) > -115 ) {
		if ( (*p) > -106 ) {
			if ( -94 <= (*p) && (*p) <= -93 )
				goto tr1;
		} else if ( (*p) >= -107 )
			goto tr1;
	} else
		goto tr1;
	goto tr3;
st29:
	if ( ++p == pe )
		goto _test_eof29;
case 29:
	if ( (*p) > -125 ) {
		if ( -66 <= (*p) && (*p) <= -65 )
			goto tr1;
	} else if ( (*p) >= -127 )
		goto tr1;
	goto tr3;
st30:
	if ( ++p == pe )
		goto _test_eof30;
case 30:
	if ( (*p) == -105 )
		goto tr1;
	if ( (*p) < -122 ) {
		if ( (*p) <= -124 )
			goto tr1;
	} else if ( (*p) > -120 ) {
		if ( (*p) > -115 ) {
			if ( -94 <= (*p) && (*p) <= -93 )
				goto tr1;
		} else if ( (*p) >= -118 )
			goto tr1;
	} else
		goto tr1;
	goto tr3;
st31:
	if ( ++p == pe )
		goto _test_eof31;
case 31:
	if ( -126 <= (*p) && (*p) <= -125 )
		goto tr1;
	goto tr3;
st32:
	if ( ++p == pe )
		goto _test_eof32;
case 32:
	switch( (*p) ) {
		case -118: goto tr1;
		case -106: goto tr1;
	}
	if ( (*p) < -104 ) {
		if ( -113 <= (*p) && (*p) <= -108 )
			goto tr1;
	} else if ( (*p) > -97 ) {
		if ( -78 <= (*p) && (*p) <= -77 )
			goto tr1;
	} else
		goto tr1;
	goto tr3;
st33:
	if ( ++p == pe )
		goto _test_eof33;
case 33:
	if ( (*p) == -79 )
		goto tr1;
	if ( -77 <= (*p) && (*p) <= -70 )
		goto tr1;
	goto tr3;
st34:
	if ( ++p == pe )
		goto _test_eof34;
case 34:
	if ( -121 <= (*p) && (*p) <= -114 )
		goto tr1;
	goto tr3;
st35:
	if ( ++p == pe )
		goto _test_eof35;
case 35:
	if ( (*p) == -79 )
		goto tr1;
	if ( (*p) > -71 ) {
		if ( -69 <= (*p) && (*p) <= -68 )
			goto tr1;
	} else if ( (*p) >= -77 )
		goto tr1;
	goto tr3;
st36:
	if ( ++p == pe )
		goto _test_eof36;
case 36:
	if ( -120 <= (*p) && (*p) <= -115 )
		goto tr1;
	goto tr3;
st37:
	if ( ++p == pe )
		goto _test_eof37;
case 37:
	switch( (*p) ) {
		case -75: goto tr1;
		case -73: goto tr1;
		case -71: goto tr1;
	}
	if ( (*p) > -103 ) {
		if ( -66 <= (*p) && (*p) <= -65 )
			goto tr1;
	} else if ( (*p) >= -104 )
		goto tr1;
	goto tr3;
st38:
	if ( ++p == pe )
		goto _test_eof38;
case 38:
	if ( -79 <= (*p) && (*p) <= -65 )
		goto tr1;
	goto tr3;
st39:
	if ( ++p == pe )
		goto _test_eof39;
case 39:
	if ( (*p) < -122 ) {
		if ( (*p) <= -124 )
			goto tr1;
	} else if ( (*p) > -121 ) {
		if ( (*p) > -105 ) {
			if ( -103 <= (*p) && (*p) <= -68 )
				goto tr1;
		} else if ( (*p) >= -115 )
			goto tr1;
	} else
		goto tr1;
	goto tr3;
st40:
	if ( ++p == pe )
		goto _test_eof40;
case 40:
	if ( (*p) == -122 )
		goto tr1;
	goto tr3;
st41:
	if ( ++p == pe )
		goto _test_eof41;
case 41:
	switch( (*p) ) {
		case -128: goto st42;
		case -127: goto st43;
		case -126: goto st44;
		case -115: goto st45;
		case -100: goto st46;
		case -99: goto st47;
		case -98: goto st48;
		case -97: goto st49;
		case -96: goto st50;
		case -94: goto st51;
		case -92: goto st52;
		case -90: goto st53;
		case -88: goto st54;
		case -87: goto st55;
		case -86: goto st56;
		case -84: goto st57;
		case -83: goto st58;
		case -82: goto st59;
		case -81: goto st60;
		case -80: goto st61;
		case -77: goto st62;
		case -73: goto st63;
	}
	goto tr3;
st42:
	if ( ++p == pe )
		goto _test_eof42;
case 42:
	if ( (*p) > -73 ) {
		if ( -71 <= (*p) && (*p) <= -66 )
			goto tr1;
	} else if ( (*p) >= -83 )
		goto tr1;
	goto tr3;
st43:
	if ( ++p == pe )
		goto _test_eof43;
case 43:
	if ( (*p) < -98 ) {
		if ( -106 <= (*p) && (*p) <= -103 )
			goto tr1;
	} else if ( (*p) > -96 ) {
		if ( -79 <= (*p) && (*p) <= -76 )
			goto tr1;
	} else
		goto tr1;
	goto tr3;
st44:
	if ( ++p == pe )
		goto _test_eof44;
case 44:
	switch( (*p) ) {
		case -126: goto tr1;
		case -115: goto tr1;
		case -99: goto tr1;
	}
	if ( -124 <= (*p) && (*p) <= -122 )
		goto tr1;
	goto tr3;
st45:
	if ( ++p == pe )
		goto _test_eof45;
case 45:
	if ( -99 <= (*p) && (*p) <= -97 )
		goto tr1;
	goto tr3;
st46:
	if ( ++p == pe )
		goto _test_eof46;
case 46:
	if ( (*p) > -108 ) {
		if ( -78 <= (*p) && (*p) <= -76 )
			goto tr1;
	} else if ( (*p) >= -110 )
		goto tr1;
	goto tr3;
st47:
	if ( ++p == pe )
		goto _test_eof47;
case 47:
	if ( (*p) > -109 ) {
		if ( -78 <= (*p) && (*p) <= -77 )
			goto tr1;
	} else if ( (*p) >= -110 )
		goto tr1;
	goto tr3;
st48:
	if ( ++p == pe )
		goto _test_eof48;
case 48:
	if ( -76 <= (*p) && (*p) <= -65 )
		goto tr1;
	goto tr3;
st49:
	if ( ++p == pe )
		goto _test_eof49;
case 49:
	if ( (*p) == -99 )
		goto tr1;
	if ( (*p) <= -109 )
		goto tr1;
	goto tr3;
st50:
	if ( ++p == pe )
		goto _test_eof50;
case 50:
	if ( -117 <= (*p) && (*p) <= -115 )
		goto tr1;
	goto tr3;
st51:
	if ( ++p == pe )
		goto _test_eof51;
case 51:
	if ( (*p) == -87 )
		goto tr1;
	goto tr3;
st52:
	if ( ++p == pe )
		goto _test_eof52;
case 52:
	if ( (*p) > -85 ) {
		if ( -80 <= (*p) && (*p) <= -69 )
			goto tr1;
	} else if ( (*p) >= -96 )
		goto tr1;
	goto tr3;
st53:
	if ( ++p == pe )
		goto _test_eof53;
case 53:
	if ( (*p) == -70 )
		goto tr1;
	if ( -75 <= (*p) && (*p) <= -73 )
		goto tr1;
	goto tr3;
st54:
	if ( ++p == pe )
		goto _test_eof54;
case 54:
	if ( -105 <= (*p) && (*p) <= -101 )
		goto tr1;
	goto tr3;
st55:
	if ( ++p == pe )
		goto _test_eof55;
case 55:
	switch( (*p) ) {
		case -96: goto tr1;
		case -94: goto tr1;
		case -65: goto tr1;
	}
	if ( (*p) > -98 ) {
		if ( -91 <= (*p) && (*p) <= -68 )
			goto tr1;
	} else if ( (*p) >= -107 )
		goto tr1;
	goto tr3;
st56:
	if ( ++p == pe )
		goto _test_eof56;
case 56:
	if ( -80 <= (*p) && (*p) <= -66 )
		goto tr1;
	goto tr3;
st57:
	if ( ++p == pe )
		goto _test_eof57;
case 57:
	if ( (*p) > -124 ) {
		if ( -76 <= (*p) && (*p) <= -65 )
			goto tr1;
	} else
		goto tr1;
	goto tr3;
st58:
	if ( ++p == pe )
		goto _test_eof58;
case 58:
	if ( (*p) > -124 ) {
		if ( -85 <= (*p) && (*p) <= -77 )
			goto tr1;
	} else
		goto tr1;
	goto tr3;
st59:
	if ( ++p == pe )
		goto _test_eof59;
case 59:
	if ( (*p) > -126 ) {
		if ( -95 <= (*p) && (*p) <= -83 )
			goto tr1;
	} else
		goto tr1;
	goto tr3;
st60:
	if ( ++p == pe )
		goto _test_eof60;
case 60:
	if ( -90 <= (*p) && (*p) <= -77 )
		goto tr1;
	goto tr3;
st61:
	if ( ++p == pe )
		goto _test_eof61;
case 61:
	if ( -92 <= (*p) && (*p) <= -73 )
		goto tr1;
	goto tr3;
st62:
	if ( ++p == pe )
		goto _test_eof62;
case 62:
	if ( (*p) == -83 )
		goto tr1;
	if ( (*p) < -108 ) {
		if ( -112 <= (*p) && (*p) <= -110 )
			goto tr1;
	} else if ( (*p) > -88 ) {
		if ( (*p) > -76 ) {
			if ( -72 <= (*p) && (*p) <= -71 )
				goto tr1;
		} else if ( (*p) >= -78 )
			goto tr1;
	} else
		goto tr1;
	goto tr3;
st63:
	if ( ++p == pe )
		goto _test_eof63;
case 63:
	if ( (*p) > -75 ) {
		if ( -68 <= (*p) && (*p) <= -65 )
			goto tr1;
	} else
		goto tr1;
	goto tr3;
st64:
	if ( ++p == pe )
		goto _test_eof64;
case 64:
	switch( (*p) ) {
		case -128: goto st65;
		case -125: goto st66;
		case -77: goto st67;
		case -75: goto st68;
		case -73: goto st69;
	}
	goto tr3;
st65:
	if ( ++p == pe )
		goto _test_eof65;
case 65:
	if ( -116 <= (*p) && (*p) <= -115 )
		goto tr1;
	goto tr3;
st66:
	if ( ++p == pe )
		goto _test_eof66;
case 66:
	if ( -112 <= (*p) && (*p) <= -80 )
		goto tr1;
	goto tr3;
st67:
	if ( ++p == pe )
		goto _test_eof67;
case 67:
	if ( -81 <= (*p) && (*p) <= -79 )
		goto tr1;
	goto tr3;
st68:
	if ( ++p == pe )
		goto _test_eof68;
case 68:
	if ( (*p) == -65 )
		goto tr1;
	goto tr3;
st69:
	if ( ++p == pe )
		goto _test_eof69;
case 69:
	if ( -96 <= (*p) && (*p) <= -65 )
		goto tr1;
	goto tr3;
st70:
	if ( ++p == pe )
		goto _test_eof70;
case 70:
	switch( (*p) ) {
		case -128: goto st71;
		case -126: goto st72;
	}
	goto tr3;
st71:
	if ( ++p == pe )
		goto _test_eof71;
case 71:
	if ( -86 <= (*p) && (*p) <= -81 )
		goto tr1;
	goto tr3;
st72:
	if ( ++p == pe )
		goto _test_eof72;
case 72:
	if ( -103 <= (*p) && (*p) <= -102 )
		goto tr1;
	goto tr3;
st73:
	if ( ++p == pe )
		goto _test_eof73;
case 73:
	switch( (*p) ) {
		case -103: goto st74;
		case -102: goto st75;
		case -101: goto st76;
		case -96: goto st77;
		case -94: goto st78;
		case -93: goto st79;
		case -92: goto st80;
		case -91: goto st81;
		case -90: goto st82;
		case -89: goto st83;
		case -88: goto st84;
		case -87: goto st85;
		case -86: goto st86;
		case -85: goto st87;
		case -81: goto st88;
	}
	goto tr3;
st74:
	if ( ++p == pe )
		goto _test_eof74;
case 74:
	if ( (*p) > -78 ) {
		if ( -76 <= (*p) && (*p) <= -67 )
			goto tr1;
	} else if ( (*p) >= -81 )
		goto tr1;
	goto tr3;
st75:
	if ( ++p == pe )
		goto _test_eof75;
case 75:
	if ( (*p) == -97 )
		goto tr1;
	goto tr3;
st76:
	if ( ++p == pe )
		goto _test_eof76;
case 76:
	if ( -80 <= (*p) && (*p) <= -79 )
		goto tr1;
	goto tr3;
st77:
	if ( ++p == pe )
		goto _test_eof77;
case 77:
	switch( (*p) ) {
		case -126: goto tr1;
		case -122: goto tr1;
		case -117: goto tr1;
	}
	if ( -93 <= (*p) && (*p) <= -89 )
		goto tr1;
	goto tr3;
st78:
	if ( ++p == pe )
		goto _test_eof78;
case 78:
	if ( (*p) > -127 ) {
		if ( -76 <= (*p) && (*p) <= -65 )
			goto tr1;
	} else
		goto tr1;
	goto tr3;
st79:
	if ( ++p == pe )
		goto _test_eof79;
case 79:
	if ( (*p) > -124 ) {
		if ( -96 <= (*p) && (*p) <= -79 )
			goto tr1;
	} else
		goto tr1;
	goto tr3;
st80:
	if ( ++p == pe )
		goto _test_eof80;
case 80:
	if ( -90 <= (*p) && (*p) <= -83 )
		goto tr1;
	goto tr3;
st81:
	if ( ++p == pe )
		goto _test_eof81;
case 81:
	if ( -121 <= (*p) && (*p) <= -109 )
		goto tr1;
	goto tr3;
st82:
	if ( ++p == pe )
		goto _test_eof82;
case 82:
	if ( (*p) > -125 ) {
		if ( -77 <= (*p) && (*p) <= -65 )
			goto tr1;
	} else
		goto tr1;
	goto tr3;
st83:
	if ( ++p == pe )
		goto _test_eof83;
case 83:
	switch( (*p) ) {
		case -128: goto tr1;
		case -91: goto tr1;
	}
	goto tr3;
st84:
	if ( ++p == pe )
		goto _test_eof84;
case 84:
	if ( -87 <= (*p) && (*p) <= -74 )
		goto tr1;
	goto tr3;
st85:
	if ( ++p == pe )
		goto _test_eof85;
case 85:
	switch( (*p) ) {
		case -125: goto tr1;
		case -68: goto tr1;
	}
	if ( -116 <= (*p) && (*p) <= -115 )
		goto tr1;
	goto tr3;
st86:
	if ( ++p == pe )
		goto _test_eof86;
case 86:
	if ( (*p) == -80 )
		goto tr1;
	if ( (*p) < -73 ) {
		if ( -78 <= (*p) && (*p) <= -76 )
			goto tr1;
	} else if ( (*p) > -72 ) {
		if ( -66 <= (*p) && (*p) <= -65 )
			goto tr1;
	} else
		goto tr1;
	goto tr3;
st87:
	if ( ++p == pe )
		goto _test_eof87;
case 87:
	if ( (*p) == -127 )
		goto tr1;
	if ( (*p) > -81 ) {
		if ( -75 <= (*p) && (*p) <= -74 )
			goto tr1;
	} else if ( (*p) >= -85 )
		goto tr1;
	goto tr3;
st88:
	if ( ++p == pe )
		goto _test_eof88;
case 88:
	if ( (*p) > -86 ) {
		if ( -84 <= (*p) && (*p) <= -83 )
			goto tr1;
	} else if ( (*p) >= -93 )
		goto tr1;
	goto tr3;
st89:
	if ( ++p == pe )
		goto _test_eof89;
case 89:
	switch( (*p) ) {
		case -84: goto st90;
		case -72: goto st91;
		case -66: goto st92;
	}
	goto tr3;
st90:
	if ( ++p == pe )
		goto _test_eof90;
case 90:
	if ( (*p) == -98 )
		goto tr1;
	goto tr3;
st91:
	if ( ++p == pe )
		goto _test_eof91;
case 91:
	if ( (*p) > -113 ) {
		if ( -96 <= (*p) && (*p) <= -83 )
			goto tr1;
	} else
		goto tr1;
	goto tr3;
st92:
	if ( ++p == pe )
		goto _test_eof92;
case 92:
	if ( -98 <= (*p) && (*p) <= -97 )
		goto tr1;
	goto tr3;
st93:
	if ( ++p == pe )
		goto _test_eof93;
case 93:
	switch( (*p) ) {
		case -112: goto st94;
		case -111: goto st100;
		case -106: goto st115;
		case -101: goto st120;
		case -99: goto st122;
		case -98: goto st126;
	}
	goto tr3;
st94:
	if ( ++p == pe )
		goto _test_eof94;
case 94:
	switch( (*p) ) {
		case -121: goto st95;
		case -117: goto st96;
		case -115: goto st97;
		case -88: goto st98;
		case -85: goto st99;
	}
	goto tr3;
st95:
	if ( ++p == pe )
		goto _test_eof95;
case 95:
	if ( (*p) == -67 )
		goto tr1;
	goto tr3;
st96:
	if ( ++p == pe )
		goto _test_eof96;
case 96:
	if ( (*p) == -96 )
		goto tr1;
	goto tr3;
st97:
	if ( ++p == pe )
		goto _test_eof97;
case 97:
	if ( -74 <= (*p) && (*p) <= -70 )
		goto tr1;
	goto tr3;
st98:
	if ( ++p == pe )
		goto _test_eof98;
case 98:
	if ( (*p) == -65 )
		goto tr1;
	if ( (*p) < -123 ) {
		if ( -127 <= (*p) && (*p) <= -125 )
			goto tr1;
	} else if ( (*p) > -122 ) {
		if ( (*p) > -113 ) {
			if ( -72 <= (*p) && (*p) <= -70 )
				goto tr1;
		} else if ( (*p) >= -116 )
			goto tr1;
	} else
		goto tr1;
	goto tr3;
st99:
	if ( ++p == pe )
		goto _test_eof99;
case 99:
	if ( -91 <= (*p) && (*p) <= -90 )
		goto tr1;
	goto tr3;
st100:
	if ( ++p == pe )
		goto _test_eof100;
case 100:
	switch( (*p) ) {
		case -128: goto st101;
		case -127: goto st102;
		case -126: goto st103;
		case -124: goto st104;
		case -123: goto st105;
		case -122: goto st106;
		case -121: goto st107;
		case -120: goto st108;
		case -117: goto st109;
		case -116: goto st20;
		case -115: goto st110;
		case -110: goto st111;
		case -109: goto st112;
		case -106: goto st113;
		case -104: goto st111;
		case -102: goto st114;
	}
	if ( -105 <= (*p) && (*p) <= -103 )
		goto st107;
	goto tr3;
st101:
	if ( ++p == pe )
		goto _test_eof101;
case 101:
	if ( (*p) > -126 ) {
		if ( -72 <= (*p) && (*p) <= -65 )
			goto tr1;
	} else
		goto tr1;
	goto tr3;
st102:
	if ( ++p == pe )
		goto _test_eof102;
case 102:
	if ( (*p) == -65 )
		goto tr1;
	if ( (*p) <= -122 )
		goto tr1;
	goto tr3;
st103:
	if ( ++p == pe )
		goto _test_eof103;
case 103:
	if ( (*p) > -126 ) {
		if ( -80 <= (*p) && (*p) <= -70 )
			goto tr1;
	} else
		goto tr1;
	goto tr3;
st104:
	if ( ++p == pe )
		goto _test_eof104;
case 104:
	if ( (*p) > -126 ) {
		if ( -89 <= (*p) && (*p) <= -76 )
			goto tr1;
	} else
		goto tr1;
	goto tr3;
st105:
	if ( ++p == pe )
		goto _test_eof105;
case 105:
	if ( (*p) == -77 )
		goto tr1;
	goto tr3;
st106:
	if ( ++p == pe )
		goto _test_eof106;
case 106:
	if ( (*p) > -126 ) {
		if ( -77 <= (*p) && (*p) <= -65 )
			goto tr1;
	} else
		goto tr1;
	goto tr3;
st107:
	if ( ++p == pe )
		goto _test_eof107;
case 107:
	if ( (*p) == -128 )
		goto tr1;
	goto tr3;
st108:
	if ( ++p == pe )
		goto _test_eof108;
case 108:
	if ( -84 <= (*p) && (*p) <= -73 )
		goto tr1;
	goto tr3;
st109:
	if ( ++p == pe )
		goto _test_eof109;
case 109:
	if ( -97 <= (*p) && (*p) <= -86 )
		goto tr1;
	goto tr3;
st110:
	if ( ++p == pe )
		goto _test_eof110;
case 110:
	if ( (*p) == -105 )
		goto tr1;
	if ( (*p) < -117 ) {
		if ( (*p) > -124 ) {
			if ( -121 <= (*p) && (*p) <= -120 )
				goto tr1;
		} else
			goto tr1;
	} else if ( (*p) > -115 ) {
		if ( (*p) < -90 ) {
			if ( -94 <= (*p) && (*p) <= -93 )
				goto tr1;
		} else if ( (*p) > -84 ) {
			if ( -80 <= (*p) && (*p) <= -76 )
				goto tr1;
		} else
			goto tr1;
	} else
		goto tr1;
	goto tr3;
st111:
	if ( ++p == pe )
		goto _test_eof111;
case 111:
	if ( -80 <= (*p) && (*p) <= -65 )
		goto tr1;
	goto tr3;
st112:
	if ( ++p == pe )
		goto _test_eof112;
case 112:
	if ( (*p) <= -125 )
		goto tr1;
	goto tr3;
st113:
	if ( ++p == pe )
		goto _test_eof113;
case 113:
	if ( (*p) > -75 ) {
		if ( -72 <= (*p) && (*p) <= -65 )
			goto tr1;
	} else if ( (*p) >= -81 )
		goto tr1;
	goto tr3;
st114:
	if ( ++p == pe )
		goto _test_eof114;
case 114:
	if ( -85 <= (*p) && (*p) <= -73 )
		goto tr1;
	goto tr3;
st115:
	if ( ++p == pe )
		goto _test_eof115;
case 115:
	switch( (*p) ) {
		case -85: goto st116;
		case -84: goto st117;
		case -67: goto st118;
		case -66: goto st119;
	}
	goto tr3;
st116:
	if ( ++p == pe )
		goto _test_eof116;
case 116:
	if ( -80 <= (*p) && (*p) <= -76 )
		goto tr1;
	goto tr3;
st117:
	if ( ++p == pe )
		goto _test_eof117;
case 117:
	if ( -80 <= (*p) && (*p) <= -74 )
		goto tr1;
	goto tr3;
st118:
	if ( ++p == pe )
		goto _test_eof118;
case 118:
	if ( -111 <= (*p) && (*p) <= -66 )
		goto tr1;
	goto tr3;
st119:
	if ( ++p == pe )
		goto _test_eof119;
case 119:
	if ( -113 <= (*p) && (*p) <= -110 )
		goto tr1;
	goto tr3;
st120:
	if ( ++p == pe )
		goto _test_eof120;
case 120:
	if ( (*p) == -78 )
		goto st121;
	goto tr3;
st121:
	if ( ++p == pe )
		goto _test_eof121;
case 121:
	if ( -99 <= (*p) && (*p) <= -98 )
		goto tr1;
	goto tr3;
st122:
	if ( ++p == pe )
		goto _test_eof122;
case 122:
	switch( (*p) ) {
		case -123: goto st123;
		case -122: goto st124;
		case -119: goto st125;
	}
	goto tr3;
st123:
	if ( ++p == pe )
		goto _test_eof123;
case 123:
	if ( (*p) < -83 ) {
		if ( -91 <= (*p) && (*p) <= -87 )
			goto tr1;
	} else if ( (*p) > -78 ) {
		if ( -69 <= (*p) && (*p) <= -65 )
			goto tr1;
	} else
		goto tr1;
	goto tr3;
st124:
	if ( ++p == pe )
		goto _test_eof124;
case 124:
	if ( (*p) < -123 ) {
		if ( (*p) <= -126 )
			goto tr1;
	} else if ( (*p) > -117 ) {
		if ( -86 <= (*p) && (*p) <= -83 )
			goto tr1;
	} else
		goto tr1;
	goto tr3;
st125:
	if ( ++p == pe )
		goto _test_eof125;
case 125:
	if ( -126 <= (*p) && (*p) <= -124 )
		goto tr1;
	goto tr3;
st126:
	if ( ++p == pe )
		goto _test_eof126;
case 126:
	if ( (*p) == -93 )
		goto st127;
	goto tr3;
st127:
	if ( ++p == pe )
		goto _test_eof127;
case 127:
	if ( -112 <= (*p) && (*p) <= -106 )
		goto tr1;
	goto tr3;
st128:
	if ( ++p == pe )
		goto _test_eof128;
case 128:
	if ( (*p) == -96 )
		goto st129;
	goto tr3;
st129:
	if ( ++p == pe )
		goto _test_eof129;
case 129:
	if ( (*p) == -121 )
		goto st3;
	if ( -124 <= (*p) && (*p) <= -122 )
		goto st2;
	goto tr3;
st130:
	if ( ++p == pe )
		goto _test_eof130;
case 130:
	if ( (*p) <= -65 )
		goto tr1;
	goto st0;
st131:
	if ( ++p == pe )
		goto _test_eof131;
case 131:
	if ( (*p) == -100 )
		goto tr0;
	if ( (*p) > -123 ) {
		if ( -122 <= (*p) && (*p) <= -65 )
			goto tr1;
	} else
		goto tr0;
	goto st0;
st132:
	if ( ++p == pe )
		goto _test_eof132;
case 132:
	if ( (*p) == -99 )
		goto tr0;
	if ( (*p) <= -65 )
		goto tr1;
	goto st0;
st133:
	if ( ++p == pe )
		goto _test_eof133;
case 133:
	if ( (*p) == -113 )
		goto tr0;
	if ( (*p) <= -65 )
		goto tr1;
	goto st0;
st134:
	if ( ++p == pe )
		goto _test_eof134;
case 134:
	if ( -96 <= (*p) && (*p) <= -65 )
		goto st130;
	goto st0;
st135:
	if ( ++p == pe )
		goto _test_eof135;
case 135:
	switch( (*p) ) {
		case -124: goto st136;
		case -123: goto st166;
		case -122: goto st167;
		case -121: goto st168;
		case -96: goto st169;
	}
	if ( (*p) <= -65 )
		goto st130;
	goto st0;
st136:
	if ( ++p == pe )
		goto _test_eof136;
case 136:
	if ( (*p) <= -65 )
		goto tr120;
	goto st0;
tr120:
#line 1 "NONE"
	{te = p+1;}
	goto st211;
st211:
	if ( ++p == pe )
		goto _test_eof211;
case 211:
#line 1587 "/tmp/DIwPodyP1J/output"
	switch( (*p) ) {
		case -52: goto st2;
		case -51: goto st3;
		case -46: goto st4;
		case -42: goto st5;
		case -41: goto st6;
		case -40: goto st7;
		case -39: goto st8;
		case -37: goto st9;
		case -36: goto st10;
		case -35: goto st11;
		case -34: goto st12;
		case -33: goto st13;
		case -32: goto st14;
		case -31: goto st137;
		case -30: goto st64;
		case -29: goto st70;
		case -22: goto st152;
		case -21: goto st161;
		case -20: goto st162;
		case -19: goto st163;
		case -17: goto st89;
		case -16: goto st93;
		case -13: goto st128;
	}
	goto tr189;
st137:
	if ( ++p == pe )
		goto _test_eof137;
case 137:
	switch( (*p) ) {
		case -128: goto st42;
		case -127: goto st43;
		case -126: goto st44;
		case -124: goto st138;
		case -123: goto st139;
		case -122: goto st151;
		case -115: goto st45;
		case -100: goto st46;
		case -99: goto st47;
		case -98: goto st48;
		case -97: goto st49;
		case -96: goto st50;
		case -94: goto st51;
		case -92: goto st52;
		case -90: goto st53;
		case -88: goto st54;
		case -87: goto st55;
		case -86: goto st56;
		case -84: goto st57;
		case -83: goto st58;
		case -82: goto st59;
		case -81: goto st60;
		case -80: goto st61;
		case -77: goto st62;
		case -73: goto st63;
	}
	goto tr3;
st138:
	if ( ++p == pe )
		goto _test_eof138;
case 138:
	if ( (*p) <= -65 )
		goto tr120;
	goto tr3;
st139:
	if ( ++p == pe )
		goto _test_eof139;
case 139:
	if ( (*p) > -97 ) {
		if ( -96 <= (*p) && (*p) <= -65 )
			goto tr124;
	} else
		goto tr120;
	goto tr3;
tr124:
#line 1 "NONE"
	{te = p+1;}
	goto st212;
st212:
	if ( ++p == pe )
		goto _test_eof212;
case 212:
#line 1671 "/tmp/DIwPodyP1J/output"
	switch( (*p) ) {
		case -52: goto st2;
		case -51: goto st3;
		case -46: goto st4;
		case -42: goto st5;
		case -41: goto st6;
		case -40: goto st7;
		case -39: goto st8;
		case -37: goto st9;
		case -36: goto st10;
		case -35: goto st11;
		case -34: goto st12;
		case -33: goto st13;
		case -32: goto st14;
		case -31: goto st140;
		case -30: goto st64;
		case -29: goto st70;
		case -22: goto st73;
		case -19: goto st148;
		case -17: goto st89;
		case -16: goto st93;
		case -13: goto st128;
	}
	goto tr189;
st140:
	if ( ++p == pe )
		goto _test_eof140;
case 140:
	switch( (*p) ) {
		case -128: goto st42;
		case -127: goto st43;
		case -126: goto st44;
		case -123: goto st141;
		case -122: goto st142;
		case -121: goto st145;
		case -115: goto st45;
		case -100: goto st46;
		case -99: goto st47;
		case -98: goto st48;
		case -97: goto st49;
		case -96: goto st50;
		case -94: goto st51;
		case -92: goto st52;
		case -90: goto st53;
		case -88: goto st54;
		case -87: goto st55;
		case -86: goto st56;
		case -84: goto st57;
		case -83: goto st58;
		case -82: goto st59;
		case -81: goto st60;
		case -80: goto st61;
		case -77: goto st62;
		case -73: goto st63;
	}
	goto tr3;
st141:
	if ( ++p == pe )
		goto _test_eof141;
case 141:
	if ( -96 <= (*p) && (*p) <= -65 )
		goto tr124;
	goto tr3;
st142:
	if ( ++p == pe )
		goto _test_eof142;
case 142:
	if ( (*p) > -89 ) {
		if ( -88 <= (*p) && (*p) <= -65 )
			goto tr128;
	} else
		goto tr124;
	goto tr3;
tr128:
#line 1 "NONE"
	{te = p+1;}
	goto st213;
st213:
	if ( ++p == pe )
		goto _test_eof213;
case 213:
#line 1753 "/tmp/DIwPodyP1J/output"
	switch( (*p) ) {
		case -52: goto st2;
		case -51: goto st3;
		case -46: goto st4;
		case -42: goto st5;
		case -41: goto st6;
		case -40: goto st7;
		case -39: goto st8;
		case -37: goto st9;
		case -36: goto st10;
		case -35: goto st11;
		case -34: goto st12;
		case -33: goto st13;
		case -32: goto st14;
		case -31: goto st143;
		case -30: goto st64;
		case -29: goto st70;
		case -22: goto st73;
		case -19: goto st146;
		case -17: goto st89;
		case -16: goto st93;
		case -13: goto st128;
	}
	goto tr189;
st143:
	if ( ++p == pe )
		goto _test_eof143;
case 143:
	switch( (*p) ) {
		case -128: goto st42;
		case -127: goto st43;
		case -126: goto st44;
		case -122: goto st144;
		case -121: goto st145;
		case -115: goto st45;
		case -100: goto st46;
		case -99: goto st47;
		case -98: goto st48;
		case -97: goto st49;
		case -96: goto st50;
		case -94: goto st51;
		case -92: goto st52;
		case -90: goto st53;
		case -88: goto st54;
		case -87: goto st55;
		case -86: goto st56;
		case -84: goto st57;
		case -83: goto st58;
		case -82: goto st59;
		case -81: goto st60;
		case -80: goto st61;
		case -77: goto st62;
		case -73: goto st63;
	}
	goto tr3;
st144:
	if ( ++p == pe )
		goto _test_eof144;
case 144:
	if ( -88 <= (*p) && (*p) <= -65 )
		goto tr128;
	goto tr3;
st145:
	if ( ++p == pe )
		goto _test_eof145;
case 145:
	if ( (*p) <= -65 )
		goto tr128;
	goto tr3;
st146:
	if ( ++p == pe )
		goto _test_eof146;
case 146:
	if ( (*p) == -97 )
		goto st147;
	goto tr3;
st147:
	if ( ++p == pe )
		goto _test_eof147;
case 147:
	if ( -117 <= (*p) && (*p) <= -69 )
		goto tr128;
	goto tr3;
st148:
	if ( ++p == pe )
		goto _test_eof148;
case 148:
	switch( (*p) ) {
		case -98: goto st149;
		case -97: goto st150;
	}
	goto tr3;
st149:
	if ( ++p == pe )
		goto _test_eof149;
case 149:
	if ( -80 <= (*p) && (*p) <= -65 )
		goto tr124;
	goto tr3;
st150:
	if ( ++p == pe )
		goto _test_eof150;
case 150:
	if ( (*p) > -122 ) {
		if ( -117 <= (*p) && (*p) <= -69 )
			goto tr128;
	} else
		goto tr124;
	goto tr3;
st151:
	if ( ++p == pe )
		goto _test_eof151;
case 151:
	if ( (*p) <= -89 )
		goto tr124;
	goto tr3;
st152:
	if ( ++p == pe )
		goto _test_eof152;
case 152:
	switch( (*p) ) {
		case -103: goto st74;
		case -102: goto st75;
		case -101: goto st76;
		case -96: goto st77;
		case -94: goto st78;
		case -93: goto st79;
		case -92: goto st80;
		case -91: goto st153;
		case -90: goto st82;
		case -89: goto st83;
		case -88: goto st84;
		case -87: goto st85;
		case -86: goto st86;
		case -85: goto st87;
		case -81: goto st88;
		case -79: goto st155;
		case -78: goto st156;
		case -77: goto st157;
		case -76: goto st158;
		case -75: goto st159;
		case -74: goto st160;
		case -72: goto st155;
		case -71: goto st156;
		case -70: goto st157;
		case -69: goto st158;
		case -68: goto st159;
		case -67: goto st160;
		case -65: goto st155;
	}
	if ( -80 <= (*p) && (*p) <= -66 )
		goto st154;
	goto tr3;
st153:
	if ( ++p == pe )
		goto _test_eof153;
case 153:
	if ( (*p) > -109 ) {
		if ( -96 <= (*p) && (*p) <= -68 )
			goto tr120;
	} else if ( (*p) >= -121 )
		goto tr1;
	goto tr3;
st154:
	if ( ++p == pe )
		goto _test_eof154;
case 154:
	switch( (*p) ) {
		case -128: goto tr124;
		case -100: goto tr124;
		case -72: goto tr124;
	}
	if ( -127 <= (*p) && (*p) <= -65 )
		goto tr128;
	goto tr3;
st155:
	if ( ++p == pe )
		goto _test_eof155;
case 155:
	switch( (*p) ) {
		case -108: goto tr124;
		case -80: goto tr124;
	}
	if ( (*p) <= -65 )
		goto tr128;
	goto tr3;
st156:
	if ( ++p == pe )
		goto _test_eof156;
case 156:
	switch( (*p) ) {
		case -116: goto tr124;
		case -88: goto tr124;
	}
	if ( (*p) <= -65 )
		goto tr128;
	goto tr3;
st157:
	if ( ++p == pe )
		goto _test_eof157;
case 157:
	switch( (*p) ) {
		case -124: goto tr124;
		case -96: goto tr124;
		case -68: goto tr124;
	}
	if ( (*p) <= -65 )
		goto tr128;
	goto tr3;
st158:
	if ( ++p == pe )
		goto _test_eof158;
case 158:
	switch( (*p) ) {
		case -104: goto tr124;
		case -76: goto tr124;
	}
	if ( (*p) <= -65 )
		goto tr128;
	goto tr3;
st159:
	if ( ++p == pe )
		goto _test_eof159;
case 159:
	switch( (*p) ) {
		case -112: goto tr124;
		case -84: goto tr124;
	}
	if ( (*p) <= -65 )
		goto tr128;
	goto tr3;
st160:
	if ( ++p == pe )
		goto _test_eof160;
case 160:
	switch( (*p) ) {
		case -120: goto tr124;
		case -92: goto tr124;
	}
	if ( (*p) <= -65 )
		goto tr128;
	goto tr3;
st161:
	if ( ++p == pe )
		goto _test_eof161;
case 161:
	switch( (*p) ) {
		case -127: goto st157;
		case -126: goto st158;
		case -125: goto st159;
		case -124: goto st160;
		case -123: goto st154;
		case -122: goto st155;
		case -120: goto st157;
		case -119: goto st158;
		case -118: goto st159;
		case -117: goto st160;
		case -116: goto st154;
		case -115: goto st155;
		case -113: goto st157;
		case -112: goto st158;
		case -111: goto st159;
		case -110: goto st160;
		case -109: goto st154;
		case -108: goto st155;
		case -106: goto st157;
		case -105: goto st158;
		case -104: goto st159;
		case -103: goto st160;
		case -102: goto st154;
		case -101: goto st155;
		case -99: goto st157;
		case -98: goto st158;
		case -97: goto st159;
		case -96: goto st160;
		case -95: goto st154;
		case -94: goto st155;
		case -92: goto st157;
		case -91: goto st158;
		case -90: goto st159;
		case -89: goto st160;
		case -88: goto st154;
		case -87: goto st155;
		case -85: goto st157;
		case -84: goto st158;
		case -83: goto st159;
		case -82: goto st160;
		case -81: goto st154;
		case -80: goto st155;
		case -78: goto st157;
		case -77: goto st158;
		case -76: goto st159;
		case -75: goto st160;
		case -74: goto st154;
		case -73: goto st155;
		case -71: goto st157;
		case -70: goto st158;
		case -69: goto st159;
		case -68: goto st160;
		case -67: goto st154;
		case -66: goto st155;
	}
	if ( (*p) <= -65 )
		goto st156;
	goto tr3;
st162:
	if ( ++p == pe )
		goto _test_eof162;
case 162:
	switch( (*p) ) {
		case -127: goto st158;
		case -126: goto st159;
		case -125: goto st160;
		case -124: goto st154;
		case -123: goto st155;
		case -122: goto st156;
		case -120: goto st158;
		case -119: goto st159;
		case -118: goto st160;
		case -117: goto st154;
		case -116: goto st155;
		case -115: goto st156;
		case -113: goto st158;
		case -112: goto st159;
		case -111: goto st160;
		case -110: goto st154;
		case -109: goto st155;
		case -108: goto st156;
		case -106: goto st158;
		case -105: goto st159;
		case -104: goto st160;
		case -103: goto st154;
		case -102: goto st155;
		case -101: goto st156;
		case -99: goto st158;
		case -98: goto st159;
		case -97: goto st160;
		case -96: goto st154;
		case -95: goto st155;
		case -94: goto st156;
		case -92: goto st158;
		case -91: goto st159;
		case -90: goto st160;
		case -89: goto st154;
		case -88: goto st155;
		case -87: goto st156;
		case -85: goto st158;
		case -84: goto st159;
		case -83: goto st160;
		case -82: goto st154;
		case -81: goto st155;
		case -80: goto st156;
		case -78: goto st158;
		case -77: goto st159;
		case -76: goto st160;
		case -75: goto st154;
		case -74: goto st155;
		case -73: goto st156;
		case -71: goto st158;
		case -70: goto st159;
		case -69: goto st160;
		case -68: goto st154;
		case -67: goto st155;
		case -66: goto st156;
	}
	if ( (*p) <= -65 )
		goto st157;
	goto tr3;
st163:
	if ( ++p == pe )
		goto _test_eof163;
case 163:
	switch( (*p) ) {
		case -127: goto st159;
		case -126: goto st160;
		case -125: goto st154;
		case -124: goto st155;
		case -123: goto st156;
		case -122: goto st157;
		case -120: goto st159;
		case -119: goto st160;
		case -118: goto st154;
		case -117: goto st155;
		case -116: goto st156;
		case -115: goto st157;
		case -113: goto st159;
		case -112: goto st160;
		case -111: goto st154;
		case -110: goto st155;
		case -109: goto st156;
		case -108: goto st157;
		case -106: goto st159;
		case -105: goto st160;
		case -104: goto st154;
		case -103: goto st155;
		case -102: goto st156;
		case -101: goto st157;
		case -99: goto st159;
		case -98: goto st164;
		case -97: goto st165;
	}
	if ( (*p) <= -100 )
		goto st158;
	goto tr3;
st164:
	if ( ++p == pe )
		goto _test_eof164;
case 164:
	if ( (*p) == -120 )
		goto tr124;
	if ( (*p) > -93 ) {
		if ( -80 <= (*p) && (*p) <= -65 )
			goto tr124;
	} else
		goto tr128;
	goto tr3;
st165:
	if ( ++p == pe )
		goto _test_eof165;
case 165:
	if ( (*p) <= -122 )
		goto tr124;
	goto tr3;
st166:
	if ( ++p == pe )
		goto _test_eof166;
case 166:
	if ( (*p) > -97 ) {
		if ( -96 <= (*p) && (*p) <= -65 )
			goto tr124;
	} else
		goto tr120;
	goto st0;
st167:
	if ( ++p == pe )
		goto _test_eof167;
case 167:
	if ( (*p) > -89 ) {
		if ( -88 <= (*p) && (*p) <= -65 )
			goto tr128;
	} else
		goto tr124;
	goto st0;
st168:
	if ( ++p == pe )
		goto _test_eof168;
case 168:
	if ( (*p) <= -65 )
		goto tr128;
	goto st0;
st169:
	if ( ++p == pe )
		goto _test_eof169;
case 169:
	if ( (*p) == -114 )
		goto tr0;
	if ( (*p) <= -65 )
		goto tr1;
	goto st0;
st170:
	if ( ++p == pe )
		goto _test_eof170;
case 170:
	switch( (*p) ) {
		case -128: goto st171;
		case -127: goto st172;
	}
	if ( -126 <= (*p) && (*p) <= -65 )
		goto st130;
	goto st0;
st171:
	if ( ++p == pe )
		goto _test_eof171;
case 171:
	if ( (*p) == -117 )
		goto tr0;
	if ( (*p) < -112 ) {
		if ( (*p) > -115 ) {
			if ( -114 <= (*p) && (*p) <= -113 )
				goto tr0;
		} else
			goto tr1;
	} else if ( (*p) > -89 ) {
		if ( (*p) > -82 ) {
			if ( -81 <= (*p) && (*p) <= -65 )
				goto tr1;
		} else if ( (*p) >= -88 )
			goto tr0;
	} else
		goto tr1;
	goto st0;
st172:
	if ( ++p == pe )
		goto _test_eof172;
case 172:
	if ( (*p) < -96 ) {
		if ( (*p) <= -97 )
			goto tr1;
	} else if ( (*p) > -81 ) {
		if ( -80 <= (*p) && (*p) <= -65 )
			goto tr1;
	} else
		goto tr0;
	goto st0;
st173:
	if ( ++p == pe )
		goto _test_eof173;
case 173:
	if ( (*p) <= -65 )
		goto st130;
	goto st0;
st174:
	if ( ++p == pe )
		goto _test_eof174;
case 174:
	switch( (*p) ) {
		case -91: goto st175;
		case -79: goto st177;
		case -78: goto st178;
		case -77: goto st179;
		case -76: goto st180;
		case -75: goto st181;
		case -74: goto st182;
		case -72: goto st177;
		case -71: goto st178;
		case -70: goto st179;
		case -69: goto st180;
		case -68: goto st181;
		case -67: goto st182;
		case -65: goto st177;
	}
	if ( (*p) > -81 ) {
		if ( -80 <= (*p) && (*p) <= -66 )
			goto st176;
	} else
		goto st130;
	goto st0;
st175:
	if ( ++p == pe )
		goto _test_eof175;
case 175:
	if ( (*p) < -96 ) {
		if ( (*p) <= -97 )
			goto tr1;
	} else if ( (*p) > -68 ) {
		if ( -67 <= (*p) && (*p) <= -65 )
			goto tr1;
	} else
		goto tr120;
	goto st0;
st176:
	if ( ++p == pe )
		goto _test_eof176;
case 176:
	switch( (*p) ) {
		case -128: goto tr124;
		case -100: goto tr124;
		case -72: goto tr124;
	}
	if ( -127 <= (*p) && (*p) <= -65 )
		goto tr128;
	goto st0;
st177:
	if ( ++p == pe )
		goto _test_eof177;
case 177:
	switch( (*p) ) {
		case -108: goto tr124;
		case -80: goto tr124;
	}
	if ( (*p) <= -65 )
		goto tr128;
	goto st0;
st178:
	if ( ++p == pe )
		goto _test_eof178;
case 178:
	switch( (*p) ) {
		case -116: goto tr124;
		case -88: goto tr124;
	}
	if ( (*p) <= -65 )
		goto tr128;
	goto st0;
st179:
	if ( ++p == pe )
		goto _test_eof179;
case 179:
	switch( (*p) ) {
		case -124: goto tr124;
		case -96: goto tr124;
		case -68: goto tr124;
	}
	if ( (*p) <= -65 )
		goto tr128;
	goto st0;
st180:
	if ( ++p == pe )
		goto _test_eof180;
case 180:
	switch( (*p) ) {
		case -104: goto tr124;
		case -76: goto tr124;
	}
	if ( (*p) <= -65 )
		goto tr128;
	goto st0;
st181:
	if ( ++p == pe )
		goto _test_eof181;
case 181:
	switch( (*p) ) {
		case -112: goto tr124;
		case -84: goto tr124;
	}
	if ( (*p) <= -65 )
		goto tr128;
	goto st0;
st182:
	if ( ++p == pe )
		goto _test_eof182;
case 182:
	switch( (*p) ) {
		case -120: goto tr124;
		case -92: goto tr124;
	}
	if ( (*p) <= -65 )
		goto tr128;
	goto st0;
st183:
	if ( ++p == pe )
		goto _test_eof183;
case 183:
	switch( (*p) ) {
		case -127: goto st179;
		case -126: goto st180;
		case -125: goto st181;
		case -124: goto st182;
		case -123: goto st176;
		case -122: goto st177;
		case -120: goto st179;
		case -119: goto st180;
		case -118: goto st181;
		case -117: goto st182;
		case -116: goto st176;
		case -115: goto st177;
		case -113: goto st179;
		case -112: goto st180;
		case -111: goto st181;
		case -110: goto st182;
		case -109: goto st176;
		case -108: goto st177;
		case -106: goto st179;
		case -105: goto st180;
		case -104: goto st181;
		case -103: goto st182;
		case -102: goto st176;
		case -101: goto st177;
		case -99: goto st179;
		case -98: goto st180;
		case -97: goto st181;
		case -96: goto st182;
		case -95: goto st176;
		case -94: goto st177;
		case -92: goto st179;
		case -91: goto st180;
		case -90: goto st181;
		case -89: goto st182;
		case -88: goto st176;
		case -87: goto st177;
		case -85: goto st179;
		case -84: goto st180;
		case -83: goto st181;
		case -82: goto st182;
		case -81: goto st176;
		case -80: goto st177;
		case -78: goto st179;
		case -77: goto st180;
		case -76: goto st181;
		case -75: goto st182;
		case -74: goto st176;
		case -73: goto st177;
		case -71: goto st179;
		case -70: goto st180;
		case -69: goto st181;
		case -68: goto st182;
		case -67: goto st176;
		case -66: goto st177;
	}
	if ( (*p) <= -65 )
		goto st178;
	goto st0;
st184:
	if ( ++p == pe )
		goto _test_eof184;
case 184:
	switch( (*p) ) {
		case -127: goto st180;
		case -126: goto st181;
		case -125: goto st182;
		case -124: goto st176;
		case -123: goto st177;
		case -122: goto st178;
		case -120: goto st180;
		case -119: goto st181;
		case -118: goto st182;
		case -117: goto st176;
		case -116: goto st177;
		case -115: goto st178;
		case -113: goto st180;
		case -112: goto st181;
		case -111: goto st182;
		case -110: goto st176;
		case -109: goto st177;
		case -108: goto st178;
		case -106: goto st180;
		case -105: goto st181;
		case -104: goto st182;
		case -103: goto st176;
		case -102: goto st177;
		case -101: goto st178;
		case -99: goto st180;
		case -98: goto st181;
		case -97: goto st182;
		case -96: goto st176;
		case -95: goto st177;
		case -94: goto st178;
		case -92: goto st180;
		case -91: goto st181;
		case -90: goto st182;
		case -89: goto st176;
		case -88: goto st177;
		case -87: goto st178;
		case -85: goto st180;
		case -84: goto st181;
		case -83: goto st182;
		case -82: goto st176;
		case -81: goto st177;
		case -80: goto st178;
		case -78: goto st180;
		case -77: goto st181;
		case -76: goto st182;
		case -75: goto st176;
		case -74: goto st177;
		case -73: goto st178;
		case -71: goto st180;
		case -70: goto st181;
		case -69: goto st182;
		case -68: goto st176;
		case -67: goto st177;
		case -66: goto st178;
	}
	if ( (*p) <= -65 )
		goto st179;
	goto st0;
st185:
	if ( ++p == pe )
		goto _test_eof185;
case 185:
	switch( (*p) ) {
		case -127: goto st181;
		case -126: goto st182;
		case -125: goto st176;
		case -124: goto st177;
		case -123: goto st178;
		case -122: goto st179;
		case -120: goto st181;
		case -119: goto st182;
		case -118: goto st176;
		case -117: goto st177;
		case -116: goto st178;
		case -115: goto st179;
		case -113: goto st181;
		case -112: goto st182;
		case -111: goto st176;
		case -110: goto st177;
		case -109: goto st178;
		case -108: goto st179;
		case -106: goto st181;
		case -105: goto st182;
		case -104: goto st176;
		case -103: goto st177;
		case -102: goto st178;
		case -101: goto st179;
		case -99: goto st181;
		case -98: goto st186;
		case -97: goto st187;
	}
	if ( (*p) <= -100 )
		goto st180;
	goto st0;
st186:
	if ( ++p == pe )
		goto _test_eof186;
case 186:
	if ( (*p) == -120 )
		goto tr124;
	if ( (*p) < -92 ) {
		if ( (*p) <= -93 )
			goto tr128;
	} else if ( (*p) > -81 ) {
		if ( -80 <= (*p) && (*p) <= -65 )
			goto tr124;
	} else
		goto tr1;
	goto st0;
st187:
	if ( ++p == pe )
		goto _test_eof187;
case 187:
	if ( (*p) < -121 ) {
		if ( (*p) <= -122 )
			goto tr124;
	} else if ( (*p) > -118 ) {
		if ( (*p) > -69 ) {
			if ( -68 <= (*p) && (*p) <= -65 )
				goto tr1;
		} else if ( (*p) >= -117 )
			goto tr128;
	} else
		goto tr1;
	goto st0;
st188:
	if ( ++p == pe )
		goto _test_eof188;
case 188:
	switch( (*p) ) {
		case -69: goto st189;
		case -65: goto st190;
	}
	if ( (*p) <= -66 )
		goto st130;
	goto st0;
st189:
	if ( ++p == pe )
		goto _test_eof189;
case 189:
	if ( (*p) == -65 )
		goto tr0;
	if ( (*p) <= -66 )
		goto tr1;
	goto st0;
st190:
	if ( ++p == pe )
		goto _test_eof190;
case 190:
	if ( (*p) < -80 ) {
		if ( (*p) <= -81 )
			goto tr1;
	} else if ( (*p) > -69 ) {
		if ( -68 <= (*p) && (*p) <= -65 )
			goto tr1;
	} else
		goto tr0;
	goto st0;
st191:
	if ( ++p == pe )
		goto _test_eof191;
case 191:
	switch( (*p) ) {
		case -111: goto st192;
		case -101: goto st194;
		case -99: goto st196;
		case -97: goto st198;
	}
	if ( -112 <= (*p) && (*p) <= -65 )
		goto st173;
	goto st0;
st192:
	if ( ++p == pe )
		goto _test_eof192;
case 192:
	if ( (*p) == -126 )
		goto st193;
	if ( (*p) <= -65 )
		goto st130;
	goto st0;
st193:
	if ( ++p == pe )
		goto _test_eof193;
case 193:
	if ( (*p) == -67 )
		goto tr0;
	if ( (*p) <= -65 )
		goto tr1;
	goto st0;
st194:
	if ( ++p == pe )
		goto _test_eof194;
case 194:
	if ( (*p) == -78 )
		goto st195;
	if ( (*p) <= -65 )
		goto st130;
	goto st0;
st195:
	if ( ++p == pe )
		goto _test_eof195;
case 195:
	if ( (*p) < -96 ) {
		if ( (*p) <= -97 )
			goto tr1;
	} else if ( (*p) > -93 ) {
		if ( -92 <= (*p) && (*p) <= -65 )
			goto tr1;
	} else
		goto tr0;
	goto st0;
st196:
	if ( ++p == pe )
		goto _test_eof196;
case 196:
	if ( (*p) == -123 )
		goto st197;
	if ( (*p) <= -65 )
		goto st130;
	goto st0;
st197:
	if ( ++p == pe )
		goto _test_eof197;
case 197:
	if ( (*p) < -77 ) {
		if ( (*p) <= -78 )
			goto tr1;
	} else if ( (*p) > -70 ) {
		if ( -69 <= (*p) && (*p) <= -65 )
			goto tr1;
	} else
		goto tr0;
	goto st0;
st198:
	if ( ++p == pe )
		goto _test_eof198;
case 198:
	if ( (*p) == -121 )
		goto st199;
	if ( (*p) <= -65 )
		goto st130;
	goto st0;
st199:
	if ( ++p == pe )
		goto _test_eof199;
case 199:
	if ( (*p) > -91 ) {
		if ( -90 <= (*p) && (*p) <= -65 )
			goto tr166;
	} else
		goto tr1;
	goto st0;
tr166:
#line 1 "NONE"
	{te = p+1;}
	goto st214;
st214:
	if ( ++p == pe )
		goto _test_eof214;
case 214:
#line 2711 "/tmp/DIwPodyP1J/output"
	switch( (*p) ) {
		case -52: goto st2;
		case -51: goto st3;
		case -46: goto st4;
		case -42: goto st5;
		case -41: goto st6;
		case -40: goto st7;
		case -39: goto st8;
		case -37: goto st9;
		case -36: goto st10;
		case -35: goto st11;
		case -34: goto st12;
		case -33: goto st13;
		case -32: goto st14;
		case -31: goto st41;
		case -30: goto st64;
		case -29: goto st70;
		case -22: goto st73;
		case -17: goto st89;
		case -16: goto st200;
		case -13: goto st128;
	}
	goto tr189;
st200:
	if ( ++p == pe )
		goto _test_eof200;
case 200:
	switch( (*p) ) {
		case -112: goto st94;
		case -111: goto st100;
		case -106: goto st115;
		case -101: goto st120;
		case -99: goto st122;
		case -98: goto st126;
		case -97: goto st201;
	}
	goto tr3;
st201:
	if ( ++p == pe )
		goto _test_eof201;
case 201:
	if ( (*p) == -121 )
		goto st202;
	goto tr3;
st202:
	if ( ++p == pe )
		goto _test_eof202;
case 202:
	if ( -90 <= (*p) && (*p) <= -65 )
		goto tr166;
	goto tr3;
st203:
	if ( ++p == pe )
		goto _test_eof203;
case 203:
	if ( (*p) <= -65 )
		goto st173;
	goto st0;
st204:
	if ( ++p == pe )
		goto _test_eof204;
case 204:
	if ( (*p) == -96 )
		goto st205;
	if ( (*p) <= -65 )
		goto st173;
	goto st0;
st205:
	if ( ++p == pe )
		goto _test_eof205;
case 205:
	if ( (*p) == -121 )
		goto st207;
	if ( (*p) < -124 ) {
		if ( (*p) <= -125 )
			goto st206;
	} else if ( (*p) > -122 ) {
		if ( -120 <= (*p) && (*p) <= -65 )
			goto st206;
	} else
		goto st130;
	goto st0;
st206:
	if ( ++p == pe )
		goto _test_eof206;
case 206:
	if ( (*p) <= -65 )
		goto tr0;
	goto st0;
st207:
	if ( ++p == pe )
		goto _test_eof207;
case 207:
	if ( (*p) > -81 ) {
		if ( -80 <= (*p) && (*p) <= -65 )
			goto tr0;
	} else
		goto tr1;
	goto st0;
st208:
	if ( ++p == pe )
		goto _test_eof208;
case 208:
	if ( (*p) <= -113 )
		goto st173;
	goto st0;
tr188:
#line 1 "NONE"
	{te = p+1;}
	goto st215;
st215:
	if ( ++p == pe )
		goto _test_eof215;
case 215:
#line 2826 "/tmp/DIwPodyP1J/output"
	switch( (*p) ) {
		case -52: goto st2;
		case -51: goto st3;
		case -46: goto st4;
		case -42: goto st5;
		case -41: goto st6;
		case -40: goto st7;
		case -39: goto st8;
		case -37: goto st9;
		case -36: goto st10;
		case -35: goto st11;
		case -34: goto st12;
		case -33: goto st13;
		case -32: goto st14;
		case -31: goto st41;
		case -30: goto st64;
		case -29: goto st70;
		case -22: goto st73;
		case -17: goto st89;
		case -16: goto st93;
		case -13: goto st128;
		case 10: goto tr218;
	}
	goto tr189;
	}
	_test_eof209: cs = 209; goto _test_eof; 
	_test_eof1: cs = 1; goto _test_eof; 
	_test_eof210: cs = 210; goto _test_eof; 
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
	_test_eof211: cs = 211; goto _test_eof; 
	_test_eof137: cs = 137; goto _test_eof; 
	_test_eof138: cs = 138; goto _test_eof; 
	_test_eof139: cs = 139; goto _test_eof; 
	_test_eof212: cs = 212; goto _test_eof; 
	_test_eof140: cs = 140; goto _test_eof; 
	_test_eof141: cs = 141; goto _test_eof; 
	_test_eof142: cs = 142; goto _test_eof; 
	_test_eof213: cs = 213; goto _test_eof; 
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
	_test_eof214: cs = 214; goto _test_eof; 
	_test_eof200: cs = 200; goto _test_eof; 
	_test_eof201: cs = 201; goto _test_eof; 
	_test_eof202: cs = 202; goto _test_eof; 
	_test_eof203: cs = 203; goto _test_eof; 
	_test_eof204: cs = 204; goto _test_eof; 
	_test_eof205: cs = 205; goto _test_eof; 
	_test_eof206: cs = 206; goto _test_eof; 
	_test_eof207: cs = 207; goto _test_eof; 
	_test_eof208: cs = 208; goto _test_eof; 
	_test_eof215: cs = 215; goto _test_eof; 

	_test_eof: {}
	if ( p == eof )
	{
	switch ( cs ) {
	case 210: goto tr189;
	case 2: goto tr3;
	case 3: goto tr3;
	case 4: goto tr3;
	case 5: goto tr3;
	case 6: goto tr3;
	case 7: goto tr3;
	case 8: goto tr3;
	case 9: goto tr3;
	case 10: goto tr3;
	case 11: goto tr3;
	case 12: goto tr3;
	case 13: goto tr3;
	case 14: goto tr3;
	case 15: goto tr3;
	case 16: goto tr3;
	case 17: goto tr3;
	case 18: goto tr3;
	case 19: goto tr3;
	case 20: goto tr3;
	case 21: goto tr3;
	case 22: goto tr3;
	case 23: goto tr3;
	case 24: goto tr3;
	case 25: goto tr3;
	case 26: goto tr3;
	case 27: goto tr3;
	case 28: goto tr3;
	case 29: goto tr3;
	case 30: goto tr3;
	case 31: goto tr3;
	case 32: goto tr3;
	case 33: goto tr3;
	case 34: goto tr3;
	case 35: goto tr3;
	case 36: goto tr3;
	case 37: goto tr3;
	case 38: goto tr3;
	case 39: goto tr3;
	case 40: goto tr3;
	case 41: goto tr3;
	case 42: goto tr3;
	case 43: goto tr3;
	case 44: goto tr3;
	case 45: goto tr3;
	case 46: goto tr3;
	case 47: goto tr3;
	case 48: goto tr3;
	case 49: goto tr3;
	case 50: goto tr3;
	case 51: goto tr3;
	case 52: goto tr3;
	case 53: goto tr3;
	case 54: goto tr3;
	case 55: goto tr3;
	case 56: goto tr3;
	case 57: goto tr3;
	case 58: goto tr3;
	case 59: goto tr3;
	case 60: goto tr3;
	case 61: goto tr3;
	case 62: goto tr3;
	case 63: goto tr3;
	case 64: goto tr3;
	case 65: goto tr3;
	case 66: goto tr3;
	case 67: goto tr3;
	case 68: goto tr3;
	case 69: goto tr3;
	case 70: goto tr3;
	case 71: goto tr3;
	case 72: goto tr3;
	case 73: goto tr3;
	case 74: goto tr3;
	case 75: goto tr3;
	case 76: goto tr3;
	case 77: goto tr3;
	case 78: goto tr3;
	case 79: goto tr3;
	case 80: goto tr3;
	case 81: goto tr3;
	case 82: goto tr3;
	case 83: goto tr3;
	case 84: goto tr3;
	case 85: goto tr3;
	case 86: goto tr3;
	case 87: goto tr3;
	case 88: goto tr3;
	case 89: goto tr3;
	case 90: goto tr3;
	case 91: goto tr3;
	case 92: goto tr3;
	case 93: goto tr3;
	case 94: goto tr3;
	case 95: goto tr3;
	case 96: goto tr3;
	case 97: goto tr3;
	case 98: goto tr3;
	case 99: goto tr3;
	case 100: goto tr3;
	case 101: goto tr3;
	case 102: goto tr3;
	case 103: goto tr3;
	case 104: goto tr3;
	case 105: goto tr3;
	case 106: goto tr3;
	case 107: goto tr3;
	case 108: goto tr3;
	case 109: goto tr3;
	case 110: goto tr3;
	case 111: goto tr3;
	case 112: goto tr3;
	case 113: goto tr3;
	case 114: goto tr3;
	case 115: goto tr3;
	case 116: goto tr3;
	case 117: goto tr3;
	case 118: goto tr3;
	case 119: goto tr3;
	case 120: goto tr3;
	case 121: goto tr3;
	case 122: goto tr3;
	case 123: goto tr3;
	case 124: goto tr3;
	case 125: goto tr3;
	case 126: goto tr3;
	case 127: goto tr3;
	case 128: goto tr3;
	case 129: goto tr3;
	case 211: goto tr189;
	case 137: goto tr3;
	case 138: goto tr3;
	case 139: goto tr3;
	case 212: goto tr189;
	case 140: goto tr3;
	case 141: goto tr3;
	case 142: goto tr3;
	case 213: goto tr189;
	case 143: goto tr3;
	case 144: goto tr3;
	case 145: goto tr3;
	case 146: goto tr3;
	case 147: goto tr3;
	case 148: goto tr3;
	case 149: goto tr3;
	case 150: goto tr3;
	case 151: goto tr3;
	case 152: goto tr3;
	case 153: goto tr3;
	case 154: goto tr3;
	case 155: goto tr3;
	case 156: goto tr3;
	case 157: goto tr3;
	case 158: goto tr3;
	case 159: goto tr3;
	case 160: goto tr3;
	case 161: goto tr3;
	case 162: goto tr3;
	case 163: goto tr3;
	case 164: goto tr3;
	case 165: goto tr3;
	case 214: goto tr189;
	case 200: goto tr3;
	case 201: goto tr3;
	case 202: goto tr3;
	case 215: goto tr189;
	}
	}

	_out: {}
	}

#line 86 "/tmp/DIwPodyP1J/input"


  done:

  if (cs < egc_scanner_first_final) {
    error_occurred = 1;
    cut_len = p - input;
  }

  *truncation_required_out = truncation_required;
  *cut_len_out = cut_len;
  *error_occurred_out = error_occurred;
}






static SV *_truncate(SV *input, long trunc_len, SV *ellipsis, int in_place, const char *func_name) {
  size_t trunc_size;
  char *input_p, *ellipsis_p;
  size_t input_len, ellipsis_len;
  size_t cut_len;
  int truncation_required, error_occurred;
  SV *output;
  char *output_p;
  size_t output_len;

  SvUPGRADE(input, SVt_PV);
  if (!SvPOK(input)) croak("need to pass a string in as first argument to %s", func_name);

  input_len = SvCUR(input);
  input_p = SvPV(input, input_len);

  if (trunc_len < 0) croak("trunc size argument to %s must be >= 0", func_name);
  trunc_size = (size_t) trunc_len;

  if (ellipsis == NULL) {
    ellipsis_len = 3;
    ellipsis_p = "\xE2\x80\xA6"; // UTF-8 encoded U+2026 ellipsis character
  } else {
    SvUPGRADE(ellipsis, SVt_PV);
    if (!SvPOK(ellipsis)) croak("ellipsis must be a string in 3rd argument to %s", func_name);

    ellipsis_len = SvCUR(ellipsis);
    ellipsis_p = SvPV(ellipsis, ellipsis_len);

    if (!is_utf8_string(ellipsis_p, ellipsis_len)) croak("ellipsis must be utf-8 encoded in 3rd argument to %s", func_name);
  }

  if (ellipsis_len > trunc_size) croak("length of ellipsis is longer than truncation length in %s", func_name);
  trunc_size -= ellipsis_len;

  _scan_egc(input_p, input_len, trunc_size, &truncation_required, &cut_len, &error_occurred);

  if (error_occurred) croak("input string not valid UTF-8 (detected at byte offset %lu in %s)", cut_len, func_name);

  output_len = cut_len + ellipsis_len;

  if (input_len <= trunc_len) {
    truncation_required = 0;
    output_len = input_len;
  }

  if (in_place) {
    output = input;

    if (truncation_required) {
      SvGROW(output, output_len);
      SvCUR_set(output, output_len);
      output_p = SvPV(output, output_len);

      memcpy(output_p + cut_len, ellipsis_p, ellipsis_len);
    }
  } else {
    if (truncation_required) {
      output = newSVpvn("", 0);

      SvGROW(output, output_len);
      SvCUR_set(output, output_len);
      output_p = SvPV(output, output_len);

      memcpy(output_p, input_p, cut_len);
      memcpy(output_p + cut_len, ellipsis_p, ellipsis_len);
    } else {
      output = newSVpvn(input_p, input_len);
    }
  }

  SvUTF8_on(output);

  return output;
}



SV *truncate_egc(SV *input, long trunc_len, ...) {
  Inline_Stack_Vars;

  SV *ellipsis;

  const char *func_name = "truncate_egc";

  if (Inline_Stack_Items == 2) {
    ellipsis = NULL;
  } else if (Inline_Stack_Items == 3) {
    ellipsis = Inline_Stack_Item(2);
  } else {
    croak("too many items passed to %s", func_name);
  }

  return _truncate(input, trunc_len, ellipsis, 0, func_name);
}


void truncate_egc_inplace(SV *input, long trunc_len, ...) {
  Inline_Stack_Vars;

  SV *ellipsis;

  const char *func_name = "truncate_egc_inplace";

  if (SvREADONLY(input)) croak("input string can't be read-only with inplace mode at %s", func_name);

  if (Inline_Stack_Items == 2) {
    ellipsis = NULL;
  } else if (Inline_Stack_Items == 3) {
    ellipsis = Inline_Stack_Item(2);
  } else {
    croak("too many items passed to %s", func_name);
  }

  _truncate(input, trunc_len, ellipsis, 1, func_name);
}







MODULE = Unicode::Truncate  PACKAGE = Unicode::Truncate  

PROTOTYPES: DISABLE


SV *
truncate_egc (input, trunc_len, ...)
	SV *	input
	long	trunc_len
        PREINIT:
        I32* temp;
        CODE:
        temp = PL_markstack_ptr++;
        RETVAL = truncate_egc(input, trunc_len);
        PL_markstack_ptr = temp;
        OUTPUT:
        RETVAL

void
truncate_egc_inplace (input, trunc_len, ...)
	SV *	input
	long	trunc_len
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        truncate_egc_inplace(input, trunc_len);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

