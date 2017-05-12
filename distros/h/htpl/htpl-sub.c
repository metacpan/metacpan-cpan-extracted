/***************************************************************
 * HTPL by Ariel Brosh                                         *
 * This program can be used freely, but the source should not  *
 * be modified without notice.                                 *
 * Copyright 1997-1999 Ariel Brosh                             *
 ***************************************************************/

/**************************************
 * htpl-sub.c - The macro processor   *
 **************************************/

#include "htpl.h"
#include "htpl-sh.h"
#include <stdarg.h>

SCOPE searchback(STR);

/*************************************
 * Output a perl line with a macro   *
 **************************************/

void outperlline(o, code) 
    STR code;
    FILE *o; {

    pchar ch;
    int rcode;

    for (ch = code; isspace(*ch); ch++) ;

    if (*ch == '#') {
        ch++;
        if (*ch && *ch != ' ') {
            rcode = begin_parse_htpl(ch);    
            if (rcode) {
                outdbg(o, code);
                outmacro(o, result, 1);
                return;
             }
        }
    }

    fprintf(o, "%s%s", code, NEWLINE);
    rline++;
}

/** 
This is obsolette

void bloop(dest, token, ps)
    pchar dest;
    STR token, ps[]; {

    int flag1, flag2;
    int this = -1, that;
    int i;
    char delim;
    TOKEN cmp;
    pchar ch;
    pchar left;

    if (!strcmp(token, "id")) {
        if (!currscope) {
            *dest = '\0';
            return;
        }
        sprintf(cmp, "%d", scope_ids[currscope->scope]);
        strcpy(dest, cmp);
    }

    if (!strcmp(token, "key")) {
        if (!currscope) {
            *dest = '\0';
            return;
        }
        strcpy(dest, scope_names[currscope->scope]);
    }

    if (!sscanf(token, "%d", &this)) return;
    sprintf(cmp, "%d", this);
    left = token + strlen(cmp);

    flag1 = !strcmp(left, "*");
    flag2 = !strcmp(left, "!");

    if (flag1 || flag2) {
        dest[0] = '\0';
        if (flag2 && ps[this - 1]) strcat(dest, "$");
        strcat(dest, nprot(ps[this - 1]));
        while (ps[this++]) {
            if (flag2) strcat(dest, ",");
            strcat(dest, " ");
            if (flag2) strcat(dest, "$");
            strcat(dest, nprot(ps[this - 1]));
        }
        return;
    }

    if (!*left) {
        strcpy(dest, nprot(ps[this - 1]));
        return;
    }

    cmp[0] = '\0';
    if (sscanf(left + 1, "%d", &that)) {
        delim = *left;
        sprintf(cmp, "%d%c%d", this, delim, that);
    }
    if (!strcmp(cmp, token)) {
        ch = nprot(ps[this - 1]);
        for (i = 1; i < that; i++) {
            ch = strchr(ch, delim);
            if (!ch) return;
            ch++;
        }
        strcpy(dest, ch);
        ch = strchr(dest, delim);
        if (ch) *ch = '\0';
        return;
    }
    *dest = '\0';
}

** Obsolette

STR populate(str, params)
    STR str, params; {

    STR buff;
    int i = 0;
    pchar ch, dst;
    short pflag, iflag;
    TOKEN token;
    pchar tkn;
    STR ps[NUM_P];

    buff = malloc(BUFF_SIZE);

    ch = params;

    bzero(ps, sizeof(ps));
    while (*ch) eat(&ch, ps[i++] = malloc(512));
    ps[i] = NULL;

    ch = str;
    dst = buff;
    pflag = 0;
    iflag = 0;

    while (*ch) {
        if (*ch == '%') {
            if (iflag) {
                *tkn = '\0';
                bloop(dst, token, ps);
                while (*dst) dst++;
                iflag = 0;
                pflag = 0;
            } else {
                if (pflag) {
                    *dst++ = '%'; 
                    pflag = 0;
                    iflag = 0;
                } else pflag = 1;
            }
        } else {
            if (pflag) {
                iflag = 1;
                tkn = token;
                pflag = 0;
            }
            if (!iflag) *dst++ = *ch; else *tkn++ = *ch;
        }
        ch++;
    }
    *dst = '\0';

    for (i = 0; ps[i]; i++) if (ps[i]) free(ps[i]);

    return buff;
}

*/

