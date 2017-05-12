/***************************************************************f
 * HTPL by Ariel Brosh                                         *
 * This program can be used freely, but the source should not  *
 * be modified without notice.                                 *
 * Copyright 1997-1999 Ariel Brosh                             *
 ***************************************************************/

/***************************************************
 * htpl.c - main program file                      *
 ***************************************************/

#define __HTMAIN__
#include "htpl.h"
#include "htpl-sh.h"

/**********************************************
 * Determinist Finite Automaton               *
 **********************************************/
DFA eat_one(ch, status, perlkind, language) 
    int ch;
    int language;
    int perlkind;
    DFA status; {
    int sch = ch;
    static int tcllist = 0;
    ch = toupper(ch);
    if (cstate == CC) return PERL;
    switch (status) {
        case ESCAPE:     return D_QUOTE;
        case COMMENT:    switch (ch) {
                             case '\n': if (language == LNG_PERL) return PERL_END;
                                        else return PERL;
                             default:   return COMMENT;
                         }
        case QUOTE:      switch (ch) {
                             case '\'': return PERL;
                             default:   return QUOTE;
                         }
        case D_QUOTE:    switch(ch) {
                             case '\\': return ESCAPE;
                             case '"':  return PERL;
                             default:   return D_QUOTE;
                         }
        case FIELD:      return PERL;
        case TCL_INTER:  switch(ch) {
                             case '>': return TCL_DO_INTER;
                             default : return PERL;
                         }
        case PERL:       switch(ch) {
                             case '?':  if (language == LNG_TCL) return TCL_INTER;
                             case '-':  return FIELD;
                             case '\'': if (language == LNG_PERL) return QUOTE;
                             case '"':  return D_QUOTE;
                             case '#':  return COMMENT;
                             case '%':  if (perlkind == CODE_EVAL) 
                                  return PERL_UNEXP; 
                                  else return PERL;
                             case ';': 
                             case '{':  if (language == LNG_TCL) {
                                            tcllist++;
                                            return PERL;
                                        }
                             case '}':  if (language == LNG_PERL) return PERL_END;
                                        if (language == LNG_TCL && tcllist) tcllist--;
                                        return PERL;
                             case '<':  if (language == LNG_TCL && !tcllist) return UPERL_0;
                             default:   return PERL;
                         }
       case PERL_END:    switch(ch) {
                             case '-':  return FIELD;
                             case '\'': return QUOTE;
                             case '"':  return D_QUOTE;
                             case ' ': 
                             case '\t': 
                             case ';': 
                             case '}':
                             case '{':  return PERL_END;
                             case '%': if (perlkind == CODE_EVAL) 
                                           return PERL_UNEXP;  
                                       else return PERL; 
                             case '>':  if (perlkind == CODE_TAG) return HTML; else 
						return PERL;
                             case '<':  if (perlkind == CODE_BLOCK)
                                               return UPERL_0;
					else return PERL;
                             default:   return PERL;
                         }
       case PERL_UNEXP:  switch(ch) {
                             case '>':  return HTML;
                             default:   return PERL;
                         }
       case HTML:        switch(ch) {
                             case '<':  return BRAC;
                             default:   return HTML;
                         }
       case BRAC:        switch(ch) {
                             case '#':  if (language == LNG_PERL) return PERL;
                             case '?':  if (language == LNG_PERL) return TCL;
                                        if (language == LNG_TCL &&
                                           (perlkind == CODE_TAG ||
                                              perlkind == CODE_BLOCK)) 
                                                return PERL;
                                        return TAG;
                             case '%':  return PERL_EXP;
                             case '@':  return PREP;
                             case 'H':  return TAG_H;
                             case '>':  return HTML;
                             case '/':  return UNTAG;
                             case 'P':  return PERL_1;
                             case 'T':  return TCL_1;
                             case '!':  return PRECOM_1;
                             default:   return TAG_NONE;
                         }
       case TAG:         switch(ch) {
                             case '"':  return T_QUOTE;
                             case '>':  return HTML;
                             default:   return TAG;
                         }
       case UNTAG:       switch(ch) {
                             case 'H':  return TAG_H;
                             default:   return TAG_NONE;
                         }
       case TAG_H:       switch(ch) {
                             case 'T':  return TAG;
                             default:   return TAG_NONE;
                         }
       case T_QUOTE:     switch(ch) {
                             case '"':  return TAG;
                             default:   return T_QUOTE;
                         }
        case UPERL_0:    switch (ch) {
                             case '/': return UPERL_1;
                             default:   return PERL;
                         }
        case UPERL_1:    switch (ch) {
                             case 'P': if (language == LNG_PERL) return UPERL_2;
                             case 'T': if (language == LNG_TCL) return UPERL_2;
                             default:  return PERL;
                         }
        case UPERL_2:    switch (ch) {
                             case 'E': if (language == LNG_PERL) return UPERL_3;
                             case 'C': if (language == LNG_TCL) return UPERL_3;
                             default:   return PERL;
                         }
        case UPERL_3:    switch (ch) {
                             case 'R': if (language == LNG_PERL) return UPERL_4;
                             case 'L': if (language == LNG_TCL) return UPERL_5;
                             default:  return PERL;
                         }
        case UPERL_4:    switch (ch) {
                             case 'L': return UPERL_5;
                             default:   return PERL;
                         }
        case UPERL_5:    switch (ch) {
                             case '>': return HTML;
                             default:  return PERL;
                         }
        case PERL_1:      switch (ch) {
                             case 'E': return PERL_2;
                             case '>': return HTML;
                             default:  return TAG_NONE;
                         }
        case PERL_2:     switch (ch) {
                             case 'R': return PERL_3;
                             case '>': return HTML;
                             default:  return TAG_NONE;
                         }
        case PERL_3:     switch (ch) {
                             case '>' : return HTML;
                             case 'L':  return PERL_4;
                             default:   return TAG_NONE;
                         }
        case PERL_4:     switch (ch) {
                             case '>': return PERL_TAG;
                             default:  return TAG_NONE;
                         }
        case TCL_1   :  switch (ch) {
                             case 'C': return TCL_2;
                             default:  return TAG_NONE;
                        }
        case TCL_2   :  switch(ch) {
                             case 'L': return TCL_3;
                             default:  return TAG_NONE;  
                        }
        case TCL_3   :  switch(ch) {
                            case '>':  return TCL_TAG;
                            default:   return TAG_NONE;
                        }
        case PRECOM_1:  switch(ch) {
                             case '-': return PRECOM_2;
                             default:  return TAG_NONE;
                        }
        case PRECOM_2:  switch(ch) {
                             case '-': return PRECOM_3;
                             default:  return TAG_NONE;
                        }
        case PRECOM_3:  switch(ch) {
                             case '-': return SILENCE;
                             default:  return TAG_NONE;
                        }
        case SILENCE :  switch(ch) {
                             case '-' : return POSTCOM_1;
                             default:   return SILENCE;
                        }
        case POSTCOM_1: switch(ch) {
                             case '-': return POSTCOM_2;
                             default:  return SILENCE;
                        }
        case POSTCOM_2: switch(ch) {
                             case '-': return POSTCOM_3;
                             default:  return SILENCE;
                        }
        case POSTCOM_3: switch(ch) {
                             case '-': return POSTCOM_4;
                             default:  return SILENCE;
                        }
        case POSTCOM_4: switch(ch) {
                             case '>': return HTML;
                             default:  return SILENCE;
                        }
        case PREP:      switch(ch) {
                            case '>': return UNPREP;
                            default:  return PREP;
                        }
        case PREPBUFF:  return PREPBUFF;
    }
}

