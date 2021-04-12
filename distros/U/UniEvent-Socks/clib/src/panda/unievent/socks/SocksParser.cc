
#line 1 "src/panda/unievent/socks/SocksParser.rl"

#line 89 "src/panda/unievent/socks/SocksParser.rl"


#if defined(MACHINE_DATA)
#undef MACHINE_DATA

#line 11 "src/panda/unievent/socks/SocksParser.cc"
static const int socks5_client_parser_start = 1;
static const int socks5_client_parser_first_final = 13;
static const int socks5_client_parser_error = 0;

static const int socks5_client_parser_en_negotiate_reply = 9;
static const int socks5_client_parser_en_auth_reply = 11;
static const int socks5_client_parser_en_connect_reply = 1;


#line 95 "src/panda/unievent/socks/SocksParser.rl"

#endif

#if defined(MACHINE_INIT)
#undef MACHINE_INIT

#line 28 "src/panda/unievent/socks/SocksParser.cc"
	{
	cs = socks5_client_parser_start;
	}

#line 102 "src/panda/unievent/socks/SocksParser.rl"

#endif

#if defined(MACHINE_EXEC)
#undef MACHINE_EXEC

#line 40 "src/panda/unievent/socks/SocksParser.cc"
	{
	short _widec;
	if ( p == pe )
		goto _test_eof;
	switch ( cs )
	{
case 1:
	if ( (*p) == 5 )
		goto st2;
	goto tr0;
tr0:
#line 66 "src/panda/unievent/socks/SocksParser.rl"
	{
        do_error(errc::protocol_error);
    }
	goto st0;
#line 57 "src/panda/unievent/socks/SocksParser.cc"
st0:
cs = 0;
	goto _out;
st2:
	if ( ++p == pe )
		goto _test_eof2;
case 2:
	if ( (*p) == 0 )
		goto tr2;
	goto tr0;
tr2:
#line 61 "src/panda/unievent/socks/SocksParser.rl"
	{
        rep = (uint8_t)*p;
        panda_log_verbose_debug("rep: " << rep);
    }
	goto st3;
st3:
	if ( ++p == pe )
		goto _test_eof3;
case 3:
#line 79 "src/panda/unievent/socks/SocksParser.cc"
	if ( (*p) == 0 )
		goto st4;
	goto tr0;
st4:
	if ( ++p == pe )
		goto _test_eof4;
case 4:
	goto tr4;
tr4:
#line 56 "src/panda/unievent/socks/SocksParser.rl"
	{
        atyp = (uint8_t)*p;
        panda_log_verbose_debug("atyp: " << atyp);
    }
	goto st5;
st5:
	if ( ++p == pe )
		goto _test_eof5;
case 5:
#line 99 "src/panda/unievent/socks/SocksParser.cc"
	_widec = (*p);
	if ( (*p) < 5 ) {
		if ( (*p) > 3 ) {
			if ( 4 <= (*p) && (*p) <= 4 ) {
				_widec = (short)(1152 + ((*p) - -128));
				if ( 
#line 85 "src/panda/unievent/socks/SocksParser.rl"
atyp==0x01 ) _widec += 256;
				if ( 
#line 86 "src/panda/unievent/socks/SocksParser.rl"
atyp==0x04 ) _widec += 512;
			}
		} else {
			_widec = (short)(1152 + ((*p) - -128));
			if ( 
#line 85 "src/panda/unievent/socks/SocksParser.rl"
atyp==0x01 ) _widec += 256;
			if ( 
#line 86 "src/panda/unievent/socks/SocksParser.rl"
atyp==0x04 ) _widec += 512;
		}
	} else if ( (*p) > 15 ) {
		if ( (*p) > 16 ) {
			if ( 17 <= (*p) )
 {				_widec = (short)(1152 + ((*p) - -128));
				if ( 
#line 85 "src/panda/unievent/socks/SocksParser.rl"
atyp==0x01 ) _widec += 256;
				if ( 
#line 86 "src/panda/unievent/socks/SocksParser.rl"
atyp==0x04 ) _widec += 512;
			}
		} else if ( (*p) >= 16 ) {
			_widec = (short)(1152 + ((*p) - -128));
			if ( 
#line 85 "src/panda/unievent/socks/SocksParser.rl"
atyp==0x01 ) _widec += 256;
			if ( 
#line 86 "src/panda/unievent/socks/SocksParser.rl"
atyp==0x04 ) _widec += 512;
		}
	} else {
		_widec = (short)(1152 + ((*p) - -128));
		if ( 
#line 85 "src/panda/unievent/socks/SocksParser.rl"
atyp==0x01 ) _widec += 256;
		if ( 
#line 86 "src/panda/unievent/socks/SocksParser.rl"
atyp==0x04 ) _widec += 512;
	}
	switch( _widec ) {
		case 1540: goto tr6;
		case 1808: goto tr8;
		case 2052: goto tr10;
		case 2064: goto tr11;
	}
	if ( _widec < 1664 ) {
		if ( 1408 <= _widec && _widec <= 1663 )
			goto tr5;
	} else if ( _widec > 1919 ) {
		if ( 1920 <= _widec && _widec <= 2175 )
			goto tr9;
	} else
		goto tr7;
	goto tr0;
tr5:
#line 48 "src/panda/unievent/socks/SocksParser.rl"
	{
        panda_log_verbose_debug("ip4");
    }
	goto st6;
tr7:
#line 52 "src/panda/unievent/socks/SocksParser.rl"
	{
        panda_log_verbose_debug("ip6");
    }
	goto st6;
tr9:
#line 48 "src/panda/unievent/socks/SocksParser.rl"
	{
        panda_log_verbose_debug("ip4");
    }
#line 52 "src/panda/unievent/socks/SocksParser.rl"
	{
        panda_log_verbose_debug("ip6");
    }
	goto st6;
st6:
	if ( ++p == pe )
		goto _test_eof6;
case 6:
#line 191 "src/panda/unievent/socks/SocksParser.cc"
	if ( (*p) == 2 )
		goto tr13;
	goto tr12;
tr12:
#line 18 "src/panda/unievent/socks/SocksParser.rl"
	{
        panda_log_verbose_debug("connect");
        if(rep) {
            do_error(errc::protocol_error);
            {p++; cs = 13; goto _out;}
        }
        do_connected();
    }
	goto st13;
st13:
	if ( ++p == pe )
		goto _test_eof13;
case 13:
#line 210 "src/panda/unievent/socks/SocksParser.cc"
	goto st0;
tr13:
#line 18 "src/panda/unievent/socks/SocksParser.rl"
	{
        panda_log_verbose_debug("connect");
        if(rep) {
            do_error(errc::protocol_error);
            {p++; cs = 14; goto _out;}
        }
        do_connected();
    }
	goto st14;
tr14:
#line 48 "src/panda/unievent/socks/SocksParser.rl"
	{
        panda_log_verbose_debug("ip4");
    }
#line 18 "src/panda/unievent/socks/SocksParser.rl"
	{
        panda_log_verbose_debug("connect");
        if(rep) {
            do_error(errc::protocol_error);
            {p++; cs = 14; goto _out;}
        }
        do_connected();
    }
	goto st14;
tr16:
#line 52 "src/panda/unievent/socks/SocksParser.rl"
	{
        panda_log_verbose_debug("ip6");
    }
#line 18 "src/panda/unievent/socks/SocksParser.rl"
	{
        panda_log_verbose_debug("connect");
        if(rep) {
            do_error(errc::protocol_error);
            {p++; cs = 14; goto _out;}
        }
        do_connected();
    }
	goto st14;
st14:
	if ( ++p == pe )
		goto _test_eof14;
case 14:
#line 257 "src/panda/unievent/socks/SocksParser.cc"
	if ( (*p) == 2 )
		goto tr13;
	goto tr12;
tr6:
#line 48 "src/panda/unievent/socks/SocksParser.rl"
	{
        panda_log_verbose_debug("ip4");
    }
	goto st7;
tr10:
#line 48 "src/panda/unievent/socks/SocksParser.rl"
	{
        panda_log_verbose_debug("ip4");
    }
#line 52 "src/panda/unievent/socks/SocksParser.rl"
	{
        panda_log_verbose_debug("ip6");
    }
	goto st7;
st7:
	if ( ++p == pe )
		goto _test_eof7;
case 7:
#line 281 "src/panda/unievent/socks/SocksParser.cc"
	_widec = (*p);
	if ( (*p) < 4 ) {
		if ( (*p) <= 3 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 85 "src/panda/unievent/socks/SocksParser.rl"
atyp==0x01 ) _widec += 256;
		}
	} else if ( (*p) > 4 ) {
		if ( 5 <= (*p) )
 {			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 85 "src/panda/unievent/socks/SocksParser.rl"
atyp==0x01 ) _widec += 256;
		}
	} else {
		_widec = (short)(128 + ((*p) - -128));
		if ( 
#line 85 "src/panda/unievent/socks/SocksParser.rl"
atyp==0x01 ) _widec += 256;
	}
	switch( _widec ) {
		case 258: goto tr13;
		case 516: goto tr15;
	}
	if ( _widec > 383 ) {
		if ( 384 <= _widec && _widec <= 639 )
			goto tr14;
	} else if ( _widec >= 128 )
		goto tr12;
	goto tr0;