/**********************************
 * Expand an <HT> macro           *
 **********************************/

int copyhtmltag(tag) 
    STR tag; {

    int code = 0;
    pchar src, ch;
    STR buff;
    long l;

    int untag = 0;

    if (tag[1] == '/') {
        untag = 1;
        tag++;
    }

    if (toupper(tag[1]) == 'H' && toupper(tag[2]) == 'T') {
        buff = malloc(BUFF_SIZE);
        htmldecode(tag + 3, buff);
        buff[strlen(buff) - 1] = '\0';
        *result = '\0';
        nest = 0;
        currbuffer->lines = 0;
        persist = NULL;
        code = parse_htpl(buff, untag);
        free(buff);
    }

    return code;
}

/**
This is obsolette
    
int count_args(buff)
    STR buff; {
    pchar ptr;
    TOKEN temp;
    int result = 0;

    for (ptr = buff; *ptr; ++result) eat(&ptr, temp);
    return result;
}
*/

/********************************************
 * Push a scope                             *
 ********************************************/

void pushscope(scope, dont)
    int scope, dont; {
    currscope = malloc(sizeof(struct scope_el));
    currscope->scope = scope;
    currscope->nline = nline;
    currscope->vars = NULL;
    if (!dont) currscope->id = scope_ids[scope]++;
    ppush(&scopestack, currscope);
    scopelevel++;
}

/*****************************
 * Pop a scope               *
 *****************************/

void popscope() {
    struct scope_el *old;
    btreekill(&currscope->vars);
    currscope = ppop(&scopestack);
    scopelevel--;
}

/******************************
 * Push a buffer to the stack *
 *******************************/

void pushbuffer() {
    BUFFER el = malloc(sizeof(struct buffer_el));
    el->size = resultsize = BUFF_SIZE;
    el->buffer = result = malloc(el->size);
    ppush(&bufferstack, el);
    currbuffer = el;
}

/*******************************
 * Pop a buffer from the stack *
 *******************************/

void popbuffer() {
    struct buffer_el *el = ppop(&bufferstack);
    currbuffer = el;
    free(result);
    if (!el) return;
    result = el->buffer;
    resultsize = el->size;
}

/***************************************************
 * Check a string for content and delete from heap *
 ***************************************************/

int disposetrue(buff)
    pchar buff; {

    int code = *buff;
    free(buff);
    return code;
}

/********************************************
 * Compare two strings and delete from heap *
 ********************************************/

int disposecmp(buff1, buff2)
    pchar buff1, buff2; {

    int code = strcmp(buff1, buff2);
    free(buff1);
    free(buff2);
    return code;
}

/********************************************
 * Compare two strings and delete from heap *
 ********************************************/

int disposeicmp(buff1, buff2)
    pchar buff1, buff2; {

    int code = strcasecmp(buff1, buff2);
    free(buff1);
    free(buff2);
    return code;
}


/*********************************************
 * Parse the current macro                   *
 *********************************************/

void makepersist(buff) 
    STR buff; {
    pchar ch;
    STR* ptr;
    TOKEN token;
    int n = 0;

    if (persist) n = persist->n;
    NEW(persist)
    NEW(persist->extras)
    NEW(persist->tokens)
    vectorinit(persist->extras);
    vectorinit(persist->tokens);

    persist->n = n + 1;

    ch = buff;
    while (*ch) {
        eat(&ch, token);
        if (!token[0]) break;
        vectorpush(persist->tokens, (PTR)strdup(token));
    }
    ppush(&persiststack, persist);
}