/*
Obsolette hard wire LDAP support from version 2.00

void parseldap(line, ld)
    STR line;
    struct ldapp *ld; {

    DN token, work;

    pchar ch, ptr, lastptr;
    DN safe;

#define choose(field) ptr=ld->field; lastptr = ptr; *ptr = '\0'; continue;
#define dechoose ptr = safe; continue;

    ch = safe;

    strcpy(ld->scope, "sub");
    strcpy(ld->start, "");
    strcpy(ld->server, "127.0.0.1");
    strcpy(ld->pass, "");
    strcpy(ld->bind, "");
    strcpy(ld->dn, "");
    strcpy(ld->filter, "objectclass=*");
    strcpy(ld->attributes, "");
    strcpy(ld->sortkey, "");
    ld->port = 389;
    ld->sizelimit = -1;

    while (*line) {
        eat(&line, token);
        if (!strcasecmp(token, "PORT")) {
            eat(&line, token);
            sscanf(token, "%d", &ld->port);
            dechoose
        }
        if (!strcasecmp(token, "SIZE")) {
            eat(&line, token);
            sscanf(token, "%d", &ld->sizelimit);
            dechoose
        }
        if (!strcasecmp(token, "SCOPE")) {
            eat(&line, ld->scope);
            dechoose
        }
        if (!strcasecmp(token, "SORT")) {
            eat(&line, ld->sortkey);
            dechoose
        }
        if (!strcasecmp(token, "SERVER")) {
            eat(&line, ld->server);
            dechoose
        }
        if (!strcasecmp(token, "PASSWORD")) {
            eat(&line, ld->pass);
            dechoose
        }
        if (!strcasecmp(token, "START")) {
            choose(start)
        }
        if (!strcasecmp(token, "BIND")) {
            choose(bind)
        }
        if (!strcasecmp(token, "DN")) {
            choose(dn)
        }
        if (!strcasecmp(token, "FILTER")) {
            choose(filter)
        }
        if (!strcasecmp(token, "ATTRIBUTES")) {
            choose(attributes)
        }

        if (ptr == lastptr) *ptr++ = ' ';
        ch = token;
        while (*ch) *ptr++ = *ch++;
        *ptr = '\0';
        lastptr = ptr;
    }
#undef choose
#undef dechoose
}

void outldap(o, line)
    FILE *o;
    STR line; {
    TOKEN action;
    TOKEN token;
    pchar ch;
    long limit;
    static short declared = 0;
    short state = 0;
    TOKEN cursor;
    int port;
    struct ldapp ld;
    pchar save;

#define parse parseldap(line, &ld);

    save = line;

    eat (&line, action);

    if (!strcasecmp(action, "CONNECT")) {
        parse
        if (!declared) {
                outf(o, "use htpl_dir;");
                declared = -1;
        }

        fprintf(o, "my %s = htpl_dir->new(\"%s\", %d, \"%s\", \"%s\");\n",
          HTPL_DIR_OBJECT, ld.server, ld.port, ld.bind, ld.pass);
        return;
    }

    if (!strcasecmp(action, "SEARCH")) {
        eat(&line, cursor);
        parse
        fprintf(o, "$%s = %s->search(\"%s\", \"%s\", \"%s\", \"%s\", %d, \"%s\");\n",
           cursor, HTPL_DIR_OBJECT, ld.filter, ld.start, ld.scope,
           ld.attributes, ld.sizelimit, ld.sortkey);
        return;
    }

    if (!strcasecmp(action, "ADD")) {
        parse

        fprintf(o, "%s->add(\"%s\", \"%s\");\n", HTPL_DIR_OBJECT, ld.dn,
              ld.attributes); 
        return;
    }

    if (!strcasecmp(action, "MODIFY")) {
        parse

        fprintf(o, "%s->modify(\"%s\", \"%s\");\n", HTPL_DIR_OBJECT,
             ld.dn, ld.attributes); 
        return;
    }

    if (!strcasecmp(action, "DELETE")) {
        parse

        fprintf(o, "%s->delete(\"%s\");\n", HTPL_DIR_OBJECT, ld.dn);
        return;
    }

    fputs(save, o);

#undef parse
}

*/