tr15:
#line 48 "src/panda/unievent/socks/SocksParser.rl"
	{
        panda_log_verbose_debug("ip4");
    }
#line 18 "src/panda/unievent/socks/SocksParser.rl"
	{
        panda_log_verbose_debug("connect");
        if(rep) {
            do_error(errc::protocol_error);
            {p++; cs = 15; goto _out;}
        }
        do_connected();
    }
	goto st15;
st15:
	if ( ++p == pe )
		goto _test_eof15;
case 15:
#line 332 "src/panda/unievent/socks/SocksParser.cc"
	_widec = (*p);
	if ( (*p) < 4 ) {
		if ( (*p) <= 3 ) {
			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 85 "src/panda/unievent/socks/SocksParser.rl"
atyp==0x01 ) _widec += 256;
		}
	} else if ( (*p) > 4 ) {
		if ( 5 <= (*p) )
 {			_widec = (short)(128 + ((*p) - -128));
			if ( 
#line 85 "src/panda/unievent/socks/SocksParser.rl"
atyp==0x01 ) _widec += 256;
		}
	} else {
		_widec = (short)(128 + ((*p) - -128));
		if ( 
#line 85 "src/panda/unievent/socks/SocksParser.rl"
atyp==0x01 ) _widec += 256;
	}
	switch( _widec ) {
		case 258: goto tr13;
		case 516: goto tr15;
	}
	if ( _widec > 383 ) {
		if ( 384 <= _widec && _widec <= 639 )
			goto tr14;
	} else if ( _widec >= 128 )
		goto tr12;
	goto st0;
