/** HTPL Macro parser **********************************
 ** This file is created automatically by htpl-crp.pl **
 ** Do not attempt to edit *****************************/

#define __HTPARSE__
#include "htpl.h"
#include "htpl-sh.h"
#include "perf.h"

#define RETURN(x) {int v = (x); destroypersist(); return v;}
#define numtokens (persist->tokens->num)

int parse_htpl_graph(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    printcode("{\n");
    if (numtokens < 3) RETURN(croak("%sGRAPH called with %d arguments, minimum needed is 3", (untag ? "/" : ""), numtokens))
    if (!done) {
        done = 1;
        printcode("use HTML::HTPL::Graph;\n");
    }
    printcode("	my $g = new HTML::HTPL::Graph;\n");
    printfcode(" $g->set('data' => [${\"%s\"}->project(\"%s\")]);\n", gettoken(1), gettoken(2));
    printfcode(" $g->set('labels' => [${\"%s\"}->project(\"%s\")]);\n", gettoken(1), gettoken(3));
    if (numtokens >= 4)  {
        printfcode(" $g->set('width' => %s);\n", gettoken(4));
    }
    if (numtokens >= 5)  {
        printfcode(" $g->set('cols' => %s);\n", gettoken(5));
    }
    if (numtokens >= 6)  {
        printfcode(" $g->set('legend' => [split(/:/, \"%s\")]);\n", gettokenlist(6, " ", "", ""));
    }
    printcode("	print $g->ashtml;\n");
    printcode("}\n");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_combobox(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    nesting++;
    if (nesting > 1) RETURN(croak("Infinite loop in COMBOBOX"))
    kludge_reunifying = 1;
    asprintf(&buff, "SERVBOXEN DECIDE 0 %s", gettokenlist(1, " ", "", ""));
    kludge_reunifying = 0;
    nest++;
    code = parse_htpl(buff, untag);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);

    nesting = 0;
    RETURN(1)
}

int parse_htpl_fetchit(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 1) RETURN(croak("%sFETCHIT called with %d arguments, minimum needed is 1", (untag ? "/" : ""), numtokens))
    if (numtokens > 1) RETURN(croak("%sFETCHIT called with %d arguments, maximum needed is 1", (untag ? "/" : ""), numtokens))
    printfcode("${\"%s\"}->fetch;\n", gettoken(1));
    nesting = 0;
    RETURN(1)
}

int parse_htpl_catch(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (!currscope) RETURN(croak("Unexpected CATCH"))
    if (currscope->scope != scope_try && currscope->scope != scope_catch) RETURN(croak("Now in scope %s from %d and met CATCH, expecting: try,catch", scope_names[currscope->scope], currscope->nline))
    popscope();
    pushscope(scope_catch, 0);
    printcode("};\n");
    if (numtokens <= 0)  {
        printcode("$__htpl_default_handler = sub {$_ = shift; \n");
    }
    if (numtokens >= 1)  {
        printfcode("$__htpl_handler{\"%s\"} = sub {$_ = shift; \n", gettokenlist(1, " ", "", ""));
    }
    nesting = 0;
    RETURN(1)
}

int parse_htpl_merge(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 2) RETURN(croak("%sMERGE called with %d arguments, minimum needed is 2", (untag ? "/" : ""), numtokens))
    printfcode("foreach (%s) {\n", gettokenlist(2, ", ", "$", ""));
    printfcode(" ${\"%s\"}->append($_);\n", gettoken(1));
    printcode("}\n");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_continue(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    printcode("next;\n");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_else(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (!currscope) RETURN(croak("Unexpected ELSE"))
    if (currscope->scope != scope_if_then) RETURN(croak("Now in scope %s from %d and met ELSE, expecting: if-then", scope_names[currscope->scope], currscope->nline))
    popscope();
    pushscope(scope_if_then_else, 0);
    printcode("} else {\n");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_text_precsv(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (!nest) RETURN(0)
    if (!done) {
        done = 1;
        printcode("use HTML::HTPL::CSV;\n");
    }
    nesting = 0;
    RETURN(1)
}

int parse_htpl_text_template___fwd(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 1) RETURN(croak("%sTEXT TEMPLATE called with %d arguments, minimum needed is 1", (untag ? "/" : ""), numtokens))
    if (numtokens > 1) RETURN(croak("%sTEXT TEMPLATE called with %d arguments, maximum needed is 1", (untag ? "/" : ""), numtokens))
    printcode("{\n");
    printfcode("my $__htpl_params = \\%%%s;\n", gettoken(1));
    printcode("	&begintransaction;\n");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_text_template___rev(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    printcode("{ my $text = &endtransaction;\n");
    printcode("		 my $temp = new Template({ 'INCLUDE_PATH' => $ORIG_DIR,\n");
    printcode("			'INTERPOLATE' => 1, 'EVAL_PERL' => 1});\n");
    printcode("		$temp->process(\\$text, $__htpl_params); }\n");
    printcode("}\n");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_text_template(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (!done) {
        done = 1;
        printcode("use Template;\n");
    }
    if (!untag) RETURN(parse_htpl_text_template___fwd(stack, untag))
        else RETURN(parse_htpl_text_template___rev(stack, untag))
}

int parse_htpl_text_fixed(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 3) RETURN(croak("%sTEXT FIXED called with %d arguments, minimum needed is 3", (untag ? "/" : ""), numtokens))
    code = 1;
    kludge_reunifying = 1;
    asprintf(&buff, "TEXT PREFIXED");
    kludge_reunifying = 0;
    nest++;
    code = parse_htpl(buff, untag);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);

    printfcode("${\"%s\"} = &HTML::HTPL::Fixed'openfixed(\"%s\", %s);\n", gettoken(1), gettoken(2), numtokens >= abs(3) ? gettokenlist(3, ", ", "", "\"$s\"") : "()");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_text_read(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 2) RETURN(croak("%sTEXT READ called with %d arguments, minimum needed is 2", (untag ? "/" : ""), numtokens))
    if (numtokens > 2) RETURN(croak("%sTEXT READ called with %d arguments, maximum needed is 2", (untag ? "/" : ""), numtokens))
    printfcode("${\"%s\"} = &readfile(\"%s\");\n", gettoken(1), gettoken(2));
    nesting = 0;
    RETURN(1)
}

int parse_htpl_text_prefixed(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (!nest) RETURN(0)
    if (!done) {
        done = 1;
        printcode("use HTML::HTPL::Fixed;\n");
    }
    nesting = 0;
    RETURN(1)
}

int parse_htpl_text_records(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 3) RETURN(croak("%sTEXT RECORDS called with %d arguments, minimum needed is 3", (untag ? "/" : ""), numtokens))
    code = 1;
    kludge_reunifying = 1;
    asprintf(&buff, "TEXT PREFIXED");
    kludge_reunifying = 0;
    nest++;
    code = parse_htpl(buff, untag);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);

    printfcode("${\"%s\"} = &HTML::HTPL::Fixed'openfixed(\"%s\", \\\"IBM\", %s);\n", gettoken(1), gettoken(2), numtokens >= abs(3) ? gettokenlist(3, ", ", "", "\"$s\"") : "()");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_text_flat(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 3) RETURN(croak("%sTEXT FLAT called with %d arguments, minimum needed is 3", (untag ? "/" : ""), numtokens))
    if (!done) {
        done = 1;
        printcode("use HTML::HTPL::Flat;\n");
    }
    printfcode(" ${\"%s\"} = &HTML::HTPL::Flat'openflat(\"%s\", %s);\n", gettoken(1), gettoken(2), numtokens >= abs(3) ? gettokenlist(3, ", ", "", "\"$s\"") : "()");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_text_csv(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 2) RETURN(croak("%sTEXT CSV called with %d arguments, minimum needed is 2", (untag ? "/" : ""), numtokens))
    code = 1;
    kludge_reunifying = 1;
    asprintf(&buff, "TEXT PRECSV");
    kludge_reunifying = 0;
    nest++;
    code = parse_htpl(buff, untag);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);

    if (numtokens <= 2)  {
        printfcode("${\"%s\"} = &HTML::HTPL::CSV'opencsv(\"%s\");\n", gettoken(1), gettoken(2));
    }
    if (numtokens >= 3)  {
        printfcode("${\"%s\"} = &HTML::HTPL::CSV'opencsv(\"%s\", \"%s\", %s);\n", gettoken(1), gettoken(2), gettoken(3), numtokens >= abs(4) ? gettokenlist(4, ", ", "", "\"$s\"") : "()");
    }
    nesting = 0;
    RETURN(1)
}

int parse_htpl_text_cube(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 4) RETURN(croak("%sTEXT CUBE called with %d arguments, minimum needed is 4", (untag ? "/" : ""), numtokens))
    code = 1;
    kludge_reunifying = 1;
    asprintf(&buff, "TEXT PRECSV");
    kludge_reunifying = 0;
    nest++;
    code = parse_htpl(buff, untag);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);

    printfcode("${\"%s\"} = &HTML::HTPL::CSV'opencsv(\"%s\", [\"%s\", \"%s\"],\n", gettoken(1), gettoken(2), gettoken(3), gettoken(4));
    printfcode("%s);\n", numtokens >= abs(5) ? gettokenlist(5, ", ", "", "\"$s\"") : "()");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_text(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    eat(&stack, token);
    {
        static char *text_table[] = {"CSV",
            "CUBE",
            "FIXED",
            "FLAT",
            "PRECSV",
            "PREFIXED",
            "READ",
            "RECORDS",
            "TEMPLATE"};
        static int text_locations[] = { 6, -1, 5, -1, 1, -1, 0, 7, -1, 3, 8, -1, 2, -1, 4, -1 };
        static int text_shortcuts[] = { 0, 6, -1, -1, 9, 12, 14, -1, 2, 4 };
        static struct hash_t text_hash = {text_table,
             text_locations, text_shortcuts};

        static parser funs[] = { parse_htpl_text_csv, parse_htpl_text_cube, parse_htpl_text_fixed, parse_htpl_text_flat, parse_htpl_text_precsv, parse_htpl_text_prefixed, parse_htpl_text_read, parse_htpl_text_records, parse_htpl_text_template };
        int n;
        parser fun;
        n = search_hash(&text_hash, token, 0);
        if (n < 0) RETURN(0)
        fun = funs[n];
        RETURN(fun(stack, untag))
    }
}

int parse_htpl_connection(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 1) RETURN(croak("%sCONNECTION called with %d arguments, minimum needed is 1", (untag ? "/" : ""), numtokens))
    printfcode("        *HTML::HTPL::htpl_db_obj = \\${\"%s\"};\n", gettoken(1));
    printcode("        \n");
    if (numtokens >= 3)  {
        code = 1;
        kludge_reunifying = 1;
        asprintf(&buff, "SQL %s", gettokenlist(2, " ", "", ""));
        kludge_reunifying = 0;
        nest++;
        code = parse_htpl(buff, untag);
        nest--;
        if (!code) {
            croak("Unification of '%s' failed", buff);
            free(buff);
            RETURN(0)
        }
        free(buff);
    }
    nesting = 0;
    RETURN(1)
}

int parse_htpl_time_now(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    printcode("print scalar(localtime);\n");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_time_modified(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    printcode("print scalar(localtime(&lastmodified()));\n");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_time(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    eat(&stack, token);
    {
        static char *time_table[] = {"MODIFIED",
            "NOW"};
        static int time_locations[] = { 0, -1, 1, -1 };
        static int time_shortcuts[] = { -1, -1, -1, -1, 0, 2, -1, -1, -1, -1 };
        static struct hash_t time_hash = {time_table,
             time_locations, time_shortcuts};

        static parser funs[] = { parse_htpl_time_modified, parse_htpl_time_now };
        int n;
        parser fun;
        n = search_hash(&time_hash, token, 0);
        if (n < 0) RETURN(0)
        fun = funs[n];
        RETURN(fun(stack, untag))
    }
}

int parse_htpl_auth_create(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    printcode("use HTML::HTPL::ACL;\n");
    printcode("HTML::HTPL::ACL::CreateDDL($HTML::HTPL::htpl_db_obj->{'dbh'});\n");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_loop(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    printcode("}\n");
    if (!currscope) RETURN(croak("Unexpected LOOP"))
    if (currscope->scope != scope_fetch) RETURN(croak("Now in scope %s from %d and met LOOP, expecting: fetch", scope_names[currscope->scope], currscope->nline))
    popscope();
    nesting = 0;
    RETURN(1)
}

int parse_htpl_redirect(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 1) RETURN(croak("%sREDIRECT called with %d arguments, minimum needed is 1", (untag ? "/" : ""), numtokens))
    if (numtokens > 1) RETURN(croak("%sREDIRECT called with %d arguments, maximum needed is 1", (untag ? "/" : ""), numtokens))
    printfcode("&redirect(\"%s\");\n", gettoken(1));
    nesting = 0;
    RETURN(1)
}

int parse_htpl_auth_iflogin(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 2) RETURN(croak("%sAUTH IFLOGIN called with %d arguments, minimum needed is 2", (untag ? "/" : ""), numtokens))
    if (numtokens > 2) RETURN(croak("%sAUTH IFLOGIN called with %d arguments, maximum needed is 2", (untag ? "/" : ""), numtokens))
    code = 1;
    kludge_reunifying = 1;
    asprintf(&buff, "AUTH LOGIN %s", gettokenlist(1, " ", "", ""));
    kludge_reunifying = 0;
    nest++;
    code = parse_htpl(buff, untag);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);

    code = 1;
    kludge_reunifying = 1;
    asprintf(&buff, "AUTH IFLOGGED");
    kludge_reunifying = 0;
    nest++;
    code = parse_htpl(buff, untag);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);

    nesting = 0;
    RETURN(1)
}