/*************************************************
 * Process compile time include files            *
 *************************************************/

void doinclude(o, filename1) 
    FILE *o;
    STR filename1; {
    FILE *i;
    FILENAME now;
    long nnow;
    FILENAME cdir, ndir;
    FILENAME filename;
    FILE *c;

    getcwd(cdir, sizeof(cdir));

    finddir(filename, ndir);

    strcpy(now, infile);
    nnow = nline;

    sprintf(infile, "%s included from %s", filename, now);
    nline = 1;

    tryexts(filename1, filename, ".hh.inc");
    i = opensource(filename);
    strcpy(thefilename, filename);

    chdir(ndir);
    getcwd(ndir, sizeof(ndir));

    if (strcmp(ndir, cdir)) outf(o, "use lib '%s';", qualify(ndir, 0));
    c = fopen("/dev/null", "w");
    outf(o, "# Including %s", filename);
    outline(o, thefilename, 1);
    process(i, c, o);
    fclose(i);
    fclose(c);
    strcpy(infile, now);
    nline = nnow;

    chdir(cdir);
}

int beforefunc(node, level, tag)
    BTREE *node;
    int level;
    PTR tag; {

    FILE *o = (FILE *)tag;
    STR key = (*node)->key;
    STR data = (STR)((*node)->data);

    outf(o, "$%s = \"%s\";", key, data);
    return 0;
}

void beforerequire(o, vars)
    FILE *o;
    STR vars; {
    pchar ch = vars;
    pchar v, p;
    char boundary;
    BTREE tree = NULL;
    STR result = malloc(2);
    int len = 0, size = 1, len2;

    result[0] = '\0';
    while (*ch) {
        while (*ch && isspace(*ch)) ch++;
        if (!*ch) break;
        v = ch++;
        while (*ch && isalnum(*ch)) ch++;
        if (!*ch) break;
        boundary = *ch;

#define BOUND(ch1, ch2) if (boundary == (ch1)) boundary = (ch2); else \
if (boundary == (ch2)) boundary = (ch1);

        BOUND('(', ')')
        BOUND('[', ']')
        BOUND('{', '}')
#undef BOUND

        len2 = len;
        len += (ch - v);
        *ch++ = '\0';
        p = ch;
        while (*ch && *ch != boundary) ch++;
        if (!*ch) break;
        *ch++ = '\0';
        btreeadd(&tree, v, strdup(p));

        if (len >= size - 2) {
            size = len + 5;
            result = realloc(result, size);
        }
        if (len2 > 0) result[len2++] = ' ';
        memcpy(&result[len2], v, p - 1 - v);
        len = len2 + p - 1 - v;
        result[len] = '\0';
    }
    outf(o, "&HTML::HTPL::Sys::pushvars(qw(%s));", result);
    free(result);
    btreescan(&tree, beforefunc, 0, o, BTREE_INFIX);
    btreekill(&tree);
}

/********************************************
 * Process runtime include files            *
 ********************************************/

void dorequire(filename1, o, params) 
    FILE *o;
    STR filename1;
    STR params; {

    FILENAME filename, script, component;

    if (params && !*params) params = NULL;

    makecache(filename1, filename, "htpm");
    makecache(filename1, component, "htpc");
    makecache(filename1, script, "ht.pl");

    if (depend(filename, component) > 0 || fit(filename, component, 0)) {
        makecomponent(filename);
        fit(filename, component, 1);
    }
    if (depend(script, filename) > 0 || fit(script, filename, 0)) compile(filename, script);
    if (params) beforerequire(o, params);
    outf(o, "do \"%s\";", qualify(script, 0));
    if (params) outf(o, "&HTML::HTPL::Sys::popvars;");
} 

/**************************************
 * Link XSUB file                     *
 **************************************/

void linksubs(xs) 
    FILENAME xs; {

    FILENAME tc;
    COMMAND cmd;

    makecache(xs, tc, "");

    sprintf(cmd, "%s %s%chtpl-xsub.pl %s %s", PERL_BIN, bindir, SLASH_CHAR, tc, bindir);
    system(cmd);
}

/***********************************
 * Out an XSUB C line              *
 ***********************************/

void outcc(c, line)
    FILE *c;
    STR line; {

    if (!hasxs) {
/*        fprintf(c, "#ifdef __c_plus_plus\nextern \"C\" {\n\n#endif\n");
        fprintf(c, "#include \"perl.h\"\n#include \"XSUB.h\"\n#include \"EXTERN.h\"\n");
        fprintf(c, "\n#endif\n}\n#endif\n");
        fprintf(c, "\n\nMODULE htpl  PACKAGE htpl\n\n");*/
        hasxs = -1;
    }

    fprintf(c, "%s%s", line, NEWLINE);
}

/***********************************
 * Out a text line                 *
 ***********************************/

void outplain(o, line, language)
    FILE *o;
    STR line; 
    int language; {
    STR copy;

    if (!*line) return;
    
    copy = escapevars(line);

    if (!language) {
        outf(o, "print \"%s\";", copy);
    } else {
        STR it = " -nonewline";
        STR ch = copy + strlen(copy) - 2;
        if (!strcmp(ch, "\\n")) {
            it = "";
            *ch = '\0';
        }
        outf(o, "puts%s \"%s\"", it, copy);
    }
    free(copy);
    rline++;
}

STR tcl_boundary = "ThisIsTheEndOfOurTCLCodeEmbededIntoThePerlCodeInsideHTPL";