tr8:
#line 52 "src/panda/unievent/socks/SocksParser.rl"
	{
        panda_log_verbose_debug("ip6");
    }
	goto st8;
tr11:
#line 48 "src/panda/unievent/socks/SocksParser.rl"
	{
        panda_log_verbose_debug("ip4");
    }
#line 52 "src/panda/unievent/socks/SocksParser.rl"
	{
        panda_log_verbose_debug("ip6");
    }
	goto st8;
st8:
	if ( ++p == pe )
		goto _test_eof8;
case 8:
#line 384 "src/panda/unievent/socks/SocksParser.cc"
	_widec = (*p);
	if ( (*p) < 16 ) {
		if ( (*p) <= 15 ) {
			_widec = (short)(640 + ((*p) - -128));
			if ( 
#line 86 "src/panda/unievent/socks/SocksParser.rl"
atyp==0x04 ) _widec += 256;
		}
	} else if ( (*p) > 16 ) {
		if ( 17 <= (*p) )
 {			_widec = (short)(640 + ((*p) - -128));
			if ( 
#line 86 "src/panda/unievent/socks/SocksParser.rl"
atyp==0x04 ) _widec += 256;
		}
	} else {
		_widec = (short)(640 + ((*p) - -128));
		if ( 
#line 86 "src/panda/unievent/socks/SocksParser.rl"
atyp==0x04 ) _widec += 256;
	}
	switch( _widec ) {
		case 770: goto tr13;
		case 1040: goto tr17;
	}
	if ( _widec > 895 ) {
		if ( 896 <= _widec && _widec <= 1151 )
			goto tr16;
	} else if ( _widec >= 640 )
		goto tr12;
	goto tr0;
tr17:
#line 52 "src/panda/unievent/socks/SocksParser.rl"
	{
        panda_log_verbose_debug("ip6");
    }
#line 18 "src/panda/unievent/socks/SocksParser.rl"
	{
        panda_log_verbose_debug("connect");
        if(rep) {
            do_error(errc::protocol_error);
            {p++; cs = 16; goto _out;}
        }
        do_connected();
    }
	goto st16;
st16:
	if ( ++p == pe )
		goto _test_eof16;
case 16:
#line 435 "src/panda/unievent/socks/SocksParser.cc"
	_widec = (*p);
	if ( (*p) < 16 ) {
		if ( (*p) <= 15 ) {
			_widec = (short)(640 + ((*p) - -128));
			if ( 
#line 86 "src/panda/unievent/socks/SocksParser.rl"
atyp==0x04 ) _widec += 256;
		}
	} else if ( (*p) > 16 ) {
		if ( 17 <= (*p) )
 {			_widec = (short)(640 + ((*p) - -128));
			if ( 
#line 86 "src/panda/unievent/socks/SocksParser.rl"
atyp==0x04 ) _widec += 256;
		}
	} else {
		_widec = (short)(640 + ((*p) - -128));
		if ( 
#line 86 "src/panda/unievent/socks/SocksParser.rl"
atyp==0x04 ) _widec += 256;
	}
	switch( _widec ) {
		case 770: goto tr13;
		case 1040: goto tr17;
	}
	if ( _widec > 895 ) {
		if ( 896 <= _widec && _widec <= 1151 )
			goto tr16;
	} else if ( _widec >= 640 )
		goto tr12;
	goto st0;