static const STR BLANK = "";

/********************************************
 * Get a numbered token                     *
 ********************************************/

STR gettoken(which) 
    int which; {
    int prepend = 0;
    STR buff, result;
    pchar ptr1, ptr2;
    short flag = 0;

    if (which < 0) {
        which = -which;
        prepend = 1;
    }
    if (which > persist->tokens->num || which < 1) return BLANK;
    result = persist->tokens->data[which - 1];
    if (!prepend && !kludge_reunifying) return result;
    buff = malloc(strlen(result) * 2);
    ptr1 = result;
    ptr2 = buff;
    for (; *ptr1; *ptr2++ = *ptr1++) {
	if (!kludge_reunifying)
            if (*ptr1 == '"' || *ptr1 == '\'' || *ptr1 == '\\'
                || *ptr1 == '$' || *ptr1 == '%' || *ptr1 == '@') *ptr2++ = '\\';
        if (isspace(*ptr1)) flag = 1;
    }
    *ptr2 = '\0';
    if ((!flag || !kludge_reunifying) && ptr1 - result == ptr2 - buff) {
	free(buff);
	return result;
    }
    if (kludge_reunifying && flag) {
	memmove(buff + 2, buff, ptr1 - result);
	buff[0] = buff[1] = '<';
	buff[ptr1 - result + 2] = buff[ptr1 - result + 3] = '>';
	buff[ptr1 - result + 4] = '\0';
    }
    result = setworktoken(buff);
    free(buff);
    return result;
}

STR repeat(times, what)
    int times;
    char what; {

    STR result;	    
    STR buff = malloc(times + 1);
    memset(buff, what, times);
    buff[times] = '\0';
    result = setworktoken(buff);
    free(buff);
    return result;
}

/**************************************************
 * Get a unique identifier for the current scope  *
 **************************************************/

STR getblockid(scope)
    STR scope; {
    char result[6];
    SCOPE srch;
    if (*scope) srch = searchback(scope); else srch = currscope;
    if (!srch) {
        return BLANK;
    }
    sprintf(result, "%d", srch->id);
    return setworktoken(result);
}

/**************************************
 * Get current scope name             *
 **************************************/

STR getkey() {
    if (!currscope) {
        return BLANK;
    }
    return scope_names[currscope->scope];
}

/***************************************
 * Split a token                       *
 ***************************************/

STR getsubtoken(which, how, where)
    int which, where;
    char how; {

    pchar token = gettoken(which);
    STR result;
    int i;
    for (i = 1; i < where; i++) {
        token  = strchr(token, how);
        if (!token) break; 
        token++;
    }
    result = setworktoken(nprot(token));
    token = strchr(result, how);
    if (token) *token = '\0';
    return result;
}

STR convertmask(mask)
    STR mask; {

    pchar ch;
    mask = setworktoken(mask);
    for (ch = mask; *ch; ch++) if (*ch == '$') *ch = '%';    
    return mask;
}

/*******************
 * Join tokens     *
 *******************/

STR workf(STR, ...);

STR gettokenlist(which, delim, before, mask)
    STR delim;
    STR before;
    STR mask;
    int which; {
    
    int l = 100, ln = 0, ln2;
    STR s = malloc(l);
    STR t;
    int lnb4 = strlen(before);
    int lndlm = strlen(delim);
    int flag = 1;

    if (mask) {
	if (*mask) mask = convertmask(mask);
	else mask = NULL;
    }	   
    if (which < 0) {
        flag = -1;
        which = -which;
    }

    s[0] = '\0';

    while (which <= persist->tokens->num) {
        t = gettoken(flag * which++);
	if (mask) {t = workf(mask, t);}
        ln2  = strlen(t);
        if (ln2 + ln + lndlm + lnb4 + 4 > l - 1) {
            l = (ln2 + ln + lndlm + lnb4) * 2;
            s = realloc(s, l);
        }
        if (ln > 0) {
            strcpy(&s[ln], delim);
            ln += lndlm;
        }
        strcpy(&s[ln], before);
        ln += lnb4;
        strcpy(&s[ln], t);
        ln += ln2;
    }
    t = setworktoken(s);
    free(s);
    return t;
}