void begintcl(o)
    FILE *o; {
    static have_interp = 0;

    if (!have_interp) {
        outf(o, "use HTML::HTPL::Tcl qw(tclexec);\n");
        have_interp = 1;
    }
    outf(o, "&tclexec(<<'%s');", tcl_boundary);
}

void endtcl(o)
    FILE *o; {
    outf(o, tcl_boundary);
}

void outtcl(o, line)
    FILE *o;
    STR line; {
    outf(o, line);
}

/***********************************************
 * Out a perl line. Process macro if necessary *
 ***********************************************/

void outperl(o, c, line, language)
    FILE *o, *c;
    int language;
    STR line; {
    TOKEN token, token2;
    STR save;
    long lpos = -1;
    pchar ch;

    if (!*line) {
        outf(o, "");
        return;
    }

    if (language == LNG_TCL) {
        outtcl(o, line);
        return;
    }

    for (ch = line; *ch; ch++) ;

    ch--;
    while (*ch == '\n' || *ch == '\r') *ch-- = '\0';

    save = line;
    eat(&line, token);
    eat(&line, token2);

    if (!strcasecmp(token, "#END") && !strcasecmp(token2, "XSUB")
            && cstate == CC ) {
        outdbg(o, save);
        cstate = 0;
        return;
    }

    if (cstate == CC) {
        outcc(c, save);
        return;
    }

/*
    if (!strcasecmp(token, "#LDAP")) {
        outdbg(o, line);
        outldap(o, line);
        return;
    }
*/

    if (!strcasecmp(token, "#INCLUDE")) {
        outdbg(o, save);
        save = line;
        doinclude(o, line);
        outf(o, "# End of %s", save);
        return;
    }

    if (!strcasecmp(token, "#USE")) {
        outdbg(o, save);
        dorequire(token2, o, line);
        return;
    }

    if (!strcasecmp(token, "#XSUB")) {
        cstate = CC;
        outdbg(o, save);
        return;
    }

/* Process macro if necessary */

    if (token[0] == '#' && token[1]) {
        outperlline(o, save);
        return;
    }
    outblock(o, save);
    rline++;
}

/*
Unknown alian
**
void xxxcheck(o)
    FILE *o; {

    static long last = 0;
    long this;

    if ((this = ftell(o)) - last > 1000) {
        fflush(o);
        last = this;
    }
}
*/

/**************************************************************
 * Main loop - read chars from input and send lines to output *
 **************************************************************/

