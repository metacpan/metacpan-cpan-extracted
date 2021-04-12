%%{
    machine socks5_client_parser;

    action negotiate { 
        panda_log_verbose_debug("negotiate");
        if(noauth) {
            do_connect();
        } else {
            do_auth();
        }
    }
    
    action auth {
        panda_log_verbose_debug("auth");
        do_connect();
    }
    
    action connect {
        panda_log_verbose_debug("connect");
        if(rep) {
            do_error(errc::protocol_error);
            fbreak;
        }
        do_connected();
    }
    
    action auth_status {
        panda_log_verbose_debug("auth status");
        auth_status = (uint8_t)*fpc;
    }

    action noauth_auth_method {
        panda_log_verbose_debug("noauth method");
        noauth = true;
    }
    
    action userpass_auth_method {
        panda_log_verbose_debug("userpass method");
        noauth = false;
    }

    action noacceptable_auth_method {
        panda_log_verbose_debug("noacceptable method");
        do_error(errc::no_acceptable_auth_method);
        fbreak;
    }

    action ip4 {
        panda_log_verbose_debug("ip4");
    }
    
    action ip6 {
        panda_log_verbose_debug("ip6");
    }

    action atyp {
        atyp = (uint8_t)*fpc;
        panda_log_verbose_debug("atyp: " << atyp);
    }
    
    action rep {
        rep = (uint8_t)*fpc;
        panda_log_verbose_debug("rep: " << rep);
    }
    
    action error {
        do_error(errc::protocol_error);
    }
    
    ver=0x05;
    byte=any;

    auth_method = 0x00 @noauth_auth_method | 0x02 @userpass_auth_method | 0xFF @noacceptable_auth_method;
    negotiate_reply := (ver auth_method) @negotiate $!error;   

    auth_ver = 0x01;
    auth_status = any @auth_status;
    auth_reply := (auth_ver auth_status) @auth @!error;

    rep = 0x00;
    rsv = 0x00;
    atyp = byte @atyp;
    dst_addr_ip4 = 4*byte $ip4;
    dst_addr_ip6 = 16*byte $ip6;
    dst_addr =  dst_addr_ip4 when {atyp==0x01} | 
                dst_addr_ip6 when {atyp==0x04};
    dst_port = 2*byte;
    connect_reply := (ver rep @rep rsv atyp dst_addr dst_port) @connect @!error;   
}%%

#if defined(MACHINE_DATA)
#undef MACHINE_DATA
%%{
    write data;
}%%
#endif

#if defined(MACHINE_INIT)
#undef MACHINE_INIT
%%{
    write init;
}%%
#endif

#if defined(MACHINE_EXEC)
#undef MACHINE_EXEC
%%{
    write exec;
}%%
#endif