int parse_htpl_auth_realm(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 1) RETURN(croak("%sAUTH REALM called with %d arguments, minimum needed is 1", (untag ? "/" : ""), numtokens))
    if (numtokens > 1) RETURN(croak("%sAUTH REALM called with %d arguments, maximum needed is 1", (untag ? "/" : ""), numtokens))
    printcode("                $HTML::HTPL::authorized = undef;\n");
    printfcode("                $REALM = \"%s\";\n", gettoken(1));
    printcode("                if ($session{'username'}) {\n");
    printcode("                        $HTML::HTPL::authorized =\n");
    printcode("$HTML::HTPL::acl->{'acl'}->IsAuthorized($session{'username'}, $REALM);\n");
    printcode("                }\n");
    printcode("        \n");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_auth_ifunauthorized___fwd(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    pushscope(scope_if_then, 0);
    printcode("unless\n");
    printcode("	($HTML::HTPL::authorized) {\n");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_auth_ifunauthorized___rev(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    nesting++;
    if (nesting > 1) RETURN(croak("Infinite loop in AUTH IFUNAUTHORIZED"))
    kludge_reunifying = 1;
    asprintf(&buff, "ENDIF");
    kludge_reunifying = 0;
    nest++;
    code = parse_htpl(buff, untag);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);

    nesting = 0;
    RETURN(1)
}

int parse_htpl_auth_ifunauthorized(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (!untag) RETURN(parse_htpl_auth_ifunauthorized___fwd(stack, untag))
        else RETURN(parse_htpl_auth_ifunauthorized___rev(stack, untag))
}

int parse_htpl_auth_iflogged___fwd(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    pushscope(scope_if_then, 0);
    printcode("if\n");
    printcode("	($session{'username'}) {\n");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_auth_iflogged___rev(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    nesting++;
    if (nesting > 1) RETURN(croak("Infinite loop in AUTH IFLOGGED"))
    kludge_reunifying = 1;
    asprintf(&buff, "ENDIF");
    kludge_reunifying = 0;
    nest++;
    code = parse_htpl(buff, untag);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);

    nesting = 0;
    RETURN(1)
}

int parse_htpl_auth_iflogged(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (!untag) RETURN(parse_htpl_auth_iflogged___fwd(stack, untag))
        else RETURN(parse_htpl_auth_iflogged___rev(stack, untag))
}

int parse_htpl_auth_login(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 2) RETURN(croak("%sAUTH LOGIN called with %d arguments, minimum needed is 2", (untag ? "/" : ""), numtokens))
    if (numtokens > 2) RETURN(croak("%sAUTH LOGIN called with %d arguments, maximum needed is 2", (untag ? "/" : ""), numtokens))
    printfcode("                $HTML::HTPL::acl->Login(\"%s\", \"%s\");\n", gettoken(1), gettoken(2));
    printcode("        \n");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_auth_adduser(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 2) RETURN(croak("%sAUTH ADDUSER called with %d arguments, minimum needed is 2", (untag ? "/" : ""), numtokens))
    if (numtokens > 3) RETURN(croak("%sAUTH ADDUSER called with %d arguments, maximum needed is 3", (untag ? "/" : ""), numtokens))
    if (numtokens <= 2)  {
        printfcode("$HTML::HTPL::acl->AddUser(\"%s\", \"%s\");\n", gettoken(1), gettoken(2));
    }
    if (numtokens >= 3 && (disposeicmp((STR)mysprintf("%s", gettoken(1)), (STR)mysprintf("crypted")) == 0))  {
        printfcode("$HTML::HTPL::acl->AddUser(\"%s\", \"%s\", 1);\n", gettoken(1), gettoken(2));
    }
    if (numtokens >= 3 && (disposeicmp((STR)mysprintf("%s", gettoken(1)), (STR)mysprintf("crypted")) != 0))  {
        RETURN(croak("Must use two arguments or 'crypted' as first argument"))
    }
    nesting = 0;
    RETURN(1)
}

int parse_htpl_auth_ifnotlogged___fwd(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    pushscope(scope_if_then, 0);
    printcode("unless\n");
    printcode("	($session{'username'}) {\n");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_auth_ifnotlogged___rev(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    nesting++;
    if (nesting > 1) RETURN(croak("Infinite loop in AUTH IFNOTLOGGED"))
    kludge_reunifying = 1;
    asprintf(&buff, "ENDIF");
    kludge_reunifying = 0;
    nest++;
    code = parse_htpl(buff, untag);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);

    nesting = 0;
    RETURN(1)
}

int parse_htpl_auth_ifnotlogged(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (!untag) RETURN(parse_htpl_auth_ifnotlogged___fwd(stack, untag))
        else RETURN(parse_htpl_auth_ifnotlogged___rev(stack, untag))
}

int parse_htpl_auth_ifauthorized___fwd(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    pushscope(scope_if_then, 0);
    printcode("if\n");
    printcode("	($HTML::HTPL::authorized) {\n");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_auth_ifauthorized___rev(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    nesting++;
    if (nesting > 1) RETURN(croak("Infinite loop in AUTH IFAUTHORIZED"))
    kludge_reunifying = 1;
    asprintf(&buff, "ENDIF");
    kludge_reunifying = 0;
    nest++;
    code = parse_htpl(buff, untag);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);

    nesting = 0;
    RETURN(1)
}

int parse_htpl_auth_ifauthorized(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (!untag) RETURN(parse_htpl_auth_ifauthorized___fwd(stack, untag))
        else RETURN(parse_htpl_auth_ifauthorized___rev(stack, untag))
}

int parse_htpl_auth(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (!done) {
        done = 1;
        printcode("use HTML::HTPL::ACL;\n	$HTML::HTPL::acl = new\n		HTML::HTPL::ACL($HTML::HTPL::htpl_db_obj->{'dbh'});\n");
    }
    eat(&stack, token);
    {
        static char *auth_table[] = {"ADDUSER",
            "IFAUTHORIZED",
            "IFLOGGED",
            "IFLOGIN",
            "IFNOTLOGGED",
            "IFUNAUTHORIZED",
            "LOGIN",
            "REALM"};
        static int auth_locations[] = { 5, -1, 1, -1, 3, 7, -1, 2, -1, 0, 6, -1, 4, -1 };
        static int auth_shortcuts[] = { 0, -1, 7, 9, -1, 12, -1, -1, 2, 4 };
        static struct hash_t auth_hash = {auth_table,
             auth_locations, auth_shortcuts};

        static parser funs[] = { parse_htpl_auth_adduser, parse_htpl_auth_ifauthorized, parse_htpl_auth_iflogged, parse_htpl_auth_iflogin, parse_htpl_auth_ifnotlogged, parse_htpl_auth_ifunauthorized, parse_htpl_auth_login, parse_htpl_auth_realm };
        int n;
        parser fun;
        n = search_hash(&auth_hash, token, 0);
        if (n < 0) RETURN(0)
        fun = funs[n];
        RETURN(fun(stack, untag))
    }
}

int parse_htpl_init___fwd(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    pushscope(scope_init, 0);
    if (refcount > 1) {
        croak("INIT may be called only once");
    }
    printcode("sub InitDoc {\n");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_init___rev(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    printcode("}\n");
    if (!currscope) RETURN(croak("Unexpected INIT"))
    if (currscope->scope != scope_init) RETURN(croak("Now in scope %s from %d and met INIT, expecting: init", scope_names[currscope->scope], currscope->nline))
    popscope();
    nesting = 0;
    RETURN(1)
}

int parse_htpl_init(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (!untag) RETURN(parse_htpl_init___fwd(stack, untag))
        else RETURN(parse_htpl_init___rev(stack, untag))
}

int parse_htpl_mail___fwd(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    printcode("{\n");
    printfcode("my %%tags = &HTML::HTPL::Sys::parse_tags('%s');\n", gettokenlist(1, " ", "", ""));
    printcode("&publish(&proper(sub {uc($_);}, %tags));\n");
    printcode("&HTML::HTPL::Sys::enforce_tags('FROM,TO,SUBJECT', 'MAIL', %tags);\n");
    pushscope(scope_mail, 0);
    printcode("{\n");
    printcode("		my %mailtags = %tags;\n");
    printcode("		my %params = %{$mailtags{'params'}};\n");
    printcode("		&begintransaction();\n");
    printcode("	\n");
    printcode("}\n");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_mail___rev(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    printcode("		$message = &endtransaction();\n");
    printcode("		$message = &subhash($message, '#', %params)\n");
    printcode("			if ($mailtags{'params'});\n");
    printcode("		delete $mailtags{'params'};\n");
    printcode("		&sendmail('Msg' => $message, %mailtags);\n");
    printcode("	\n");
    printcode("}\n");
    if (!currscope) RETURN(croak("Unexpected MAIL"))
    if (currscope->scope != scope_mail) RETURN(croak("Now in scope %s from %d and met MAIL, expecting: mail", scope_names[currscope->scope], currscope->nline))
    popscope();
    nesting = 0;
    RETURN(1)
}

int parse_htpl_mail(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (!untag) RETURN(parse_htpl_mail___fwd(stack, untag))
        else RETURN(parse_htpl_mail___rev(stack, untag))
}

int parse_htpl_endif(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    printcode("}\n");
    if (!currscope) RETURN(croak("Unexpected ENDIF"))
    if (currscope->scope != scope_if_then && currscope->scope != scope_if_then_else) RETURN(croak("Now in scope %s from %d and met ENDIF, expecting: if-then, if-then-else", scope_names[currscope->scope], currscope->nline))
    popscope();
    nesting = 0;
    RETURN(1)
}

int parse_htpl_publish(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    printfcode("&publish(%%${\"%s\"});\n", gettoken(1));
    nesting = 0;
    RETURN(1)
}

int parse_htpl_switch_case___fwd(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    pushscope(scope_switch, 0);
    printcode("{\n");
    printcode("my %__htpl_cases, @__htpl_cases_scope;\n");
    printcode("my $__htpl_cases_defopt, $__htpl_cases_default, $__htpl_cases_choose,\n");
    printcode("$__htpl_case_last = 0; \n");
    printfcode("  $__htpl_cases_choose = eval(\"%s\"); \n", gettokenlist(1, " ", "", ""));
    printcode("		{\n");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_switch_case___rev(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    printcode("}; my $__htpl_proc = $__htpl_cases{$__htpl_cases_choose}\n");
    printcode("				|| $__htpl_cases_default;\n");
    printcode("			&$__htpl_proc if (ref($__htpl_proc) =~ /CODE/);\n");
    printcode("		\n");
    printcode("}\n");
    if (!currscope) RETURN(croak("Unexpected SWITCH CASE"))
    if (currscope->scope != scope_switch) RETURN(croak("Now in scope %s from %d and met SWITCH CASE, expecting: switch", scope_names[currscope->scope], currscope->nline))
    popscope();
    nesting = 0;
    RETURN(1)
}

int parse_htpl_switch_case(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (!untag) RETURN(parse_htpl_switch_case___fwd(stack, untag))
        else RETURN(parse_htpl_switch_case___rev(stack, untag))
}

int parse_htpl_switch_rnd___fwd(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    pushscope(scope_random_switch, 0);
    printcode("{\n");
    code = 1;
    kludge_reunifying = 1;
    asprintf(&buff, "SWITCH CASE");
    kludge_reunifying = 0;
    nest++;
    code = parse_htpl(buff, untag);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);

    nesting = 0;
    RETURN(1)
}

int parse_htpl_switch_rnd___rev(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    printcode("}; my @__htpl_case_keys = keys %__htpl_cases;\n");
    printcode("        my $__htpl_rcase = int(rand(@__htpl_case_keys));\n");
    printcode("	$__htpl_cases_choose = $__htpl_case_keys[$__htpl_rcase]; {\n");
    code = 1;
    kludge_reunifying = 1;
    asprintf(&buff, "SWITCH CASE");
    kludge_reunifying = 0;
    nest++;
    code = parse_htpl(buff, 1);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);

    printcode("}\n");
    if (!currscope) RETURN(croak("Unexpected SWITCH RND"))
    if (currscope->scope != scope_random_switch) RETURN(croak("Now in scope %s from %d and met SWITCH RND, expecting: random-switch", scope_names[currscope->scope], currscope->nline))
    popscope();
    nesting = 0;
    RETURN(1)
}

int parse_htpl_switch_rnd(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (!untag) RETURN(parse_htpl_switch_rnd___fwd(stack, untag))
        else RETURN(parse_htpl_switch_rnd___rev(stack, untag))
}

int parse_htpl_switch(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    eat(&stack, token);
    {
        static char *switch_table[] = {"CASE",
            "RND"};
        static int switch_locations[] = { 0, 1, -1 };
        static int switch_shortcuts[] = { -1, -1, -1, -1, -1, -1, -1, -1, -1, 0 };
        static struct hash_t switch_hash = {switch_table,
             switch_locations, switch_shortcuts};

        static parser funs[] = { parse_htpl_switch_case, parse_htpl_switch_rnd };
        int n;
        parser fun;
        n = search_hash(&switch_hash, token, 0);
        if (n < 0) RETURN(0)
        fun = funs[n];
        RETURN(fun(stack, untag))
    }
}

int parse_htpl_load(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 1) RETURN(croak("%sLOAD called with %d arguments, minimum needed is 1", (untag ? "/" : ""), numtokens))
    printfcode("die \"Unknown query\" unless $HTML::HTPL::Sys::query_pool{\"%s\"};\n", gettoken(1));
    printfcode("${\"%s\"} = $HTML::HTPL::Sys::query_pool{\"%s\"}->load(%s);\n", gettoken(1), gettoken(1), numtokens >= abs(2) ? gettokenlist(2, ", ", "", "\"$s\"") : "()");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_cleanup___fwd(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    pushscope(scope_clean, 0);
    if (refcount > 1) {
        croak("CLEANUP may be called only once");
    }
    printcode("sub CleanDoc {\n");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_cleanup___rev(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    printcode("}\n");
    if (!currscope) RETURN(croak("Unexpected CLEANUP"))
    if (currscope->scope != scope_clean) RETURN(croak("Now in scope %s from %d and met CLEANUP, expecting: clean", scope_names[currscope->scope], currscope->nline))
    popscope();
    nesting = 0;
    RETURN(1)
}

int parse_htpl_cleanup(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (!untag) RETURN(parse_htpl_cleanup___fwd(stack, untag))
        else RETURN(parse_htpl_cleanup___rev(stack, untag))
}

int parse_htpl_sql_search(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    nesting++;
    if (nesting > 1) RETURN(croak("Infinite loop in SQL SEARCH"))
    kludge_reunifying = 1;
    asprintf(&buff, "SQL CURSOR %s", gettokenlist(1, " ", "", ""));
    kludge_reunifying = 0;
    nest++;
    code = parse_htpl(buff, untag);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);

    nesting = 0;
    RETURN(1)
}

int parse_htpl_sql_query(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    printfcode("${\"%s\"} = $HTML::HTPL::htpl_db_obj->query(\"%s\", %s);\n", gettoken(1), gettoken(2), numtokens >= abs(3) ? gettokenlist(3, ", ", "", "\"$s\"") : "()");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_sql_postgres(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    nesting++;
    if (nesting > 1) RETURN(croak("Infinite loop in SQL POSTGRES"))
    kludge_reunifying = 1;
    asprintf(&buff, "SQL POSTGRESQL %s", gettokenlist(1, " ", "", ""));
    kludge_reunifying = 0;
    nest++;
    code = parse_htpl(buff, untag);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);

    nesting = 0;
    RETURN(1)
}

int parse_htpl_sql_postgresql(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 1) RETURN(croak("%sSQL POSTGRESQL called with %d arguments, minimum needed is 1", (untag ? "/" : ""), numtokens))
    nesting++;
    if (nesting > 1) RETURN(croak("Infinite loop in SQL POSTGRESQL"))
    kludge_reunifying = 1;
    asprintf(&buff, "SQL CONNECT DBI:Pg:dbname=%s", gettoken(1));
    kludge_reunifying = 0;
    nest++;
    code = parse_htpl(buff, untag);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);

    nesting = 0;
    RETURN(1)
}