/****************************************************
 * Allocate a string for later garbage collection   *
 ****************************************************/

STR setworktoken(src)
    STR src; {

    STR copy = strdup(src);
    vectorpush(persist->extras, (PTR)copy);
    return copy;
}

/*******************************************
 * Clean up after a macro function         *
 *******************************************/

void destroypersist() {
    vectorkill(persist->tokens);
    free(persist->tokens);
    vectorkill(persist->extras);
    free(persist->extras);
    persist = ppop(&persiststack);
}

/*******************************************
 * Grabage collect and exit macro function *
 *******************************************/

int retval(val)
    int val; {
    destroypersist();
    return val;
}

/*******************************************
 * Format output to buffer                 *
 *******************************************/

void printfcode(char *fmt, ...) {
    va_list ap;
    char *msg;

    va_start(ap, fmt);
    vasprintf(&msg, fmt, ap);
    va_end(ap);
    
    printcode(msg);
    free(msg);
}

/***************************
 * Format pooled output    *
 ***************************/

STR workf(STR fmt, ...) {
    va_list ap;
    STR msg;
    STR ret;

    va_start(ap, fmt);
    vasprintf(&msg, fmt, ap);
    va_end(ap);
   
    ret = setworktoken(msg);
    free(msg);
    return ret;
}

/*********************************************
 * Add code to the buffer                    *
 *********************************************/

void printcode(buff)
    STR buff; {
    if (strlen(result) + strlen(buff) + 2 > resultsize - 1) {
        resultsize += 1024;
        result = realloc(result, resultsize);
        currbuffer->size = resultsize;
        currbuffer->buffer = result;
    }
    strcat(result, buff);
    currbuffer->lines += countlines(buff);
}

void outmacro(o, buffer, offset)
    FILE *o;
    int offset;
    STR buffer; {
    outline(o, thescript, rline + 1 + 1);
    outblock(o, buffer);
    outline(o, thefilename, nline + offset);
}

int begin_parse_htpl(buff) 
    STR buff; {
    *result = '\0';
    nest = 0;
    persist = NULL;
    currbuffer->lines = 0;
    return parse_htpl(buff, 0);
}

SCOPE searchback(name)
    STR name; {

    LINK_EL top = scopestack;

    if (!*name) return &mainscope;
    while (top) {
        SCOPE data = top->data;
        if (!strcasecmp(scope_names[data->scope], name)) return data;
        top = top->next;
    }
    return NULL;
}

SCOPE thisscope() {
    return currscope ? currscope : &mainscope;
}

void setvar(name, value)
    STR name, value; {
    SCOPE this;
    this = thisscope();
    btreeadd(&this->vars, name, (PTR)value);
}

void unsetvar(name)
    STR name; {
    SCOPE this = thisscope();
    PTR data = btreedelkey(&this->vars, name);
    if (data) free(data);
}

STR getvar(name)
    STR name; {
    SCOPE this = thisscope();
    return setworktoken(nprot((STR)btreesearch(this->vars, name)));
}

int importvar(name, scope)
    STR name, scope; {
    SCOPE srch = searchback(scope);
    STR value;
    if (!srch) return 0;
    value = nprot((STR)btreesearch(srch->vars, name));
    setvar(name, strdup(value));
    return 1;
}

int exportvar(name, scope)
    STR name, scope; {
    STR value = getvar(name);
    PTR old;
    SCOPE srch = searchback(scope);
    if (!srch) return 0;
/*    old = btreesearch(srch->vars, name);
    if (old) free(old);*/
    /* Do NOT release memory here, btreeadd does it */
    btreeadd(&srch->vars, name, strdup(value));
    return 1;
}