case 9:
	if ( (*p) == 5 )
		goto st10;
	goto tr0;
st10:
	if ( ++p == pe )
		goto _test_eof10;
case 10:
	switch( (*p) ) {
		case -1: goto tr19;
		case 0: goto tr20;
		case 2: goto tr21;
	}
	goto tr0;
tr19:
#line 42 "src/panda/unievent/socks/SocksParser.rl"
	{
        panda_log_verbose_debug("noacceptable method");
        do_error(errc::no_acceptable_auth_method);
        {p++; cs = 17; goto _out;}
    }
#line 4 "src/panda/unievent/socks/SocksParser.rl"
	{ 
        panda_log_verbose_debug("negotiate");
        if(noauth) {
            do_connect();
        } else {
            do_auth();
        }
    }
	goto st17;
tr20:
#line 32 "src/panda/unievent/socks/SocksParser.rl"
	{
        panda_log_verbose_debug("noauth method");
        noauth = true;
    }
#line 4 "src/panda/unievent/socks/SocksParser.rl"
	{ 
        panda_log_verbose_debug("negotiate");
        if(noauth) {
            do_connect();
        } else {
            do_auth();
        }
    }
	goto st17;
tr21:
#line 37 "src/panda/unievent/socks/SocksParser.rl"
	{
        panda_log_verbose_debug("userpass method");
        noauth = false;
    }
#line 4 "src/panda/unievent/socks/SocksParser.rl"
	{ 
        panda_log_verbose_debug("negotiate");
        if(noauth) {
            do_connect();
        } else {
            do_auth();
        }
    }
	goto st17;
st17:
	if ( ++p == pe )
		goto _test_eof17;
case 17:
#line 534 "src/panda/unievent/socks/SocksParser.cc"
	goto tr0;
case 11:
	if ( (*p) == 1 )
		goto st12;
	goto tr0;
st12:
	if ( ++p == pe )
		goto _test_eof12;
case 12:
	goto tr23;
tr23:
#line 27 "src/panda/unievent/socks/SocksParser.rl"
	{
        panda_log_verbose_debug("auth status");
        auth_status = (uint8_t)*p;
    }
#line 13 "src/panda/unievent/socks/SocksParser.rl"
	{
        panda_log_verbose_debug("auth");
        do_connect();
    }
	goto st18;
st18:
	if ( ++p == pe )
		goto _test_eof18;
case 18:
#line 561 "src/panda/unievent/socks/SocksParser.cc"
	goto st0;
	}
	_test_eof2: cs = 2; goto _test_eof; 
	_test_eof3: cs = 3; goto _test_eof; 
	_test_eof4: cs = 4; goto _test_eof; 
	_test_eof5: cs = 5; goto _test_eof; 
	_test_eof6: cs = 6; goto _test_eof; 
	_test_eof13: cs = 13; goto _test_eof; 
	_test_eof14: cs = 14; goto _test_eof; 
	_test_eof7: cs = 7; goto _test_eof; 
	_test_eof15: cs = 15; goto _test_eof; 
	_test_eof8: cs = 8; goto _test_eof; 
	_test_eof16: cs = 16; goto _test_eof; 
	_test_eof10: cs = 10; goto _test_eof; 
	_test_eof17: cs = 17; goto _test_eof; 
	_test_eof12: cs = 12; goto _test_eof; 
	_test_eof18: cs = 18; goto _test_eof; 

	_test_eof: {}
	if ( p == eof )
	{
	switch ( cs ) {
	case 1: 
	case 2: 
	case 3: 
	case 4: 
	case 5: 
	case 6: 
	case 7: 
	case 8: 
	case 9: 
	case 10: 
	case 11: 
	case 12: 
#line 66 "src/panda/unievent/socks/SocksParser.rl"
	{
        do_error(errc::protocol_error);
    }
	break;
#line 601 "src/panda/unievent/socks/SocksParser.cc"
	}
	}

	_out: {}
	}

#line 109 "src/panda/unievent/socks/SocksParser.rl"

#endif