int parse_htpl_sql_batch(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 2) RETURN(croak("%sSQL BATCH called with %d arguments, minimum needed is 2", (untag ? "/" : ""), numtokens))
    if (numtokens > 2) RETURN(croak("%sSQL BATCH called with %d arguments, maximum needed is 2", (untag ? "/" : ""), numtokens))
    printfcode("$HTML::HTPL::htpl_db_obj->batch_insert(\"%s\", ${\"%s\"});\n", gettoken(1), gettoken(2));
    nesting = 0;
    RETURN(1)
}

int parse_htpl_sql_msql(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 1) RETURN(croak("%sSQL MSQL called with %d arguments, minimum needed is 1", (untag ? "/" : ""), numtokens))
    if (numtokens > 1) RETURN(croak("%sSQL MSQL called with %d arguments, maximum needed is 1", (untag ? "/" : ""), numtokens))
    nesting++;
    if (nesting > 1) RETURN(croak("Infinite loop in SQL MSQL"))
    kludge_reunifying = 1;
    asprintf(&buff, "SQL CONNECT DBI:mSQL:%s", gettoken(1));
    kludge_reunifying = 0;
    nest++;
    code = parse_htpl(buff, untag);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);

    nesting = 0;
    RETURN(1)
}

int parse_htpl_sql_connect(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 1) RETURN(croak("%sSQL CONNECT called with %d arguments, minimum needed is 1", (untag ? "/" : ""), numtokens))
    if (numtokens > 3) RETURN(croak("%sSQL CONNECT called with %d arguments, maximum needed is 3", (untag ? "/" : ""), numtokens))
    printfcode("$HTML::HTPL::htpl_db_obj = HTML::HTPL::Db->new(\"%s\", \"%s\", \"%s\");\n", gettoken(1), gettoken(2), gettoken(3));
    nesting = 0;
    RETURN(1)
}

int parse_htpl_sql_project(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 2) RETURN(croak("%sSQL PROJECT called with %d arguments, minimum needed is 2", (untag ? "/" : ""), numtokens))
    printcode("{ my $imm;\n");
    code = 1;
    kludge_reunifying = 1;
    asprintf(&buff, "SQL CURSOR imm %s", gettokenlist(2, " ", "", ""));
    kludge_reunifying = 0;
    nest++;
    code = parse_htpl(buff, untag);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);

    code = 1;
    kludge_reunifying = 1;
    asprintf(&buff, "PROJECT imm %s %s", gettoken(1), gettoken(1));
    kludge_reunifying = 0;
    nest++;
    code = parse_htpl(buff, untag);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);

    printcode("}\n");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_sql_scope_goto(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 1) RETURN(croak("%sSQL SCOPE GOTO called with %d arguments, minimum needed is 1", (untag ? "/" : ""), numtokens))
    if (numtokens > 1) RETURN(croak("%sSQL SCOPE GOTO called with %d arguments, maximum needed is 1", (untag ? "/" : ""), numtokens))
    setvar("dbobj", (STR)mysprintf("$%s", gettoken(1)));
    if (!exportvar("dbobj", "")) RETURN(croak("Scope  not found in stack"));
    nesting = 0;
    RETURN(1)
}

int parse_htpl_sql_scope_emulate(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 1) RETURN(croak("%sSQL SCOPE EMULATE called with %d arguments, minimum needed is 1", (untag ? "/" : ""), numtokens))
    code = 1;
    kludge_reunifying = 1;
    asprintf(&buff, "SQL SCOPE RETRIEVE");
    kludge_reunifying = 0;
    nest++;
    code = parse_htpl(buff, untag);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);

    printcode("$HTML::HTPL::save_sql_scope = $HTML::HTPL::htpl_db_obj;\n");
    printfcode("   $HTML::HTPL::htpl_db_obj = %s;\n", getvar("dbobj"));
    printcode("		\n");
    code = 1;
    kludge_reunifying = 1;
    asprintf(&buff, "SQL %s", gettokenlist(1, " ", "", ""));
    kludge_reunifying = 0;
    nest++;
    code = parse_htpl(buff, untag);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);

    printfcode("%s = $HTML::HTPL::htpl_db_obj;\n", getvar("dbobj"));
    printcode("			$HTML::HTPL::htpl_db_obj = $HTML::HTPL::save_sql_scope;\n");
    printcode("			undef $HTML::HTPL::save_sql_scope;\n");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_sql_scope_exec(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 1) RETURN(croak("%sSQL SCOPE EXEC called with %d arguments, minimum needed is 1", (untag ? "/" : ""), numtokens))
    code = 1;
    kludge_reunifying = 1;
    asprintf(&buff, "SQL SCOPE RETRIEVE");
    kludge_reunifying = 0;
    nest++;
    code = parse_htpl(buff, untag);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);

    printfcode("%s->execsql(&HTML::HTPL::Db'parse_sql(\"%s\"));\n", getvar("dbobj"), gettokenlist(1, " ", "", ""));
    nesting = 0;
    RETURN(1)
}

int parse_htpl_sql_scope_cursor(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 2) RETURN(croak("%sSQL SCOPE CURSOR called with %d arguments, minimum needed is 2", (untag ? "/" : ""), numtokens))
    code = 1;
    kludge_reunifying = 1;
    asprintf(&buff, "SQL SCOPE RETRIEVE");
    kludge_reunifying = 0;
    nest++;
    code = parse_htpl(buff, untag);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);

    printfcode("${\"%s\"} = %s->cursor(&HTML::HTPL::Db'parse_sql(\"%s\"));\n", gettoken(1), getvar("dbobj"), gettokenlist(2, " ", "", ""));
    printcode("		\n");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_sql_scope_retrieve(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (!nest) RETURN(0)
    if (!importvar("dbobj", "")) RETURN(croak("Scope  not found in stack"));
    if (!(disposetrue((STR)mysprintf("%s", getvar("dbobj")))))  {
        code = 1;
        kludge_reunifying = 1;
        asprintf(&buff, "SQL SCOPE BEGIN");
        kludge_reunifying = 0;
        nest++;
        code = parse_htpl(buff, untag);
        nest--;
        if (!code) {
            croak("Unification of '%s' failed", buff);
            free(buff);
            RETURN(0)
        }
        free(buff);
    }
    nesting = 0;
    RETURN(1)
}

int parse_htpl_sql_scope_connect(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 1) RETURN(croak("%sSQL SCOPE CONNECT called with %d arguments, minimum needed is 1", (untag ? "/" : ""), numtokens))
    if (numtokens > 3) RETURN(croak("%sSQL SCOPE CONNECT called with %d arguments, maximum needed is 3", (untag ? "/" : ""), numtokens))
    code = 1;
    kludge_reunifying = 1;
    asprintf(&buff, "SQL SCOPE RETRIEVE");
    kludge_reunifying = 0;
    nest++;
    code = parse_htpl(buff, untag);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);

    printfcode("my %s = \n", getvar("dbobj"));
    printfcode("   HTML::HTPL::Db->new(\"%s\", \"%s\", \"%s\");\n", gettoken(1), gettoken(2), gettoken(3));
    printcode("		\n");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_sql_scope_begin(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    setvar("dbobj", (STR)mysprintf("$__htpl_db_%s_%d", getblockid(""), random()));
    if (!exportvar("dbobj", "")) RETURN(croak("Scope  not found in stack"));
    nesting = 0;
    RETURN(1)
}

int parse_htpl_sql_scope(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    eat(&stack, token);
    {
        static char *scope_table[] = {"BEGIN",
            "CONNECT",
            "CURSOR",
            "EMULATE",
            "EXEC",
            "GOTO",
            "RETRIEVE"};
        static int scope_locations[] = { 1, -1, 6, -1, 2, -1, 4, -1, 5, -1, 0, -1, 3, -1 };
        static int scope_shortcuts[] = { 2, -1, -1, 8, -1, 10, 12, 0, 4, 6 };
        static struct hash_t scope_hash = {scope_table,
             scope_locations, scope_shortcuts};

        static parser funs[] = { parse_htpl_sql_scope_begin, parse_htpl_sql_scope_connect, parse_htpl_sql_scope_cursor, parse_htpl_sql_scope_emulate, parse_htpl_sql_scope_exec, parse_htpl_sql_scope_goto, parse_htpl_sql_scope_retrieve };
        int n;
        parser fun;
        n = search_hash(&scope_hash, token, 0);
        if (n < 0) RETURN(0)
        fun = funs[n];
        RETURN(fun(stack, untag))
    }
}