void process(f, c, o) 
    FILE *f;
    FILE *o, *c; {
    int ch;
    DFA before;
    DFA after;
    DFA finish;
    STR line, htmlbuff;
    pchar ptr, saveptr;
    short code;
    short intag;
    pchar save;
    TOKEN engine, check;
    int perlkind;
    int language = LNG_PERL;
    TOKEN prep;
    STR prepbuff;
    long preplen;
    static STR prepend = "</@>";
    short prepstate = 0;
    TOKEN sub;
    pchar helper;
    int lastnl = 1;

/* Initialize */
    scopestack = NULL;
    currscope = NULL;
    mainscope.vars = NULL;
    bufferstack = NULL;
    pushbuffer();
    persiststack = NULL;
    scopelevel = 0;
    line = malloc(BUFF_SIZE);
    htmlbuff = malloc(BUFF_SIZE);
    ptr = line;
    before = HTML;
    intag = 0;
    save = NULL;

    bzero((void *)&internal_flags[0], sizeof(internal_flags));
#ifdef __DEBUG__
    if (noweb) {
        before = PERL_END;
        perlkind = CODE_TAG;
    }
#endif

    finish = before;
    after = finish;

/* Get a char from input, unless rollback buffer has chars */
    while ((ch=(save && *save ? *save++ : getc(f))) != EOF) {
/* If we have left over from  a macro tag */
        if (save && !*save) save = NULL;
/* Ignore CR to make dos users' life easier */
        if (ch == '\r') continue;
#ifdef PIPE_CMDS
        if (lastnl && ch == '|' && before == HTML) {
                TOKEN code;
                fgets(code, sizeof(code), f);
                outperl(o, c, code, language);
                goto nxt;
        }
#endif
        after = eat_one(ch, before, perlkind, language);

/* preprocess */
        if (after == PREP && before != PREP && intag) {
            intag = 0;
            ptr = prep;
            goto nxt;
        }
        if (after == UNPREP) {
            STR res;
            int ln;
            *ptr = '\0';
            preplen = BUFF_SIZE;
            ptr = prepbuff = malloc(preplen);
            after = PREPBUFF;
            goto nxt;
        }

        if (after == PREPBUFF) {
            int sofar = ptr - prepbuff;
            if (sofar + 2 > preplen) {
                preplen += BUFF_SIZE;
                prepbuff = realloc(prepbuff, preplen);
                ptr = prepbuff + sofar;
            }
            *ptr++ = ch;
            if (ch != prepend[prepstate++]) prepstate = 0;
            if (!prepend[prepstate]) {
                char *res;
                long len2;
                long len;
                ptr -= strlen(prepend);
                *ptr = '\0';
                res = preprocess(prepbuff, prep); 
                free(prepbuff);
                len = strlen(res);
                if (len > BUFF_SIZE) htmlbuff = realloc(htmlbuff, len);
                strcpy(htmlbuff, res);
                free(res);
                save = htmlbuff;
                ptr = saveptr;
                after = HTML;
            }
            goto nxt;
        }

/* If we just started a tag and we are not inside the rollback buffer */
/* Start accumulating tag for later macro tag match */
        if (after == BRAC && !save && !intag) {
            saveptr = ptr;
            ptr = htmlbuff;
            *ptr++ = ch;
            intag = 1;
            goto nxt;
        }
/* If this tag doesn't begin with HT - replay */
        if (intag && after == TAG_NONE) {
            *ptr++ = ch;
            *ptr = '\0';
            save = htmlbuff;
/*            *saveptr++ = *save++;*/
            ptr = saveptr;
            after = BRAC;
            intag = 0;
            goto nxt;
        }
/* If we finished a tag, it wasn't a replay */
        if (istag(before) && !istag(after) && intag) {
/* Seal tag */
            *ptr++ = ch;
            *ptr = '\0';
/* If we got a <PERL> tag, probably from a rollback */
/* This shuoldn't really be executed, as this tag is handled by the
automaton */
            if (!strcasecmp(htmlbuff, "<PERL>")) {
                after = PERL;
                *saveptr = '\0';
/* Yield the beginning of the line */
                if (line[0]) {
                    outplain(o, line, 0);
                    outline(o, thefilename, nline);
                }
                perlkind = CODE_BLOCK;
                intag = 0;
                ptr = line;
                goto nxt;
            }
            if (!strcasecmp(htmlbuff, "<TCL>")) {
                begintcl(o);
                after = PERL;
                *saveptr = '\0';
/* Yield the beginning of the line */
                if (line[0]) {
                    outplain(o, line, 0);
                    outline(o, thefilename, nline);
                }
                language = LNG_TCL;
                perlkind = CODE_BLOCK;
                intag = 0;
                ptr = line;
                goto nxt;
            }
            strncpy(sub, &htmlbuff[1], sizeof(sub));
            helper = strchr(sub, ' ');
            if (helper) *helper = '\0';
            helper = strchr(htmlbuff, ' ');
            if (helper) *helper++ /*= '\0' */;
            if ((!strcasecmp(sub, "HTINCLUDE")
              || !strcasecmp(sub, "HTUSE")) && helper) {
                pchar pch;
                pch = helper;
                while (*pch) if (*pch == '>') *pch = '\0';
                else pch++;
                intag = 0;
                ptr = line;
                if (!strcasecmp(sub, "HTINCLUDE")) {
                    doinclude(o, helper);
                    goto nxt;
                }
                if (!strcasecmp(sub, "HTUSE") ) {
                    pchar line = strchr(helper, ' ');
                    if (line) *line++ = '\0';
                    dorequire(helper, o, line);
                    goto nxt;
                }
            }
/* Match against macro tags  - our tag might be one */
            code = (language == LNG_PERL) && copyhtmltag(htmlbuff);
            intag = 0;
            if (!code) {
/* If it is not a macro tag - replay */
                save = htmlbuff;
/*                *saveptr++ = *save++;*/
                ptr = saveptr;
                after = BRAC;
                intag = 0;
            } else {
/* If this is a macro tag */
                *saveptr = '\0';
/* Flush begining of line */
                if (line[0]) {
                    outplain(o, line, language);
                }
/* Output resolved macro */
                outmacro(o, result, 0);
                ptr = line;
                intag = 0;
            }
            goto nxt;
        }
/* If we reached a new line */
        if (ch == '\n' && !intag && before != PREPBUFF || feof(f) && !intag) {
            *ptr = '\0';
/* If it was a command */
            if (isperl(after)) {
                if (ptr > line && *(ptr - 1) == '\\') {
                    char *saveptr2 = ptr;
                    ptr = line;
                    while (isspace(*ptr)) ptr++;
/* Allow multiline comments */
                    if (*ptr == '#') {
                        ptr = saveptr2 - 1;
                        *ptr++ = ' ';
                        goto nxt;
                    }
                }
                outperl(o, c, line, language);
/* It is now allowed to escape back to HTML  - allow matching > */
                if (language == LNG_PERL) after = PERL_END; 
            } else {
/* If we are printing HTML */
                strcat(line, qNEWLINE);
                outplain(o, line, language);
                lastnl = 1;
            }
            ptr = line;
            nline++;
            if (feof(f) && !intag) return;
            goto nxt;
        } 
/* If we just got <# */
        if (ishtml(before) && isperl(after)) { 
            if (intag) {
                 intag = 0;
                 *ptr = '\0';
                 ptr = htmlbuff;
                 while (*ptr) {
                     *saveptr++ = *ptr++;
                 }
                 ptr = saveptr;
            }
            if (after == PERL) {
/* If we matched  <# */
/* Erase the < we have on our buffer */
                ptr--;
                perlkind = CODE_TAG;
            } else if (after == PERL_TAG) {
/* If matched <PERL> */
                ptr -= 5;
                perlkind = CODE_TAG;
                language = LNG_PERL;
            } else if (after == TCL_TAG) {
                ptr -= 4;
                perlkind = CODE_BLOCK;
                language = LNG_TCL;
            } else if (after == TCL) {
                perlkind = CODE_TCL_TAG;
                language = LNG_TCL;
                ptr--;
                begintcl(o);
            } else if (after == PERL_EXP) {
/* We matched <% */
                ptr --;
                perlkind = CODE_EVAL;
            } 
            *ptr = '\0';
/* Dump beggining of line containing HTML */
            if (line[0]) {
                outplain(o, line, language);
                outline(o, thefilename, nline);
            }
            ptr = line;
            after = PERL;
            goto nxt;
        } 

        if (isperl(before) && ishtml(after)) { 
/* we just got > </PERL> or %> */
/* Erase redundant chars */
            if (perlkind == CODE_BLOCK && language == LNG_PERL) ptr -= 6;
            else if (perlkind == CODE_EVAL) ptr--;
            else if (perlkind == CODE_TCL_TAG && language == LNG_TCL) ptr--;
            else if (after == TCL_DO_INTER) ptr--; 
            else if ((perlkind == CODE_BLOCK || perlkind == CODE_TAG)
              && language == LNG_TCL) ptr -= 5;
            *ptr = '\0';
/* Allow expression evaluation, otherwise output code */
            if (line[0]) {
                if (perlkind == CODE_EVAL)  {
                    if (language == LNG_PERL) outf(o, "print (%s);", line);
                    else outf(o, "puts -nonewline %s", line);
                    perlkind = CODE_TAG;
                    after = -1;
                }
                else outperl(o, c, line, language);
                outline(o, thefilename, nline);
            }
            if (language == LNG_TCL && after == HTML &&
               (perlkind == CODE_BLOCK || perlkind == CODE_TAG) || 
               perlkind == CODE_TCL_TAG) {
                endtcl(o);
                language = LNG_PERL;
            }
            if (after == TCL_DO_INTER) perlkind = CODE_TAG;
            ptr = line;
            after = HTML;
            goto nxt;
        } 
/* Escape double quotes if we are printing HTML */
        if (ch == '"' && ishtml(after) && !intag) {
            *ptr++ = '\\';
        }
/* If we entered a server side comment */
        if (before == PRECOM_3 && after == SILENCE) {
            *(ptr - 5) = '\0';
            if (line[0]) {
                outplain(o, line, language);
                outline(o, thefilename, nline);
            }
            ptr = line;
            goto nxt;
        }
/* If we are inside a server side comment */
        if (before == SILENCE) goto nxt;
/* Ok - plain char - add to token */
        *ptr++ = ch;
nxt:
        if (ch != '\n') lastnl = 0;
/* If we are in a tag we know not to contain a macro */
        if (after == TAG_NONE) after = TAG;
/* Update automaton */
        before = after;
/* if croak() was called, no need to continue */
        if (fatal) return;
    }
/* free resources */
    free(line);
    free(htmlbuff);

/* if the scope stack is not empty as it should be */
    if (scopestack != NULL) {
/*        popscope();*/
	croak("Unterminated scope %s from line %d",  scope_names[currscope->scope], currscope->nline);
/*        while (scopestack) popscope(); 
** This is obsolette, as dumpscopes will be called */
    }

    if (after != finish) {
        croak("Did not end in correct section");
    }
}

