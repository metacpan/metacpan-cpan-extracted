#include "parser.h"

namespace panda { namespace uri {

// ============== RFC3986 compliant parser ===================

%%{
    machine uri_parser_ext;
    include uri_parser_base "parser.rl";
    
    action ext_chars { ext_chars = true; }
    
    query        = (pchar | "/" | "?" | ("\"" | "{" | "}" | "|") %ext_chars)* >mark %query;
    absolute_uri = scheme ":" hier_part ("?" query)? ("#" fragment)?;
    relative_ref = relative_part ("?" query)? ("#" fragment)?;
    
    uri := absolute_uri | relative_ref;
    
    write data;
}%%

bool URI::_parse_ext (const string& str, bool& authority_has_pct) {
    const char* ps  = str.data();
    const char* p   = ps;
    const char* pe  = p + str.length();
    const char* eof = pe;
    int         cs  = uri_parser_ext_start;
    size_t      mark;
    int acc = 0;
    bool ext_chars = false;
    
    %% write exec;
    
    if (ext_chars) { // we must parse and invalidate source query string to produce valid uri on output
        parse_query();
        _qstr.clear();
        ok_query();
    }
    
    return cs >= uri_parser_ext_first_final;
}

}}