int parse_htpl_sql_delete(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    printfcode("$HTML::HTPL::htpl_db_obj->delete(\"%s, %s);\n", gettoken(1), numtokens >= abs(2) ? gettokenlist(2, ", ", "", "\"$s\"") : "()");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_sql_immediate(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    printcode("{ my $imm;\n");
    code = 1;
    kludge_reunifying = 1;
    asprintf(&buff, "SQL CURSOR imm %s", gettokenlist(1, " ", "", ""));
    kludge_reunifying = 0;
    nest++;
    code = parse_htpl(buff, untag);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);

    code = 1;
    kludge_reunifying = 1;
    asprintf(&buff, "FETCHIT imm");
    kludge_reunifying = 0;
    nest++;
    code = parse_htpl(buff, untag);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);

    printcode("}\n");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_sql_append(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 2) RETURN(croak("%sSQL APPEND called with %d arguments, minimum needed is 2", (untag ? "/" : ""), numtokens))
    code = 1;
    kludge_reunifying = 1;
    asprintf(&buff, "SQL CURSOR __htpl__temp__ %s", gettokenlist(2, " ", "", ""));
    kludge_reunifying = 0;
    nest++;
    code = parse_htpl(buff, untag);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);

    code = 1;
    kludge_reunifying = 1;
    asprintf(&buff, "MERGE %s __htpl__temp__", gettoken(1));
    kludge_reunifying = 0;
    nest++;
    code = parse_htpl(buff, untag);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);

    printcode("undef $__htpl__temp__;\n");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_sql_exec(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 1) RETURN(croak("%sSQL EXEC called with %d arguments, minimum needed is 1", (untag ? "/" : ""), numtokens))
    printfcode("$HTML::HTPL::htpl_db_obj->execsql(&HTML::HTPL::Db'parse_sql(\"%s\"));\n", gettokenlist(1, " ", "", ""));
    nesting = 0;
    RETURN(1)
}

int parse_htpl_sql_execute(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    nesting++;
    if (nesting > 1) RETURN(croak("Infinite loop in SQL EXECUTE"))
    kludge_reunifying = 1;
    asprintf(&buff, "SQL EXEC %s", gettokenlist(1, " ", "", ""));
    kludge_reunifying = 0;
    nest++;
    code = parse_htpl(buff, untag);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);

    nesting = 0;
    RETURN(1)
}

int parse_htpl_sql_declare(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    printfcode("$HTML::HTPL::Sys::query_pool{\"%s\"} ||= $HTML::HTPL::htpl_db_obj->prepare(\"%s\");\n", gettoken(1), gettokenlist(2, " ", "", ""));
    nesting = 0;
    RETURN(1)
}

int parse_htpl_sql_add(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    nesting++;
    if (nesting > 1) RETURN(croak("Infinite loop in SQL ADD"))
    kludge_reunifying = 1;
    asprintf(&buff, "SQL INSERT %s", gettokenlist(1, " ", "", ""));
    kludge_reunifying = 0;
    nest++;
    code = parse_htpl(buff, untag);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);

    nesting = 0;
    RETURN(1)
}

int parse_htpl_sql_modify(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    nesting++;
    if (nesting > 1) RETURN(croak("Infinite loop in SQL MODIFY"))
    kludge_reunifying = 1;
    asprintf(&buff, "SQL UPDATE %s", gettokenlist(1, " ", "", ""));
    kludge_reunifying = 0;
    nest++;
    code = parse_htpl(buff, untag);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);

    nesting = 0;
    RETURN(1)
}

int parse_htpl_sql_mysql(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 1) RETURN(croak("%sSQL MYSQL called with %d arguments, minimum needed is 1", (untag ? "/" : ""), numtokens))
    if (numtokens > 3) RETURN(croak("%sSQL MYSQL called with %d arguments, maximum needed is 3", (untag ? "/" : ""), numtokens))
    nesting++;
    if (nesting > 1) RETURN(croak("Infinite loop in SQL MYSQL"))
    kludge_reunifying = 1;
    asprintf(&buff, "SQL CONNECT DBI:mysql:%s %s", gettoken(1), gettokenlist(2, " ", "", ""));
    kludge_reunifying = 0;
    nest++;
    code = parse_htpl(buff, untag);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);

    nesting = 0;
    RETURN(1)
}

int parse_htpl_sql_xbase(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 1) RETURN(croak("%sSQL XBASE called with %d arguments, minimum needed is 1", (untag ? "/" : ""), numtokens))
    if (numtokens > 1) RETURN(croak("%sSQL XBASE called with %d arguments, maximum needed is 1", (untag ? "/" : ""), numtokens))
    nesting++;
    if (nesting > 1) RETURN(croak("Infinite loop in SQL XBASE"))
    kludge_reunifying = 1;
    asprintf(&buff, "SQL CONNECT DBI:XBase:%s", gettoken(1));
    kludge_reunifying = 0;
    nest++;
    code = parse_htpl(buff, untag);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);

    nesting = 0;
    RETURN(1)
}

int parse_htpl_sql_erase(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    nesting++;
    if (nesting > 1) RETURN(croak("Infinite loop in SQL ERASE"))
    kludge_reunifying = 1;
    asprintf(&buff, "SQL ERASE %s", gettokenlist(1, " ", "", ""));
    kludge_reunifying = 0;
    nest++;
    code = parse_htpl(buff, untag);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);

    nesting = 0;
    RETURN(1)
}

int parse_htpl_sql_cursor(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 2) RETURN(croak("%sSQL CURSOR called with %d arguments, minimum needed is 2", (untag ? "/" : ""), numtokens))
    printfcode("${\"%s\"} = $HTML::HTPL::htpl_db_obj->cursor(&HTML::HTPL::Db'parse_sql(\"%s\"));\n", gettoken(1), gettokenlist(2, " ", "", ""));
    nesting = 0;
    RETURN(1)
}

int parse_htpl_sql_update(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    printfcode("$HTML::HTPL::htpl_db_obj->update(\"%s\", %s);\n", gettoken(1), numtokens >= abs(2) ? gettokenlist(2, ", ", "", "\"$s\"") : "()");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_sql_insert(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    printfcode("$HTML::HTPL::htpl_db_obj->add(\"%s\", %s);\n", gettoken(1), numtokens >= abs(2) ? gettokenlist(2, ", ", "", "\"$s\"") : "()");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_sql(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (!done) {
        done = 1;
        printcode("use HTML::HTPL::Db;\n");
    }
    eat(&stack, token);
    {
        static char *sql_table[] = {"ADD",
            "APPEND",
            "BATCH",
            "CONNECT",
            "CURSOR",
            "DECLARE",
            "DELETE",
            "ERASE",
            "EXEC",
            "EXECUTE",
            "IMMEDIATE",
            "INSERT",
            "MODIFY",
            "MSQL",
            "MYSQL",
            "POSTGRES",
            "POSTGRESQL",
            "PROJECT",
            "QUERY",
            "SCOPE",
            "SEARCH",
            "UPDATE",
            "XBASE"};
        static int sql_locations[] = { 6, 11, 16, -1, 5, 12, 21, -1, 18, 19, 20, -1, 0, -1, 7, -1, 9, -1, 2, 3, 17, 22, -1, 1, 4, 10, 13, 15, -1, 8, 14, -1 };
        static int sql_shortcuts[] = { 0, 4, 8, 12, 14, -1, 16, 18, 23, 29 };
        static struct hash_t sql_hash = {sql_table,
             sql_locations, sql_shortcuts};

        static parser funs[] = { parse_htpl_sql_add, parse_htpl_sql_append, parse_htpl_sql_batch, parse_htpl_sql_connect, parse_htpl_sql_cursor, parse_htpl_sql_declare, parse_htpl_sql_delete, parse_htpl_sql_erase, parse_htpl_sql_exec, parse_htpl_sql_execute, parse_htpl_sql_immediate, parse_htpl_sql_insert, parse_htpl_sql_modify, parse_htpl_sql_msql, parse_htpl_sql_mysql, parse_htpl_sql_postgres, parse_htpl_sql_postgresql, parse_htpl_sql_project, parse_htpl_sql_query, parse_htpl_sql_scope, parse_htpl_sql_search, parse_htpl_sql_update, parse_htpl_sql_xbase };
        int n;
        parser fun;
        n = search_hash(&sql_hash, token, 0);
        if (n < 0) RETURN(0)
        fun = funs[n];
        RETURN(fun(stack, untag))
    }
}

int parse_htpl_net_setup(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 1) RETURN(croak("%sNET SETUP called with %d arguments, minimum needed is 1", (untag ? "/" : ""), numtokens))
    if (numtokens > 3) RETURN(croak("%sNET SETUP called with %d arguments, maximum needed is 3", (untag ? "/" : ""), numtokens))
    printfcode("$htpl_net_obj = HTML::HTPL::Client->setup(\"%s\", \"%s\", \"%s\");\n", gettoken(1), gettoken(2), gettoken(3));
    nesting = 0;
    RETURN(1)
}

int parse_htpl_net_get(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 2) RETURN(croak("%sNET GET called with %d arguments, minimum needed is 2", (untag ? "/" : ""), numtokens))
    if (numtokens > 3) RETURN(croak("%sNET GET called with %d arguments, maximum needed is 3", (untag ? "/" : ""), numtokens))
    printfcode("${\"%s\"} = $htpl_net_obj->get(\"%s\", \"%s\");\n", gettoken(1), gettoken(2), gettoken(3));
    nesting = 0;
    RETURN(1)
}

int parse_htpl_net(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (!done) {
        done = 1;
        printcode("use HTML::HTPL::Client;\n");
    }
    eat(&stack, token);
    {
        static char *net_table[] = {"GET",
            "SETUP"};
        static int net_locations[] = { 1, -1, 0, -1 };
        static int net_shortcuts[] = { -1, -1, -1, -1, -1, 0, -1, 2, -1, -1 };
        static struct hash_t net_hash = {net_table,
             net_locations, net_shortcuts};

        static parser funs[] = { parse_htpl_net_get, parse_htpl_net_setup };
        int n;
        parser fun;
        n = search_hash(&net_hash, token, 0);
        if (n < 0) RETURN(0)
        fun = funs[n];
        RETURN(fun(stack, untag))
    }
}

int parse_htpl_servboxen_doit(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 2) RETURN(croak("%sSERVBOXEN DOIT called with %d arguments, minimum needed is 2", (untag ? "/" : ""), numtokens))
    if (numtokens > 2) RETURN(croak("%sSERVBOXEN DOIT called with %d arguments, maximum needed is 2", (untag ? "/" : ""), numtokens))
    printfcode("&html_selectbox({'name' => \"%s\"}, ${\"%s\"}->project(sub {\n", gettoken(1), gettoken(1));
    printfcode("($_->getcol(0), $_->getcol(%s));\n", gettoken(2));
    printcode("}));\n");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_servboxen_decide(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 2) RETURN(croak("%sSERVBOXEN DECIDE called with %d arguments, minimum needed is 2", (untag ? "/" : ""), numtokens))
    if (numtokens >= 3)  {
        code = 1;
        kludge_reunifying = 1;
        asprintf(&buff, "%s", gettokenlist(2, " ", "", ""));
        kludge_reunifying = 0;
        nest++;
        code = parse_htpl(buff, untag);
        nest--;
        if (!code) {
            croak("Unification of '%s' failed", buff);
            free(buff);
            RETURN(0)
        }
        free(buff);
    }
    if (numtokens >= 3)  {
        code = 1;
        kludge_reunifying = 1;
        asprintf(&buff, "SERVBOXEN DOIT %s %s", gettoken(4), gettoken(1));
        kludge_reunifying = 0;
        nest++;
        code = parse_htpl(buff, untag);
        nest--;
        if (!code) {
            croak("Unification of '%s' failed", buff);
            free(buff);
            RETURN(0)
        }
        free(buff);
    }
    if (numtokens <= 2)  {
        code = 1;
        kludge_reunifying = 1;
        asprintf(&buff, "SERVBOXEN DOIT %s %s", gettoken(2), gettoken(1));
        kludge_reunifying = 0;
        nest++;
        code = parse_htpl(buff, untag);
        nest--;
        if (!code) {
            croak("Unification of '%s' failed", buff);
            free(buff);
            RETURN(0)
        }
        free(buff);
    }
    nesting = 0;
    RETURN(1)
}