/************************************************************
 * Main function - process parameters and go on             *
 ************************************************************/

int main(int argc, char *argv[], char **env) {
    FILE *i, *o;
    FILENAME script, postdata;
    COMMAND cmd;
    FILENAME output, headers;
    long red;
    FILENAME inputfile, work;
    pchar ch;
    int c;
    FILENAME error, xs;

/* COMPILATION is set by the Makefile */
#ifdef COMPILATION
    long compiletime = COMPILATION;
#else
    long compiletime = -1;
#endif
#ifdef BUILD
    long buildtime = BUILD;
#else
    long buildtime = -1;
#endif


/* Flush stdout. Maybe we were launched from within a CGI */

    fflush(stdout);

/* Find the directory containing the interpreter */

    getcwd(origdir, sizeof(FILENAME));

    if (strchr(argv[0], '/')) {
        finddir(argv[0], bindir);
        nodir(argv[0], work);
        sprintf(myself, "%s%c%s", bindir, SLASH_CHAR, work);
    } else {
	findpath(argv[0], myself);
        finddir(myself, bindir);
    }
    
    if (SLASH_CHAR != '/') replacechar(myself, '/', SLASH_CHAR);

    script[0] = '\0';

#ifdef _WIN32
#ifndef __DEBUG__
    if (argc > 1) {
        bootwin(argv[1]);
        getinput();
    } 
#endif
#endif

#ifdef __DEBUG__

/* Parse command line parameters */
    while ((c=getopt(argc, argv, "tcrwdb:o:")) != EOF) {
        switch(c) {
            case 'd': perldb = 1;
                      runit = 1;
                      break;
            case 'r': runit = 1;
                      break;
            case 'w': noweb = 1;
                      break;
            case 'c': inputcgi = 1;
                      runit = 1;
                      break;
            case 'b': strcpy(bindir, optarg);
                      break;
            case 't': noout = 1;
                      break;
            case 'o': strcpy(script, optarg);
                      create = 1;
                      break;
            default: printf("Invalid switch%s", NEWLINE);
                     exit(1);
        }
    }

    if  (inputcgi && !runit || inputcgi && noweb || noout && runit) {
        printf("Invalid option combination%s", NEWLINE);
        exit(1);
    }
    if (argc != optind + 1 && !(runit && noweb)) {
        printf("Usage: %s [-r | -t] [-w | -c] [-b<htpl directory> <script_name>%s", argv[0], NEWLINE); 
        exit(1);
    }

    strcpy(inputfile, argv[optind]);
#else

/* Get parameters from CGI environment */

    optind = 1;
#ifndef _WIN32
    strcpy(inputfile, nprot(GETENV("PATH_TRANSLATED")));
#else
    {
        FILENAME temp, temp2;
        int ln;
        strcpy(temp, nprot(GETENV("EXECUTABLE_PATH")));
        inputfile[0] = '\0';
        if (temp[0]) {
            replacechar(temp, '/', '\\');
            strcpy(temp2, GETENV("DOCUMENT_ROOT"));
            ln = strlen(temp2);
            if (temp2[ln] == '\\') temp2[ln] = '\0';
            sprintf(inputfile, "%s\\%s", temp2, &temp[1]);
        }
    }
#endif
    if (!inputfile[0]) {
        printf("Content-type: text/plain\n\n");
        printf("HTPL version %04.2f\n", (float)VERSION);
        if (buildtime > 0) 
            printf("Distribution built at %s.\n", convtime(buildtime));
        if (compiletime > 0) 
            printf("Compiled at %s.\n", convtime(compiletime));
        printf("Compiled with %d macros.\n", NUM_MACROS);
        printf("HTPL is developed by Ariel Brosh, ariel@atheist.org.il\n");
        exit(0);
    }
#endif

/* Find where to create temporary files */

#ifdef TMP_DIR
    strcpy(tmpdir, TMP_DIR);
    SETENV("TEMP", TMP_DIR);
#else
    strcpy(tmpdir, bindir);
#endif

/* Find names for temporary files */

    finddir(inputfile, scriptdir);

    if (script[0] == '\0') {
#ifdef __DEBUG__
    if (noweb && !runit)
        makecache(inputfile, script, "ht.pl");
    else
#endif
        makecache(inputfile, script, "perl");

    }

    makecache(script, xs, "htxs");

    maketemp(postdata, "post");
    maketemp(output, "out");
    maketemp(headers, "http");
    maketemp(error, "log");

/* Post data */

#ifndef __DEBUG__
    o = FOPEN(postdata, "w");
    if (GETENV("REQUEST_METHOD") && !strcmp(GETENV("REQUEST_METHOD"),"POST"))
        fcpy(stdin, o, 0);
    fclose(o);
#else
    strcpy(postdata, "/dev/null");
#endif


/* Make a copy of the arguments. This is needed for the non web mode */

#ifndef __DEBUG__
#define perldb 0
#endif

    myargc = argc - optind + 1 + perldb;
    myargv = calloc(myargc + 1 + perldb, sizeof(char *));
    memcpy(&myargv[1 + perldb], &argv[optind], sizeof(char *) * myargc);
    myargv[myargc] = NULL;
    myargv[0] = PERL_BIN;
    myargv[perldb + 1] = script;
    if (perldb) myargv[1] = "-d";

/* Convert script */
    generate(inputfile, script, xs, argv[0]);

/* Run script */

#ifdef __DEBUG__
    if (!noout) 
#endif

    if (!fatal) execute(script, postdata, headers, output, error);
/* Clean up */
    fflush(stdout);
    free(myargv);
}

