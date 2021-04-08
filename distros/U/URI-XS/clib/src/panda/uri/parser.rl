#include "parser.h"

namespace panda { namespace uri {

// ============== RFC3986 compliant parser ===================

%%{
    machine uri_parser_base;
    
    action mark {
        mark = p - ps;
    }
    
    action digit {
        acc *= 10;
        acc += *p - '0';
    }
    
    action scheme   { SAVE(_scheme); }
    action host     { SAVE(_host); }
    action port     { NSAVE(_port); }
    action userinfo { SAVE(_user_info); }
    action path     { SAVE(_path); }
    action query    { SAVE(_qstr); }
    action fragment { SAVE(_fragment); }
    
    action auth_pct { authority_has_pct = true; }
    
    sub_delim   = "!" | "$" | "&" | "'" | "(" | ")" | "*" | "+" | "," | ";" | "=";
    gen_delim   = ":" | "/" | "?" | "#" | "[" | "]" | "@";
    reserved    = sub_delim | gen_delim;
    unreserved  = alnum | "-" | "." | "_" | "~";
    
    pct_encoded = "%" xdigit{2};
    pchar       = unreserved | pct_encoded | sub_delim | ":" | "@";
    
    scheme = (alpha (alnum | "+" | "-" | "." )*) >mark %scheme;
    
    userinfo = ((unreserved | pct_encoded >auth_pct | sub_delim | ":" )*) >mark %userinfo;
    
    IPvFuture   = "v" xdigit+ "." (unreserved | sub_delim | ":")+;

    dec_octet   = digit              # 0-9
                | "1".."9" digit     # 10-99
                | "1" digit{2}       # 100-199
                | "2" "0".."4" digit # 200-240
                | "25" "0".."5";     # 250-255
    IPv4address = (dec_octet "."){3} dec_octet;

    h16         = xdigit{1,4};                 # 16 bits of address represented in hexadecimal
    ls32        = (h16 ":" h16) | IPv4address; # least-significant 32 bits of address
    IPv6address =                                (h16 ":"){6} ls32
                    |                       "::" (h16 ":"){5} ls32
                    | (               h16)? "::" (h16 ":"){4} ls32
                    | ((h16 ":")?     h16)? "::" (h16 ":"){3} ls32
                    | ((h16 ":"){0,2} h16)? "::" (h16 ":"){2} ls32
                    | ((h16 ":"){0,3} h16)? "::" (h16 ":"){1} ls32
                    | ((h16 ":"){0,4} h16)? "::"              ls32
                    | ((h16 ":"){0,5} h16)? "::"              h16
                    | ((h16 ":"){0,6} h16)? "::";
                    
    IP_literal = "[" (IPv6address | IPvFuture) "]";
    reg_name   = (unreserved | pct_encoded >auth_pct | sub_delim)*;
    host       = (IP_literal | IPv4address | reg_name) >mark %host;
    port       = digit* $digit %port;
    authority  = (userinfo "@")? host (":" port)?;
    
    segment       = pchar*;
    segment_nz    = pchar+;
    segment_nz_nc = (unreserved | pct_encoded | sub_delim | "@")+; # non-zero-length segment without any colon ":"
    path_abempty  = ("/" segment)* >mark %path;
    path_absolute = ("/" (segment_nz ("/" segment)*)?) >mark %path;
    path_noscheme = (segment_nz_nc ("/" segment)*) >mark %path;
    path_rootless = (segment_nz ("/" segment)*) >mark %path;
    path_empty    = ""; # zero characters
    path          = path_abempty  # begins with "/" or is empty
                  | path_absolute # begins with "/" but not "//"
                  | path_noscheme # begins with a non-colon segment
                  | path_rootless # begins with a segment
                  | path_empty;   # zero characters

    hier_part = "//" authority path_abempty | path_absolute | path_rootless | path_empty;

    fragment = (pchar | "/" | "?")* >mark %fragment;

    relative_part = "//" authority path_abempty | path_absolute | path_noscheme | path_empty;
}%%

%%{ 
    machine uri_parser;
    include uri_parser_base;

    query        = (pchar | "/" | "?")* >mark %query;
    absolute_uri = scheme ":" hier_part ("?" query)? ("#" fragment)?;
    relative_ref = relative_part ("?" query)? ("#" fragment)?;
    
    uri := absolute_uri | relative_ref;
    
    write data;
}%%

#define SAVE(dest)  dest = str.substr(mark, p - ps - mark);
#define NSAVE(dest) dest = acc; acc = 0

bool URI::_parse (const string& str, bool& authority_has_pct) {
    const char* ps  = str.data();
    const char* p   = ps;
    const char* pe  = p + str.length();
    const char* eof = pe;
    int         cs  = uri_parser_start;
    size_t      mark;
    int acc = 0;
    
    %% write exec;
    
    return cs >= uri_parser_first_final;
}

}}