int parse_htpl_servboxen(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (!nest) RETURN(0)
    eat(&stack, token);
    {
        static char *servboxen_table[] = {"DECIDE",
            "DOIT"};
        static int servboxen_locations[] = { 0, -1, 1, -1 };
        static int servboxen_shortcuts[] = { 0, -1, -1, -1, -1, -1, 2, -1, -1, -1 };
        static struct hash_t servboxen_hash = {servboxen_table,
             servboxen_locations, servboxen_shortcuts};

        static parser funs[] = { parse_htpl_servboxen_decide, parse_htpl_servboxen_doit };
        int n;
        parser fun;
        n = search_hash(&servboxen_hash, token, 0);
        if (n < 0) RETURN(0)
        fun = funs[n];
        RETURN(fun(stack, untag))
    }
}

int parse_htpl_clsutils_imp(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (!importvar("cls", "class")) RETURN(croak("Scope class not found in stack"));
    nesting = 0;
    RETURN(1)
}

int parse_htpl_clsutils_mine(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    code = 1;
    kludge_reunifying = 1;
    asprintf(&buff, "CLSUTILS IMP");
    kludge_reunifying = 0;
    nest++;
    code = parse_htpl(buff, untag);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);

    printfcode("package %s;\n", getvar("cls"));
    nesting = 0;
    RETURN(1)
}

int parse_htpl_clsutils_other(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    code = 1;
    kludge_reunifying = 1;
    asprintf(&buff, "CLSUTILS IMP");
    kludge_reunifying = 0;
    nest++;
    code = parse_htpl(buff, untag);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);

    printfcode("package %s::__shadow__;\n", getvar("cls"));
    nesting = 0;
    RETURN(1)
}

int parse_htpl_clsutils(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (!nest) RETURN(0)
    eat(&stack, token);
    {
        static char *clsutils_table[] = {"IMP",
            "MINE",
            "OTHER"};
        static int clsutils_locations[] = { 0, -1, 2, -1, 1, -1 };
        static int clsutils_shortcuts[] = { -1, -1, -1, 0, -1, 2, -1, 4, -1, -1 };
        static struct hash_t clsutils_hash = {clsutils_table,
             clsutils_locations, clsutils_shortcuts};

        static parser funs[] = { parse_htpl_clsutils_imp, parse_htpl_clsutils_mine, parse_htpl_clsutils_other };
        int n;
        parser fun;
        n = search_hash(&clsutils_hash, token, 0);
        if (n < 0) RETURN(0)
        fun = funs[n];
        RETURN(fun(stack, untag))
    }
}

int parse_htpl_define___fwd(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 1) RETURN(croak("%sDEFINE called with %d arguments, minimum needed is 1", (untag ? "/" : ""), numtokens))
    if (numtokens > 1) RETURN(croak("%sDEFINE called with %d arguments, maximum needed is 1", (untag ? "/" : ""), numtokens))
    pushscope(scope_define, 0);
    setvar("var", (STR)mysprintf("%s", gettoken(1)));
    printcode("&begintransaction;\n");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_define___rev(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    printfcode("$%s = &endtransaction; \n", getvar("var"));
    if (!currscope) RETURN(croak("Unexpected DEFINE"))
    if (currscope->scope != scope_define) RETURN(croak("Now in scope %s from %d and met DEFINE, expecting: define", scope_names[currscope->scope], currscope->nline))
    popscope();
    nesting = 0;
    RETURN(1)
}

int parse_htpl_define(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (!untag) RETURN(parse_htpl_define___fwd(stack, untag))
        else RETURN(parse_htpl_define___rev(stack, untag))
}

int parse_htpl_out_tag(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (!nest) RETURN(0)
    printfcode("print &outhtmltag(\"%s\", %s);\n", gettoken(1), gettoken(2));
    nesting = 0;
    RETURN(1)
}

int parse_htpl_out(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    eat(&stack, token);
    {
        static char *out_table[] = {"TAG"};
        static int out_locations[] = { 0, -1 };
        static int out_shortcuts[] = { -1, -1, -1, -1, -1, -1, -1, 0, -1, -1 };
        static struct hash_t out_hash = {out_table,
             out_locations, out_shortcuts};

        static parser funs[] = { parse_htpl_out_tag };
        int n;
        parser fun;
        n = search_hash(&out_hash, token, 0);
        if (n < 0) RETURN(0)
        fun = funs[n];
        RETURN(fun(stack, untag))
    }
}

int parse_htpl_rem___fwd(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    pushscope(scope_rem, 0);
    printcode("&begintransaction;\n");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_rem___rev(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    printcode("&endtransaction;\n");
    if (!currscope) RETURN(croak("Unexpected REM"))
    if (currscope->scope != scope_rem) RETURN(croak("Now in scope %s from %d and met REM, expecting: rem", scope_names[currscope->scope], currscope->nline))
    popscope();
    nesting = 0;
    RETURN(1)
}

int parse_htpl_rem(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (!untag) RETURN(parse_htpl_rem___fwd(stack, untag))
        else RETURN(parse_htpl_rem___rev(stack, untag))
}

int parse_htpl_file___fwd(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 1) RETURN(croak("%sFILE called with %d arguments, minimum needed is 1", (untag ? "/" : ""), numtokens))
    if (numtokens > 1) RETURN(croak("%sFILE called with %d arguments, maximum needed is 1", (untag ? "/" : ""), numtokens))
    pushscope(scope_file, 0);
    printcode("		push(@HTML::HTPL::file_saves, select);\n");
    printcode("		$HTML::HTPL::new_file = gensym;\n");
    printfcode("  open($HTML::HTPL::new_file, \">%s\");\n", gettoken(1));
    printcode("		select $HTML::HTPL::new_file;\n");
    printcode("	\n");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_file___rev(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    printcode("		$HTML::HTPL::new_file = select;	\n");
    printcode("		select pop @HTML::HTPL::file_saves;\n");
    printcode("		close($HTML::HTPL::new_file);\n");
    printcode("		undef $HTML::HTPL::new_file;\n");
    printcode("		undef @HTML::HTPL::file_saves unless @HTML::HTPL::file_saves;\n");
    printcode("	\n");
    if (!currscope) RETURN(croak("Unexpected FILE"))
    if (currscope->scope != scope_file) RETURN(croak("Now in scope %s from %d and met FILE, expecting: file", scope_names[currscope->scope], currscope->nline))
    popscope();
    nesting = 0;
    RETURN(1)
}

int parse_htpl_file(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (!untag) RETURN(parse_htpl_file___fwd(stack, untag))
        else RETURN(parse_htpl_file___rev(stack, untag))
}

int parse_htpl_break(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    printcode("last;\n");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_destructor___fwd(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (!currscope) RETURN(croak("Unexpected DESTRUCTOR"))
    if (currscope->scope != scope_class) RETURN(croak("Now in scope %s from %d and met DESTRUCTOR, expecting: class", scope_names[currscope->scope], currscope->nline))
    pushscope(scope_destructor, 0);
    if (!importvar("destructor", "class")) RETURN(croak("Scope class not found in stack"));
    if (disposetrue((STR)mysprintf("%s", getvar("destructor"))))  {
        RETURN(croak("Only one destructor per class! Previous at %s", getvar("destructor")))
    }
    setvar("destructor", (STR)mysprintf("%d", nline));
    if (!exportvar("destructor", "class")) RETURN(croak("Scope class not found in stack"));
    asprintf(&buff, "#CLSUTILS MINE \n");
    nest++;
    code = parse_htpl(strchr(buff, '#') + 1, 0);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);
    printcode("	sub DESTROY {\n");
    printcode("SYNC\n");
    printcode("	\n");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_destructor___rev(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    printcode("}\n");
    if (!currscope) RETURN(croak("Unexpected DESTRUCTOR"))
    if (currscope->scope != scope_destructor) RETURN(croak("Now in scope %s from %d and met DESTRUCTOR, expecting: destructor", scope_names[currscope->scope], currscope->nline))
    popscope();
    if (!currscope) RETURN(croak("Unexpected DESTRUCTOR"))
    if (currscope->scope != scope_class) RETURN(croak("Now in scope %s from %d and met DESTRUCTOR, expecting: class", scope_names[currscope->scope], currscope->nline))
    nesting = 0;
    RETURN(1)
}

int parse_htpl_destructor(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (!untag) RETURN(parse_htpl_destructor___fwd(stack, untag))
        else RETURN(parse_htpl_destructor___rev(stack, untag))
}

int parse_htpl_method___fwd(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (!currscope) RETURN(croak("Unexpected METHOD"))
    if (currscope->scope != scope_class) RETURN(croak("Now in scope %s from %d and met METHOD, expecting: class", scope_names[currscope->scope], currscope->nline))
    if (numtokens < 1) RETURN(croak("%sMETHOD called with %d arguments, minimum needed is 1", (untag ? "/" : ""), numtokens))
    pushscope(scope_method, 0);
    asprintf(&buff, "#CLSUTILS OTHER\n");
    nest++;
    code = parse_htpl(strchr(buff, '#') + 1, 0);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);
    printfcode("                sub __shadow__%s {\n", gettoken(1));
    printcode("SYNC\n");
    if (numtokens >= 2)  {
        printfcode("my (%s) = @_;\n", gettokenlist(2, ", ", "$", ""));
    }
    nesting = 0;
    RETURN(1)
}

int parse_htpl_method___rev(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    printcode("}\n");
    if (!currscope) RETURN(croak("Unexpected METHOD"))
    if (currscope->scope != scope_method) RETURN(croak("Now in scope %s from %d and met METHOD, expecting: method", scope_names[currscope->scope], currscope->nline))
    popscope();
    if (!currscope) RETURN(croak("Unexpected METHOD"))
    if (currscope->scope != scope_class) RETURN(croak("Now in scope %s from %d and met METHOD, expecting: class", scope_names[currscope->scope], currscope->nline))
    nesting = 0;
    RETURN(1)
}

int parse_htpl_method(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (!untag) RETURN(parse_htpl_method___fwd(stack, untag))
        else RETURN(parse_htpl_method___rev(stack, untag))
}

int parse_htpl_try___fwd(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    pushscope(scope_try, 0);
    printcode("{\n");
    printcode("my $__htpl__try__sub = sub {\n");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_try___rev(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    printcode("};\n");
    printcode("$@ = undef; \n");
    printcode("eval '&$__htpl__try__sub;';\n");
    printcode("if ($@) {\n");
    printcode("	foreach (keys %__htpl_handler) {\n");
    printcode("		my $v = $__htpl_handler{$_};\n");
    printcode("		if ($@ =~ /$_/ && ref($v) =~ /CODE/) {\n");
    printcode("			&$v($@);\n");
    printfcode("   goto __htpl_try_lbl%s;\n", getblockid(""));
    printcode("		} \n");
    printcode("	} \n");
    printcode("        if (ref($__htpl_default_handler) =~ /CODE/) {\n");
    printcode("		&$__htpl_default_handler;\n");
    printfcode("  goto __htpl_try_lbl%s;\n", getblockid(""));
    printcode("	}\n");
    printcode("	die $@;\n");
    printfcode("__htpl_try_lbl%s:\n", getblockid(""));
    printcode("} \n");
    printcode("}\n");
    if (!currscope) RETURN(croak("Unexpected TRY"))
    if (currscope->scope != scope_catch) RETURN(croak("Now in scope %s from %d and met TRY, expecting: catch", scope_names[currscope->scope], currscope->nline))
    popscope();
    nesting = 0;
    RETURN(1)
}

int parse_htpl_try(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (!untag) RETURN(parse_htpl_try___fwd(stack, untag))
        else RETURN(parse_htpl_try___rev(stack, untag))
}

int parse_htpl_proc___fwd(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 1) RETURN(croak("%sPROC called with %d arguments, minimum needed is 1", (untag ? "/" : ""), numtokens))
    pushscope(scope_procedure, 0);
    printfcode("sub %s (%s) {\n", gettoken(1), repeat(numtokens - 1, '$'));
    if (numtokens >= 2)  {
        printfcode("my (%s) = @_;\n", gettokenlist(2, ", ", "$", ""));
    }
    nesting = 0;
    RETURN(1)
}

int parse_htpl_proc___rev(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    printcode("}\n");
    printcode("	\n");
    if (!currscope) RETURN(croak("Unexpected PROC"))
    if (currscope->scope != scope_procedure) RETURN(croak("Now in scope %s from %d and met PROC, expecting: procedure", scope_names[currscope->scope], currscope->nline))
    popscope();
    nesting = 0;
    RETURN(1)
}

int parse_htpl_proc(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (!untag) RETURN(parse_htpl_proc___fwd(stack, untag))
        else RETURN(parse_htpl_proc___rev(stack, untag))
}

int parse_htpl_img_rnd(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    printcode("{\n");
    printfcode("my %%tags = &HTML::HTPL::Sys::parse_tags('%s');\n", gettokenlist(1, " ", "", ""));
    printcode("&publish(&proper(sub {uc($_);}, %tags));\n");
    printcode("&HTML::HTPL::Sys::enforce_tags('SRC', 'IMG RND', %tags);\n");
    printcode("my @ims = split(/,\\s*/, $tags{'SRC'}); my $f = $ims[int(rand() * ($#ims + 1))];\n");
    printcode("		$tags{'SRC'} = $f; \n");
    code = 1;
    kludge_reunifying = 1;
    asprintf(&buff, "OUT TAG IMG %%tags");
    kludge_reunifying = 0;
    nest++;
    code = parse_htpl(buff, untag);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);

    printcode("}\n");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_img(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    eat(&stack, token);
    {
        static char *img_table[] = {"RND"};
        static int img_locations[] = { 0, -1 };
        static int img_shortcuts[] = { -1, -1, -1, -1, -1, -1, -1, -1, -1, 0 };
        static struct hash_t img_hash = {img_table,
             img_locations, img_shortcuts};

        static parser funs[] = { parse_htpl_img_rnd };
        int n;
        parser fun;
        n = search_hash(&img_hash, token, 0);
        if (n < 0) RETURN(0)
        fun = funs[n];
        RETURN(fun(stack, untag))
    }
}

int parse_htpl_case(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (!currscope) RETURN(croak("Unexpected CASE"))
    if (currscope->scope != scope_switch) RETURN(croak("Now in scope %s from %d and met CASE, expecting: switch", scope_names[currscope->scope], currscope->nline))
    printfcode("}; @__htpl_cases_scope = (%s);\n", gettokenlist(1, " ", "", ""));
    printcode("       @__htpl_cases_scope =\n");
    printcode("         defined($__htpl_case_last) ? ($__htpl_case_last + 1) : ()\n");
    printcode("         unless (@__htpl_cases_scope);\n");
    printcode("      @__htpl_cases_scope = ( '__' . ++$__htpl_cases_defopt)\n");
    printcode("        unless (@__htpl_cases_scope &&\n");
    printcode("        !@__htpl_cases{@__htpl_cases_scope});\n");
    if (numtokens >= 1)  {
        printcode("$__htpl_case_last = (!$#__htpl_cases_scope &&\n");
        printcode("$__htpl_cases_scope[0] =~ /^\\d+$/) ? $__htpl_cases_scope[0] : undef; \n");
    }
    if (numtokens <= 0)  {
        printcode("$__htpl_case_last++;\n");
    }
    printcode("@__htpl_cases{@__htpl_cases_scope} = revmap \\@__htpl_cases_scope,\n");
    printcode("sub {\n");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_mem_search(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    nesting++;
    if (nesting > 1) RETURN(croak("Infinite loop in MEM SEARCH"))
    kludge_reunifying = 1;
    asprintf(&buff, "MEM CURSOR %s", gettokenlist(1, " ", "", ""));
    kludge_reunifying = 0;
    nest++;
    code = parse_htpl(buff, untag);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);

    nesting = 0;
    RETURN(1)
}

int parse_htpl_mem_project(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    printcode("{ my $imm;\n");
    code = 1;
    kludge_reunifying = 1;
    asprintf(&buff, "MEM CURSOR imm %s", gettokenlist(2, " ", "", ""));
    kludge_reunifying = 0;
    nest++;
    code = parse_htpl(buff, untag);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);

    code = 1;
    kludge_reunifying = 1;
    asprintf(&buff, "PROJECT imm %s %s", gettoken(1), gettoken(1));
    kludge_reunifying = 0;
    nest++;
    code = parse_htpl(buff, untag);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);

    printcode("}\n");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_mem_immediate(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    printcode("{ my $imm;\n");
    code = 1;
    kludge_reunifying = 1;
    asprintf(&buff, "MEM CURSOR imm %s", gettokenlist(1, " ", "", ""));
    kludge_reunifying = 0;
    nest++;
    code = parse_htpl(buff, untag);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);

    code = 1;
    kludge_reunifying = 1;
    asprintf(&buff, "FETCHIT imm");
    kludge_reunifying = 0;
    nest++;
    code = parse_htpl(buff, untag);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);

    printcode("}\n");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_mem_cursor(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    printfcode("${\"%s\"} = HTML::HTPL::Mem'cursor(&HTML::HTPL::Db'parse_sql(\"%s\"));\n", gettoken(1), gettokenlist(2, " ", "", ""));
    nesting = 0;
    RETURN(1)
}