/****************************************************
 * Convert htpl file to perl script                 *
 ****************************************************/

void generate(inputfile, script, xs, binary)
    STR inputfile, script, xs, binary; {


    FILE *o, *i, *c;
    pchar ch, newch;
    long l;
    FILENAME header;

/* Check existence */
    if (i = fopen(inputfile, "r")) fclose(i);
    else {
        puts("Status: 404 HTPL page not found");
	puts("Content-type: text/plain");
	puts("");
	printf("The HTPL file %s was not found on this server.\n", GETENV("PATH_INFO"));
	puts("");
	printf("Processed by HTPL version %04.2f\n", (float)VERSION);
        exit(-1);
    }


/* Check dependencies - don't create a perl script if it's newer than the
HTPL page. Check in dependency database if used */

#ifdef __DEBUG__
    if (runit)
#endif
    if (depend(script, inputfile) < 0 && depend(script, binary) < 0
          && !fit(script, inputfile, 0)) return;

/* Find the code to add at the beginning of the file */

#ifdef __DEBUG__
    if (noweb)
        sprintf(header, "%s%c%s", bindir, SLASH_CHAR, HEADER_FILE_OFFLINE);
    else
#endif
    sprintf(header, "%s%c%s", bindir, SLASH_CHAR, HEADER_FILE);
/* Create script file and add minimal code */

    o = FOPEN(script, "w");

    rline = 1;

    strcpy(thescript, script);

    outf(o, "#!%s%s%s", PERL_BIN, NEWLINE, NEWLINE);

    outf(o, "# Generated by %s from %s on %s%s#%s%s",
             myself, inputfile, convtime(time(NULL)), NEWLINE, NEWLINE, NEWLINE);

    outf(o, "use lib '%s', '%s';%s%s", qualify(bindir, 0),
        qualify(scriptdir, 1), NEWLINE, NEWLINE);

    outf(o, "# %s follows:", header);

/* Open a temporary file for XSUB C code */

    c = FOPEN(xs, "w");

/* dump htpl.head or htpl.offhead retrospectively */

    i = FOPEN(header, "r");
    fcpy(i, o, 1);

    fputs(NEWLINE, o);
    fclose(i);

    sprintf(header, "%s%c%s", bindir, SLASH_CHAR, HEADER_FILE_SITE);
    i = fopen(header, "r");
    if (i) {
        outf(o, "# %s follows:", header);

        fcpy(i, o, 1);

        fputs(NEWLINE, o);
        fclose(i);
    }



    outf(o, "# End of %s", header);

/* Process source */

    chdir(scriptdir); /* Path name of script so we can find includes */

/* Include default include file */

    strcpy(thefilename, "htpl-glob.hh");
    sprintf(infile, "Default include: %s", thefilename);
    i = fopen(thefilename, "r");
    if (i) {
        nline = 1;
        outf(o, "# Including: %s", infile);
	outline(o, thefilename, 1);
        process(i, c, o);
        fclose(i);
        fseek(c, 0, SEEK_SET);
        ftruncate(fileno(c), 0);
        outf(o, "# End of %s, Source %s begins",
                infile, inputfile);
    }


/* Open source */

    chdir(origdir);
    i = opensource(inputfile);  
    strcpy(infile, inputfile);
    strcpy(thefilename, infile);
    nline = 1;
   
    outf(o, "# %s begins", inputfile);

/* Let's do it */

    outline(o, thefilename, 1);
    process(i, c, o);

/* Done */

    outf(o, "# End %s", inputfile);
    
/* If we had XSUB code, we have to wait */
#ifdef __DEBUG__
    if (!runit)
#endif
    if (hasxs && !fatal) {
#ifndef __DEBUG__
        printf("Content-type: text/plain\n\n");
#endif
        printf("HTPL is now precompiling your C code.%s", NEWLINE);
        printf("This document will be avilable in a few minutes%s", NEWLINE, NEWLINE);
/* Make the XSUB code */
        linksubs(xs);
/* Add reference to module */
        nodir(inputfile, script);
        makecache(script, xs, "");
        outf(o, "use %s;", xs);
        fclose(o);
        fclose(i);
        exit(0);
    }

    fclose(i);
    fclose(c);

    chdir(scriptdir);
    strcpy(thefilename, "footer.hh");
    sprintf(infile, "Default include: %s", thefilename);
    i = fopen(thefilename, "r");
    if (i) {
        nline = 1;
        outf(o, "# Including: %s", infile);
        outline(o, thefilename, 1);
        process(i, c, o);
        fclose(i);
        outf(o, "# End of %s",
                infile);
    }
    chdir(origdir);


/* Add code for exit */

#ifdef __DEBUG__
    if (!noweb)
#endif
    outf(o, "exit(0);");
#ifdef __DEBUG__
    else outf(o, "1;");
#endif

/* Clean up */

    popbuffer();

    unlink(xs);

    fclose(o);

/* Display errors if croak() was called */
    if (fatal) {
#ifndef __DEBUG__
        printf("Content-type: text/plain\n\n");
#endif
        printf("Error while parsing: %s: %s%s", errloc, errstr, NEWLINE);
	free(errloc);
	free(errstr);
        dumpscopes();
        unlink(script);
        return;
    }

/* Update dependency database, if we use it */
#ifdef __DEBUG__
    if (!noout)
#endif
    fit(script, inputfile, 1);
}