int parse_htpl_mem(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (!done) {
        done = 1;
        printcode("use HTML::HTPL::Mem;\nuse HTML::HTPL::Db;\n");
    }
    eat(&stack, token);
    {
        static char *mem_table[] = {"CURSOR",
            "IMMEDIATE",
            "PROJECT",
            "SEARCH"};
        static int mem_locations[] = { 3, -1, 2, -1, 0, 1, -1 };
        static int mem_shortcuts[] = { -1, -1, 0, -1, -1, -1, -1, 2, 4, -1 };
        static struct hash_t mem_hash = {mem_table,
             mem_locations, mem_shortcuts};

        static parser funs[] = { parse_htpl_mem_cursor, parse_htpl_mem_immediate, parse_htpl_mem_project, parse_htpl_mem_search };
        int n;
        parser fun;
        n = search_hash(&mem_hash, token, 0);
        if (n < 0) RETURN(0)
        fun = funs[n];
        RETURN(fun(stack, untag))
    }
}

int parse_htpl_class___fwd(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 1) RETURN(croak("%sCLASS called with %d arguments, minimum needed is 1", (untag ? "/" : ""), numtokens))
    pushscope(scope_class, 0);
    if (disposetrue((STR)mysprintf("%s", getsubtoken(1, ':', 2))))  {
        printfcode(" package %s;\n", getsubtoken(1, ':', 1));
        printfcode(" @ISA = split(/:/, \"%s\");\n", gettoken(1));
        printcode("	shift @ISA;\n");
        printfcode("        package %s::__shadow__;\n", getsubtoken(1, ':', 1));
        printfcode("        @ISA = map { \"${_}::__shadow__\"; } @%s::ISA;\n", getsubtoken(1, ':', 1));
        printcode("	\n");
        setvar("cls", (STR)mysprintf("%s", getsubtoken(1, ':', 1)));
    }
    if (!(disposetrue((STR)mysprintf("%s", getsubtoken(1, ':', 2)))))  {
        printfcode(" package %s;\n", gettoken(1));
        printcode("	\n");
        setvar("cls", (STR)mysprintf("%s", gettoken(1)));
    }
    printfcode(" use HTML::HTPL::Munge %s;\n", numtokens >= abs(2) ? gettokenlist(2, ", ", "", "\"$s\"") : "()");
    printcode("	\n");
    printcode("	sub set {\n");
    printcode("	my $self = shift;\n");
    printcode("	my %hash = @_;\n");
    printcode("	foreach (keys %hash) {\n");
    printcode("		$self->{$_} = $hash{$_};\n");
    printcode("	}\n");
    printcode("}\n");
    asprintf(&buff, "#CLSUTILS OTHER\n");
    nest++;
    code = parse_htpl(strchr(buff, '#') + 1, 0);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);
    printcode("sub __shadow__clone {\n");
    printcode("	require Clone;\n");
    printcode("	Clone::clone($self);\n");
    printcode("}\n");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_class___rev(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (!currscope) RETURN(croak("Unexpected CLASS"))
    if (currscope->scope != scope_class) RETURN(croak("Now in scope %s from %d and met CLASS, expecting: class", scope_names[currscope->scope], currscope->nline))
    popscope();
    nesting = 0;
    RETURN(1)
}

int parse_htpl_class(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (!untag) RETURN(parse_htpl_class___fwd(stack, untag))
        else RETURN(parse_htpl_class___rev(stack, untag))
}

int parse_htpl_listbox(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    nesting++;
    if (nesting > 1) RETURN(croak("Infinite loop in LISTBOX"))
    kludge_reunifying = 1;
    asprintf(&buff, "SERVBOXEN DECIDE 1 %s", gettokenlist(1, " ", "", ""));
    kludge_reunifying = 0;
    nest++;
    code = parse_htpl(buff, untag);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);

    nesting = 0;
    RETURN(1)
}

int parse_htpl_assert(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 1) RETURN(croak("%sASSERT called with %d arguments, minimum needed is 1", (untag ? "/" : ""), numtokens))
    printfcode("die \"Assertion failed: (%s)\" unless (%s);\n", gettokenlist(-1, " ", "", ""), gettokenlist(1, " ", "", ""));
    nesting = 0;
    RETURN(1)
}

int parse_htpl_filter(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    printfcode("${\"%s\"} = ${\"%s\"}->filter(sub {%s;});\n", gettoken(2), gettoken(1), gettokenlist(3, " ", "", ""));
    nesting = 0;
    RETURN(1)
}

int parse_htpl_project(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 3) RETURN(croak("%sPROJECT called with %d arguments, minimum needed is 3", (untag ? "/" : ""), numtokens))
    printfcode("@%s = ${\"%s\"}->project(%s);\n", gettoken(2), gettoken(1), numtokens >= abs(3) ? gettokenlist(3, ", ", "", "\"$s\"") : "()");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_die(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    printfcode("&htdie(\"%s\");\n", gettokenlist(1, " ", "", ""));
    nesting = 0;
    RETURN(1)
}

int parse_htpl_fetchitorbreak(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 1) RETURN(croak("%sFETCHITORBREAK called with %d arguments, minimum needed is 1", (untag ? "/" : ""), numtokens))
    if (numtokens > 1) RETURN(croak("%sFETCHITORBREAK called with %d arguments, maximum needed is 1", (untag ? "/" : ""), numtokens))
    printfcode("last unless (${\"%s\"}->fetch);\n", gettoken(1));
    nesting = 0;
    RETURN(1)
}

int parse_htpl_rewind(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    printcode("&rewind;\n");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_req_symbol(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (!nest) RETURN(0)
    if (!done) {
        done = 1;
        printcode("use Symbol;\n");
    }
    nesting = 0;
    RETURN(1)
}

int parse_htpl_ifnotnull___fwd(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 1) RETURN(croak("%sIFNOTNULL called with %d arguments, minimum needed is 1", (untag ? "/" : ""), numtokens))
    if (numtokens > 1) RETURN(croak("%sIFNOTNULL called with %d arguments, maximum needed is 1", (untag ? "/" : ""), numtokens))
    pushscope(scope_if_then, 0);
    printfcode("unless (!${\"%s\"} || ${\"%s\"}->none) {\n", gettoken(1), gettoken(1));
    nesting = 0;
    RETURN(1)
}

int parse_htpl_ifnotnull___rev(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    nesting++;
    if (nesting > 1) RETURN(croak("Infinite loop in IFNOTNULL"))
    kludge_reunifying = 1;
    asprintf(&buff, "ENDIF");
    kludge_reunifying = 0;
    nest++;
    code = parse_htpl(buff, untag);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);

    nesting = 0;
    RETURN(1)
}

int parse_htpl_ifnotnull(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (!untag) RETURN(parse_htpl_ifnotnull___fwd(stack, untag))
        else RETURN(parse_htpl_ifnotnull___rev(stack, untag))
}

int parse_htpl_end(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    nesting++;
    if (nesting > 1) RETURN(croak("Infinite loop in END"))
    kludge_reunifying = 1;
    asprintf(&buff, "%s", gettokenlist(1, " ", "", ""));
    kludge_reunifying = 0;
    nest++;
    code = parse_htpl(buff, 1);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);

    nesting = 0;
    RETURN(1)
}

int parse_htpl_dir_subs(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 3) RETURN(croak("%sDIR SUBS called with %d arguments, minimum needed is 3", (untag ? "/" : ""), numtokens))
    if (numtokens > 3) RETURN(croak("%sDIR SUBS called with %d arguments, maximum needed is 3", (untag ? "/" : ""), numtokens))
    printfcode("${\"%s\"} = &HTML::HTPL::Glob'dirs(\"%s\", \"%s\");\n", gettoken(1), gettoken(2), gettoken(3));
    nesting = 0;
    RETURN(1)
}

int parse_htpl_dir_files(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 3) RETURN(croak("%sDIR FILES called with %d arguments, minimum needed is 3", (untag ? "/" : ""), numtokens))
    if (numtokens > 3) RETURN(croak("%sDIR FILES called with %d arguments, maximum needed is 3", (untag ? "/" : ""), numtokens))
    printfcode("${\"%s\"} = &HTML::HTPL::Glob'files(\"%s\", \"%s\");\n", gettoken(1), gettoken(2), gettoken(3));
    nesting = 0;
    RETURN(1)
}

int parse_htpl_dir_tree(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 3) RETURN(croak("%sDIR TREE called with %d arguments, minimum needed is 3", (untag ? "/" : ""), numtokens))
    if (numtokens > 3) RETURN(croak("%sDIR TREE called with %d arguments, maximum needed is 3", (untag ? "/" : ""), numtokens))
    printfcode("${\"%s\"} = &HTML::HTPL::Glob'tree(\"%s\", \"%s\");\n", gettoken(1), gettoken(2), gettoken(3));
    nesting = 0;
    RETURN(1)
}

int parse_htpl_dir(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (!done) {
        done = 1;
        printcode("use HTML::HTPL::Glob;\n");
    }
    eat(&stack, token);
    {
        static char *dir_table[] = {"FILES",
            "SUBS",
            "TREE"};
        static int dir_locations[] = { 2, -1, 1, -1, 0, -1 };
        static int dir_shortcuts[] = { -1, -1, 0, 2, -1, 4, -1, -1, -1, -1 };
        static struct hash_t dir_hash = {dir_table,
             dir_locations, dir_shortcuts};

        static parser funs[] = { parse_htpl_dir_files, parse_htpl_dir_subs, parse_htpl_dir_tree };
        int n;
        parser fun;
        n = search_hash(&dir_hash, token, 0);
        if (n < 0) RETURN(0)
        fun = funs[n];
        RETURN(fun(stack, untag))
    }
}

int parse_htpl_default(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (!currscope) RETURN(croak("Unexpected DEFAULT"))
    if (currscope->scope != scope_switch) RETURN(croak("Now in scope %s from %d and met DEFAULT, expecting: switch", scope_names[currscope->scope], currscope->nline))
    printcode("}; \n");
    printcode("$__htpl_cases_default = sub\n");
    printcode("{\n");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_counter(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    printfcode("print &increasefile(\"%s\");\n", gettoken(1));
    nesting = 0;
    RETURN(1)
}

int parse_htpl_throw(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    printfcode("%#line %d %s\n", nline, thefilename);
    printfcode("die \"%s\";\n", gettokenlist(1, " ", "", ""));
    printfcode("%#line %d %s\n", rline + currbuffer->lines + 1 + 1, thescript);
    nesting = 0;
    RETURN(1)
}

int parse_htpl_call(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 1) RETURN(croak("%sCALL called with %d arguments, minimum needed is 1", (untag ? "/" : ""), numtokens))
    printfcode("&%s(%2, *%);\n", gettoken(1));
    nesting = 0;
    RETURN(1)
}

int parse_htpl_copy(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 1) RETURN(croak("%sCOPY called with %d arguments, minimum needed is 1", (untag ? "/" : ""), numtokens))
    printfcode("&include(%s);\n", numtokens >= abs(1) ? gettokenlist(1, ", ", "", "\"$s\"") : "()");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_fetchcols(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 2) RETURN(croak("%sFETCHCOLS called with %d arguments, minimum needed is 2", (untag ? "/" : ""), numtokens))
    if (numtokens > 2) RETURN(croak("%sFETCHCOLS called with %d arguments, maximum needed is 2", (untag ? "/" : ""), numtokens))
    printfcode("foreach %s (%s->cols) {\n", gettoken(2), gettoken(1));
    nesting = 0;
    RETURN(1)
}

int parse_htpl_constructor___fwd(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (!currscope) RETURN(croak("Unexpected CONSTRUCTOR"))
    if (currscope->scope != scope_class) RETURN(croak("Now in scope %s from %d and met CONSTRUCTOR, expecting: class", scope_names[currscope->scope], currscope->nline))
    pushscope(scope_contsructor, 0);
    if (!importvar("constructor", "class")) RETURN(croak("Scope class not found in stack"));
    if (disposetrue((STR)mysprintf("%s", getvar("constructor"))))  {
        RETURN(croak("Only one constructor per class! Previous at %s", getvar("constructor")))
    }
    setvar("constructor", (STR)mysprintf("%d", nline));
    if (!exportvar("constructor", "class")) RETURN(croak("Scope class not found in stack"));
    asprintf(&buff, "#CLSUTILS MINE\n");
    nest++;
    code = parse_htpl(strchr(buff, '#') + 1, 0);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);
    printcode("sub new {\n");
    printfcode(" %s::__shadow__::new(@_);\n", getvar("cls"));
    printcode("}\n");
    asprintf(&buff, "#CLSUTILS OTHER\n");
    nest++;
    code = parse_htpl(strchr(buff, '#') + 1, 0);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);
    printcode("sub new {\n");
    printcode("	my $class = shift;\n");
    printcode("	my $self = {};\n");
    printcode("	bless $self, $class;\n");
    printcode("	unshift(@_, $self);\n");
    printcode("SYNC\n");
    printcode("	\n");
    if (numtokens >= 1)  {
        printfcode(" my (%s) = @_;\n", gettokenlist(1, ", ", "$", ""));
    }
    nesting = 0;
    RETURN(1)
}

int parse_htpl_constructor___rev(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    printcode("    $self;\n");
    printcode("}\n");
    if (!currscope) RETURN(croak("Unexpected CONSTRUCTOR"))
    if (currscope->scope != scope_contsructor) RETURN(croak("Now in scope %s from %d and met CONSTRUCTOR, expecting: contsructor", scope_names[currscope->scope], currscope->nline))
    popscope();
    if (!currscope) RETURN(croak("Unexpected CONSTRUCTOR"))
    if (currscope->scope != scope_class) RETURN(croak("Now in scope %s from %d and met CONSTRUCTOR, expecting: class", scope_names[currscope->scope], currscope->nline))
    nesting = 0;
    RETURN(1)
}

int parse_htpl_constructor(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (!untag) RETURN(parse_htpl_constructor___fwd(stack, untag))
        else RETURN(parse_htpl_constructor___rev(stack, untag))
}

int parse_htpl_fetch___fwd(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 1) RETURN(croak("%sFETCH called with %d arguments, minimum needed is 1", (untag ? "/" : ""), numtokens))
    if (numtokens > 1) RETURN(croak("%sFETCH called with %d arguments, maximum needed is 1", (untag ? "/" : ""), numtokens))
    pushscope(scope_fetch, 0);
    printfcode("${\"%s\"}->rewind if (${\"%s\"});\n", gettoken(1), gettoken(1));
    printfcode("while (${\"%s\"} && !${\"%s\"}->eof && ${\"%s\"}->fetch) {\n", gettoken(1), gettoken(1), gettoken(1));
    nesting = 0;
    RETURN(1)
}

int parse_htpl_fetch___rev(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    nesting++;
    if (nesting > 1) RETURN(croak("Infinite loop in FETCH"))
    kludge_reunifying = 1;
    asprintf(&buff, "LOOP");
    kludge_reunifying = 0;
    nest++;
    code = parse_htpl(buff, untag);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);

    nesting = 0;
    RETURN(1)
}

int parse_htpl_fetch(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (!untag) RETURN(parse_htpl_fetch___fwd(stack, untag))
        else RETURN(parse_htpl_fetch___rev(stack, untag))
}

int parse_htpl_for___fwd(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 1) RETURN(croak("%sFOR called with %d arguments, minimum needed is 1", (untag ? "/" : ""), numtokens))
    if (numtokens > 4) RETURN(croak("%sFOR called with %d arguments, maximum needed is 4", (untag ? "/" : ""), numtokens))
    pushscope(scope_for, 0);
    if (numtokens <= 1)  {
        printfcode("foreach (1 .. %s) {\n", gettoken(1));
    }
    if (numtokens >= 2 && numtokens <= 2)  {
        printfcode("foreach ${\"%s\"} (1 .. %s) {\n", gettoken(1), gettoken(2));
    }
    if (numtokens >= 3 && numtokens <= 3)  {
        printfcode("foreach ${\"%s\"} (%s .. %s) {\n", gettoken(1), gettoken(2), gettoken(3));
    }
    if (numtokens >= 4 && numtokens <= 4)  {
        printfcode("for (${\"%s\"} = %s; ${\"%s\"} <= %s; ${\"%s\"} += %s) {\n", gettoken(1), gettoken(2), gettoken(1), gettoken(3), gettoken(1), gettoken(4));
    }
    nesting = 0;
    RETURN(1)
}

int parse_htpl_for___rev(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    printcode("}\n");
    if (!currscope) RETURN(croak("Unexpected FOR"))
    if (currscope->scope != scope_for) RETURN(croak("Now in scope %s from %d and met FOR, expecting: for", scope_names[currscope->scope], currscope->nline))
    popscope();
    nesting = 0;
    RETURN(1)
}

int parse_htpl_for(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (!untag) RETURN(parse_htpl_for___fwd(stack, untag))
        else RETURN(parse_htpl_for___rev(stack, untag))
}

int parse_htpl_exit(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    printcode("exit;\n");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_foreach___fwd(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 2) RETURN(croak("%sFOREACH called with %d arguments, minimum needed is 2", (untag ? "/" : ""), numtokens))
    pushscope(scope_foreach, 0);
    printfcode("foreach ${\"%s\"} (%s) {\n", gettoken(1), numtokens >= abs(2) ? gettokenlist(2, ", ", "", "\"$s\"") : "()");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_foreach___rev(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    printcode("}\n");
    if (!currscope) RETURN(croak("Unexpected FOREACH"))
    if (currscope->scope != scope_foreach) RETURN(croak("Now in scope %s from %d and met FOREACH, expecting: foreach", scope_names[currscope->scope], currscope->nline))
    popscope();
    nesting = 0;
    RETURN(1)
}

int parse_htpl_foreach(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (!untag) RETURN(parse_htpl_foreach___fwd(stack, untag))
        else RETURN(parse_htpl_foreach___rev(stack, untag))
}

int parse_htpl_pts_pool(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 3) RETURN(croak("%sPTS POOL called with %d arguments, minimum needed is 3", (untag ? "/" : ""), numtokens))
    if (numtokens > 3) RETURN(croak("%sPTS POOL called with %d arguments, maximum needed is 3", (untag ? "/" : ""), numtokens))
    printfcode("${\"%s\"} = $HTML::HTPL::pts_obj->ClientObject(\"%s\", \n", gettoken(1), gettoken(2));
    printfcode(" \"getObject\", \"%s\");\n", gettoken(3));
    nesting = 0;
    RETURN(1)
}

int parse_htpl_pts_call(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 2) RETURN(croak("%sPTS CALL called with %d arguments, minimum needed is 2", (untag ? "/" : ""), numtokens))
    printfcode("${\"%s\"} = $HTML::HTPL::pts_obj->Call(\"%s\", %s);\n", gettoken(1), gettoken(1), numtokens >= abs(3) ? gettokenlist(3, ", ", "", "\"$s\"") : "()");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_pts_create(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 2) RETURN(croak("%sPTS CREATE called with %d arguments, minimum needed is 2", (untag ? "/" : ""), numtokens))
    printfcode("${\"%s\"} = $HTML::HTPL::pts_obj->ClientObject(\"%s\", \"new\",\n", gettoken(1), gettoken(2));
    printfcode("                      %s);\n", numtokens >= abs(3) ? gettokenlist(3, ", ", "", "\"$s\"") : "()");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_pts_set(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    printcode("{\n");
    if (numtokens < 2) RETURN(croak("%sPTS SET called with %d arguments, minimum needed is 2", (untag ? "/" : ""), numtokens))
    if (numtokens > 3) RETURN(croak("%sPTS SET called with %d arguments, maximum needed is 3", (untag ? "/" : ""), numtokens))
    printfcode("my @t = split(/:/, \"%s\");\n", gettoken(1));
    printcode("push(@t, $HTML::HTPL::Config::htpl_pts_port);\n");
    printcode("$HTML::HTPL::pts_obj = new RPC::PlClient(\n");
    printcode("             peeraddr => $t[0],\n");
    printcode("             peerport => $t[1],\n");
    printfcode("             user => \"%s\",\n", gettoken(2));
    printfcode("             password => \"%s\",\n", gettoken(3));
    printcode("             application => \"pts\",\n");
    printcode("             version => 1.0);\n");
    printcode("}\n");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_pts(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (!done) {
        done = 1;
        printcode("use RPC::PlClient;\n");
    }
    eat(&stack, token);
    {
        static char *pts_table[] = {"CALL",
            "CREATE",
            "POOL",
            "SET"};
        static int pts_locations[] = { 2, -1, 3, -1, 1, -1, 0, -1 };
        static int pts_shortcuts[] = { -1, -1, -1, -1, 0, 2, -1, 4, 6, -1 };
        static struct hash_t pts_hash = {pts_table,
             pts_locations, pts_shortcuts};

        static parser funs[] = { parse_htpl_pts_call, parse_htpl_pts_create, parse_htpl_pts_pool, parse_htpl_pts_set };
        int n;
        parser fun;
        n = search_hash(&pts_hash, token, 0);
        if (n < 0) RETURN(0)
        fun = funs[n];
        RETURN(fun(stack, untag))
    }
}

int parse_htpl_next(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    printcode("}\n");
    if (!currscope) RETURN(croak("Unexpected NEXT"))
    if (currscope->scope != scope_for && currscope->scope != scope_foreach) RETURN(croak("Now in scope %s from %d and met NEXT, expecting: for,foreach", scope_names[currscope->scope], currscope->nline))
    popscope();
    nesting = 0;
    RETURN(1)
}

int parse_htpl_ldap_search(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    printcode("{\n");
    if (numtokens < 1) RETURN(croak("%sLDAP SEARCH called with %d arguments, minimum needed is 1", (untag ? "/" : ""), numtokens))
    code = 1;
    kludge_reunifying = 1;
    asprintf(&buff, "LDAP DOSEARCH %s", gettokenlist(1, " ", "", ""));
    kludge_reunifying = 0;
    nest++;
    code = parse_htpl(buff, untag);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);

    printfcode("${\"%s\"} = $HTML::HTPL::ldap_query;\n", gettoken(1));
    printcode("}\n");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_ldap_delete(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 1) RETURN(croak("%sLDAP DELETE called with %d arguments, minimum needed is 1", (untag ? "/" : ""), numtokens))
    if (numtokens > 1) RETURN(croak("%sLDAP DELETE called with %d arguments, maximum needed is 1", (untag ? "/" : ""), numtokens))
    printfcode("$HTML::HTPL::htpl_dir_obj->modify(\"%s\");\n", gettoken(1));
    nesting = 0;
    RETURN(1)
}