/********************************************
 * Run a script                             *
 ********************************************/

void execute(script, postdata, headers, output, error)
    FILENAME script, postdata, headers, output, error; {

    COMMAND cmd;
    FILE *o, *i;
    int code;
    char *array[2];
    STR devnull = "/dev/null";
    FILE *myout;
    char c;
    char **newargv;
    int j;
    TOKEN key, val, skey, sval, total, line;

#ifdef __DEBUG__

    if (!runit && !create) {
/* We are neither in precompilation or exection mode, and not in CGI -
dump processed perl script to STDOUT */

        i = FOPEN(script, "r");
        fcpy(i, stdout, 0);
        fclose(i);
        unlink(script);
        return;
    }
    if (create) return;
    if (noweb) {
/* Run script from the shell */
        chdir(origdir);
        EXECPERL(myargc, myargv, NULL, NULL, NULL, 0);
        return;
    }

    if (inputcgi) {
/* Retrieve form pairs from the input, to debug pages on the shell */
        printf("Enter CGI pairs. EOF to continue%s", NEWLINE);
        total[0] = '\0';
        while (!feof(stdin)) {
            line[0] = '\0';
            fgets(line, sizeof(line), stdin);
            if (feof(stdin)) break;
            if (!line[0]) break;
            line[strlen(line) - 1] = '\0';
            if (!sscanf(line, "%[^=]%c%[^=]", key, &c, val)) break;
            htencode(key, skey);
            htencode(val, sval);
            if (total[0]) strcat(total, "&");
            strcat(total, skey);
            strcat(total, "=");
            strcat(total, sval);
        }
        SETENV("QUERY_STRING", total);
        SETENV("REQUEST_METHOD", "GET");
    } else {
/* We are not receiving input, make sure enivronment variables exist */

        if (!GETENV("QUERY_STRING")) SETENV("QUERY_STRING", "");
        if (!GETENV("REQUEST_METHOD")) SETENV("REQUEST_METHOD", "GET");
    }

#endif


/* Inform script where to write headers */

    SETENV("HTTP_HEADERS", headers);
    o = FOPEN(headers, "w");
    fprintf(o, "Content-type: text/html\n");
    fclose(o);

/* Change to script directory */

    chdir(scriptdir);

/* Run the script */

    code = EXECPERL(myargc, myargv, output, postdata, error, 1);

/* Recreate stdout. Needed because of weirdness in embedded perl */

    myout = fdopen(1, "w");

/* If script failed, dump debug information */
    if (code) {
#ifndef __DEBUG__
	fprintf(myout, "Status: 501 HTPL script returned errors\n");
        fprintf(myout, "Content-type: text/plain\n\n");
        fprintf(myout, "HTPL version %04.2f\n", (float)VERSION);
#endif
        fprintf(myout, "Perl script returned errors%s%s", NEWLINE, NEWLINE);
        fprintf(myout, "%sStderr follows:%s", NEWLINE, NEWLINE);
        if (i = fopen(error, "r")) {
            fcpy(i, myout, 0);
            fclose(i);
        }
        i = NULL;
/* Allow web masters to avoid code listing. Otherwise, list processed code
to allow matching of line numbers against error messages */
        if (debugforbidden(myout) || (i = fopen("htpl.nodbg", "r"))) {
            fprintf(myout, "%sDebug information omitted due to server set up.%s",
                  NEWLINE, NEWLINE);
            if (i) fclose(i);
        } else {
            fprintf(myout, "%sScript follows:%s", NEWLINE, NEWLINE);
            if (i = fopen(script, "r")) {
                flpt(i, myout);
                fclose(i);
            }
        }
        unlink(script);
        fprintf(myout, "%sOutput follows%s", NEWLINE, NEWLINE);
    }

/* Dump headers */

    i = FOPEN(headers, "r");
    fcpy(i, myout, 0);
    fclose(i);
    fprintf(myout, NEWLINE);

/* Dump the actual page */

    i = openoutput(output);
    fcpy(i, myout, 0);
    fclose(i);

    i = FOPEN(error, "r");
    fcpy(i, stderr, 0);
    fclose(i);
/* Clean up */

    fflush(myout);
    fclose(myout);

    if (strcmp(postdata, "/dev/null")) unlink(postdata);
    unlink(headers);
    unlink(output);
    unlink(error);
}

/****************************************
 * XSUB entry for ModPerl support       *
 ****************************************/

void xsub_entry(inp, outp, binary) 
    STR inp, binary, outp; {

    char *argv[5] = {binary, "-t", "-o", outp, inp};

    main(5, argv, NULL);
    exit;
}