int parse_htpl_ldap_dosearch(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    printcode("{\n");
    printfcode("my %%tags = &HTML::HTPL::Sys::parse_tags('%s');\n", gettokenlist(1, " ", "", ""));
    printcode("&publish(&proper(sub {uc($_);}, %tags));\n");
    printcode("&HTML::HTPL::Sys::enforce_tags('filter,base', 'LDAP DOSEARCH', %tags);\n");
    if (!nest) RETURN(0)
    printcode("		$HTML::HTPL::ldap_query =\n");
    printcode("			$HTML::HTPL::htpl_dir_obj->search(\n");
    printcode("			$tags{'FILTER'}, $tags{'BASE'}, $tags{'SCOPE'},\n");
    printcode("                        $tags{'ATTR'} . $tags{'ATTRS'} .\n");
    printcode("			$tags{'ATTRIBUTES'}, $tags{'SIZE'} .\n");
    printcode("			$tags{'LIMIT'} . $tags{'SIZELIMIT'}, $tags{'KEY'}\n");
    printcode("			. $tags{'SORTKEY'});\n");
    printcode("	\n");
    printcode("}\n");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_ldap_add(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 2) RETURN(croak("%sLDAP ADD called with %d arguments, minimum needed is 2", (untag ? "/" : ""), numtokens))
    printfcode("$HTML::HTPL::htpl_dir_obj->add(\"%s\", \"%2*\");\n", gettoken(1));
    nesting = 0;
    RETURN(1)
}

int parse_htpl_ldap_modify(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 2) RETURN(croak("%sLDAP MODIFY called with %d arguments, minimum needed is 2", (untag ? "/" : ""), numtokens))
    printfcode("$HTML::HTPL::htpl_dir_obj->modify(\"%s\", \"%2*\");\n", gettoken(1));
    nesting = 0;
    RETURN(1)
}

int parse_htpl_ldap_init(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 1) RETURN(croak("%sLDAP INIT called with %d arguments, minimum needed is 1", (untag ? "/" : ""), numtokens))
    if (numtokens > 4) RETURN(croak("%sLDAP INIT called with %d arguments, maximum needed is 4", (untag ? "/" : ""), numtokens))
    printcode("$HTML::HTPL::htpl_dir_obj = new\n");
    printfcode("              HTML::HTPL::LDAP(%s);\n", numtokens >= abs(1) ? gettokenlist(1, ", ", "", "\"$s\"") : "()");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_ldap(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (!done) {
        done = 1;
        printcode("use HTML::HTPL::LDAP;\n");
    }
    eat(&stack, token);
    {
        static char *ldap_table[] = {"ADD",
            "DELETE",
            "DOSEARCH",
            "INIT",
            "MODIFY",
            "SEARCH"};
        static int ldap_locations[] = { 1, -1, 4, -1, 5, -1, 0, -1, 2, -1, 3, -1 };
        static int ldap_shortcuts[] = { 0, 2, 4, 6, 8, -1, -1, -1, 10, -1 };
        static struct hash_t ldap_hash = {ldap_table,
             ldap_locations, ldap_shortcuts};

        static parser funs[] = { parse_htpl_ldap_add, parse_htpl_ldap_delete, parse_htpl_ldap_dosearch, parse_htpl_ldap_init, parse_htpl_ldap_modify, parse_htpl_ldap_search };
        int n;
        parser fun;
        n = search_hash(&ldap_hash, token, 0);
        if (n < 0) RETURN(0)
        fun = funs[n];
        RETURN(fun(stack, untag))
    }
}

int parse_htpl_fetchcell(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 3) RETURN(croak("%sFETCHCELL called with %d arguments, minimum needed is 3", (untag ? "/" : ""), numtokens))
    if (numtokens > 3) RETURN(croak("%sFETCHCELL called with %d arguments, maximum needed is 3", (untag ? "/" : ""), numtokens))
    printfcode("${\"%s\"} = ${\"%s\"}->get(\"%s\");\n", gettoken(3), gettoken(1), gettoken(2));
    nesting = 0;
    RETURN(1)
}

int parse_htpl_dispose(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 1) RETURN(croak("%sDISPOSE called with %d arguments, minimum needed is 1", (untag ? "/" : ""), numtokens))
    printfcode("foreach (%s) {\n", gettokenlist(1, ", ", "$", ""));
    printcode("	undef %$_;\n");
    printcode("	undef $_;\n");
    printcode("}\n");
    nesting = 0;
    RETURN(1)
}

int parse_htpl_if___fwd(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 1) RETURN(croak("%sIF called with %d arguments, minimum needed is 1", (untag ? "/" : ""), numtokens))
    pushscope(scope_if_then, 0);
    printfcode("if (%s) {\n", gettokenlist(1, " ", "", ""));
    nesting = 0;
    RETURN(1)
}

int parse_htpl_if___rev(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    nesting++;
    if (nesting > 1) RETURN(croak("Infinite loop in IF"))
    kludge_reunifying = 1;
    asprintf(&buff, "ENDIF");
    kludge_reunifying = 0;
    nest++;
    code = parse_htpl(buff, untag);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);

    nesting = 0;
    RETURN(1)
}

int parse_htpl_if(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (!untag) RETURN(parse_htpl_if___fwd(stack, untag))
        else RETURN(parse_htpl_if___rev(stack, untag))
}

int parse_htpl_ifnull___fwd(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (numtokens < 1) RETURN(croak("%sIFNULL called with %d arguments, minimum needed is 1", (untag ? "/" : ""), numtokens))
    if (numtokens > 1) RETURN(croak("%sIFNULL called with %d arguments, maximum needed is 1", (untag ? "/" : ""), numtokens))
    pushscope(scope_if_then, 0);
    printfcode("if (!${\"%s\"} || ${\"%s\"}->none) {\n", gettoken(1), gettoken(1));
    nesting = 0;
    RETURN(1)
}

int parse_htpl_ifnull___rev(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    nesting++;
    if (nesting > 1) RETURN(croak("Infinite loop in IFNULL"))
    kludge_reunifying = 1;
    asprintf(&buff, "ENDIF");
    kludge_reunifying = 0;
    nest++;
    code = parse_htpl(buff, untag);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);

    nesting = 0;
    RETURN(1)
}

int parse_htpl_ifnull(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    if (!untag) RETURN(parse_htpl_ifnull___fwd(stack, untag))
        else RETURN(parse_htpl_ifnull___rev(stack, untag))
}

int parse_htpl(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    eat(&stack, token);
    {
        static char *htpl_table[] = {"ASSERT",
            "AUTH",
            "AUTH_CREATE",
            "BREAK",
            "CALL",
            "CASE",
            "CATCH",
            "CLASS",
            "CLEANUP",
            "CLSUTILS",
            "COMBOBOX",
            "CONNECTION",
            "CONSTRUCTOR",
            "CONTINUE",
            "COPY",
            "COUNTER",
            "DEFAULT",
            "DEFINE",
            "DESTRUCTOR",
            "DIE",
            "DIR",
            "DISPOSE",
            "ELSE",
            "END",
            "ENDIF",
            "EXIT",
            "FETCH",
            "FETCHCELL",
            "FETCHCOLS",
            "FETCHIT",
            "FETCHITORBREAK",
            "FILE",
            "FILTER",
            "FOR",
            "FOREACH",
            "GRAPH",
            "IF",
            "IFNOTNULL",
            "IFNULL",
            "IMG",
            "INIT",
            "LDAP",
            "LISTBOX",
            "LOAD",
            "LOOP",
            "MAIL",
            "MEM",
            "MERGE",
            "METHOD",
            "NET",
            "NEXT",
            "OUT",
            "PROC",
            "PROJECT",
            "PTS",
            "PUBLISH",
            "REDIRECT",
            "REM",
            "REQ_SYMBOL",
            "REWIND",
            "SERVBOXEN",
            "SQL",
            "SWITCH",
            "TEXT",
            "THROW",
            "TIME",
            "TRY"};
        static int htpl_locations[] = { 17, 18, 30, 39, 46, 56, 63, -1, 12, 21, 37, 61, -1, 25, 43, 59, 62, 65, -1, 9, 27, 33, 54, 57, -1, 1, 2, 7, 41, 44, 48, 52, -1, 13, 19, 22, 23, 26, 42, 49, 64, -1, 11, 31, 38, 47, 50, 58, -1, 3, 8, 14, 24, 29, 34, 35, 53, 55, 60, -1, 0, 4, 10, 32, 36, 40, 45, -1, 5, 6, 15, 16, 20, 28, 51, 66, -1 };
        static int htpl_shortcuts[] = { 0, 8, 13, 19, 25, 33, 42, 49, 60, 68 };
        static struct hash_t htpl_hash = {htpl_table,
             htpl_locations, htpl_shortcuts};

        static parser funs[] = { parse_htpl_assert, parse_htpl_auth, parse_htpl_auth_create, parse_htpl_break, parse_htpl_call, parse_htpl_case, parse_htpl_catch, parse_htpl_class, parse_htpl_cleanup, parse_htpl_clsutils, parse_htpl_combobox, parse_htpl_connection, parse_htpl_constructor, parse_htpl_continue, parse_htpl_copy, parse_htpl_counter, parse_htpl_default, parse_htpl_define, parse_htpl_destructor, parse_htpl_die, parse_htpl_dir, parse_htpl_dispose, parse_htpl_else, parse_htpl_end, parse_htpl_endif, parse_htpl_exit, parse_htpl_fetch, parse_htpl_fetchcell, parse_htpl_fetchcols, parse_htpl_fetchit, parse_htpl_fetchitorbreak, parse_htpl_file, parse_htpl_filter, parse_htpl_for, parse_htpl_foreach, parse_htpl_graph, parse_htpl_if, parse_htpl_ifnotnull, parse_htpl_ifnull, parse_htpl_img, parse_htpl_init, parse_htpl_ldap, parse_htpl_listbox, parse_htpl_load, parse_htpl_loop, parse_htpl_mail, parse_htpl_mem, parse_htpl_merge, parse_htpl_method, parse_htpl_net, parse_htpl_next, parse_htpl_out, parse_htpl_proc, parse_htpl_project, parse_htpl_pts, parse_htpl_publish, parse_htpl_redirect, parse_htpl_rem, parse_htpl_req_symbol, parse_htpl_rewind, parse_htpl_servboxen, parse_htpl_sql, parse_htpl_switch, parse_htpl_text, parse_htpl_throw, parse_htpl_time, parse_htpl_try };
        int n;
        parser fun;
        n = search_hash(&htpl_hash, token, 0);
        if (n < 0) RETURN(0)
        fun = funs[n];
        RETURN(fun(stack, untag))
    }
}

int parse_(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
    eat(&stack, token);
    {
        static char *htpl_table[] = {"HTPL"};
        static int htpl_locations[] = { 0, -1 };
        static int htpl_shortcuts[] = { -1, -1, -1, -1, -1, -1, 0, -1, -1, -1 };
        static struct hash_t htpl_hash = {htpl_table,
             htpl_locations, htpl_shortcuts};

        static parser funs[] = { parse_htpl };
        int n;
        parser fun;
        n = search_hash(&htpl_hash, token, 0);
        if (n < 0) RETURN(0)
        fun = funs[n];
        RETURN(fun(stack, untag))
    }
}

