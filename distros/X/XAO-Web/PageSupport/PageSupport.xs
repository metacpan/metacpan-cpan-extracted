/* This is very specific module oriented to support fast text adding
 * for XAO displaying engine. Helps a lot with template processing,
 * especially when template splits into thousands or even millions of
 * pieces.
 *
 * The idea is to have one long buffer that extends automatically and a
 * stack of positions in it that can be pushed/popped when application
 * need new portion of text.
 *
 * Andrew Maltsev, <am@xao.com>, 2000, 2002
*/
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <string.h>
#include <ctype.h>

/* Workaround for older versions of perl that do not define these macros
*/
#ifndef pTHX_
#define pTHX_
#endif
#ifndef aTHX_
#define aTHX_
#endif

/************************************************************************/

#define MAX_STACK   200
#define CHUNK_SIZE  1000

static char *buffer=NULL;
static STRLEN bufsize=0;
static STRLEN bufpos=0;
static STRLEN pstack[MAX_STACK];
static unsigned stacktop=0;

/************************************************************************/

/* Allows letters, digits, underscore and dot
*/
static int
isalnum_dot(int c) {
    return isalnum(c) || c=='.' || c=='_';
}

/* Parsing template into an array suitable for Web::Page
*/
static SV*
parse_text(pTHX_ char * template, STRLEN length, short is_unicode) {
    AV* parsed=newAV();

    char *str=template;
    char *text_ptr=template;
    char *end=template+length;

    if(!length) {
        return newRV_noinc((SV*)parsed);
    }

    while(str<end) {
        char var_flag;
        HV* hv;
        SV* sv;

        /* Simple parser with basically just two states -- text and
         * object, instead of tracking states we just have two separate
         * loops for each one.
         *
         * First is text.
        */
        while(1) {
            if(*str=='<' && str+1<end && (str[1]=='%' || str[1]=='$')) {
                if(str+3<end && str[2]==str[1] && str[3]=='>') {
                    /* A way to embed '<%' or '<$' -- <%%> or <$$> */
                    hv=newHV();
                    sv=newSVpvn(text_ptr,str+2-text_ptr);
                    if(is_unicode) SvUTF8_on(sv);
                    hv_store(hv,"text",4,sv,0);
                    av_push(parsed,newRV_noinc((SV*)hv));

                    str+=4;
                    text_ptr=str;
                }
                else {
                    if(text_ptr!=str) {
                        hv=newHV();
                        sv=newSVpvn(text_ptr,str-text_ptr);
                        if(is_unicode) SvUTF8_on(sv);
                        hv_store(hv,"text",4,sv,0);
                        av_push(parsed,newRV_noinc((SV*)hv));
                    }
                    break;
                }
            }
            else if(*str=='<' && str+4<end && str[1]=='!' && str[2]=='-' && str[3]=='-' && str[4]!='/' && str[4]!='[' && str[4]!='>' && str[4]!='<') {
                if(text_ptr!=str) {
                    hv=newHV();
                    sv=newSVpvn(text_ptr,str-text_ptr);
                    if(is_unicode) SvUTF8_on(sv);
                    hv_store(hv,"text",4,sv,0);
                    av_push(parsed,newRV_noinc((SV*)hv));
                }

                str+=4;
                while(str+2<end && (*str!='-' || str[1]!='-' || str[2]!='>')) str++;
                if(str+2>=end) {
                    av_clear(parsed);
                    return newSVpvf("Unclosed comment at position %ld (%*s)",
                                    str-template,
                                    (int)(end-str>10 ? 10 : end-str),str);
                }

                str+=3;
                text_ptr=str;
            }
            else {
                str++;
                if(str>=end) {
                    if(text_ptr!=str) {
                        hv=newHV();
                        sv=newSVpvn(text_ptr,str-text_ptr);
                        if(is_unicode) SvUTF8_on(sv);
                        hv_store(hv,"text",4,sv,0);
                        av_push(parsed,newRV_noinc((SV*)hv));
                        str+=2;
                    }
                    break;
                }
            }
        }

        /* Bailing out if we're at the end
        */
        if(str>=end)
            break;

        /* And now we're in the object or variable. Getting its name.
        */
        var_flag=str[1] == '$' ? 1 : 0;
        str+=2;
        while(str<end && isspace(*str)) str++;
        text_ptr=str;
        while(str<end && (isalnum_dot(*str) || *str==':')) str++;

        /* End object is a special case, we stop parsing if we meet it
         * and do not even look what's behind it. That helps if there
         * are some elements with broken syntax after the <%End%> that the
         * developer intended to ignore.
        */
        if(!var_flag && str-text_ptr==3 && !strncmp(text_ptr,"End",3)) {
            return newRV_noinc((SV*)parsed);
        }

        /* Storing the name
        */
        hv=newHV();
        hv_store(hv,var_flag ? "varname" : "objname",7,
                    newSVpvn(text_ptr,str-text_ptr),0);
        while(str<end && isspace(*str)) str++;

        /* Flag after the name if present -- <%VAR/f%>
        */
        if(*str=='/') {
            text_ptr=++str;
            while(str<end && isalnum(*str)) str++;
            hv_store(hv,"flag",4,newSVpvn(text_ptr,1),0);
            while(str<end && isspace(*str)) str++;
        }

        /* And finally, if that's a variable we're looking for the
         * closing bracket, if that's an object -- we're scanning its
         * arguments.
        */
        if(var_flag) {
            if(*str=='$' && str+1<end && str[1]=='>') {
                str+=2;
                text_ptr=str;
                av_push(parsed,newRV_noinc((SV*)hv));
                continue;
            }
            else {
                av_clear(parsed);
                return newSVpvf("Variable is not closed in template, pos=%ld (%*s)",
                                str-template,
                                (int)(end-str>10 ? 10 : end-str),str);
            }
        }
        else {
            HV* args=newHV();

            while(1) {
                char * name_end;

                if(*str=='%' && str+1<end && str[1]=='>') {
                    str+=2;
                    text_ptr=str;
                    break;
                }

                /* Argument name
                */
                text_ptr=str;
                while(str<end && isalnum_dot(*str)) str++;

                if(str==text_ptr) {
                    av_clear(parsed);
                    return newSVpvf("Wrong argument name, pos=%ld (%*s)",
                                    str-template,
                                    (int)(end-str>10 ? 10 : end-str),str);
                }

                /* Empty argument value gets replaced with 'on' text for
                 * compatibility
                */
                name_end=str;
                if(str==end || *str!='=') {
                    AV* tav=newAV();
                    HV* thv=newHV();
                    hv_store(thv,"text",4,newSVpvn("on",2),0);
                    av_push(tav,newRV_noinc((SV*)thv));
                    hv_store(args,text_ptr,name_end-text_ptr,
                                  newRV_noinc((SV*)tav),0);
                }

                /* We get here only when there is '=' sign in the str
                 * position and therefore we expect an argument.
                */
                else {
                    char * val_start;
                    char * val_end;
                    char literal;

                    str++;
                    while(str<end && isspace(*str)) str++;

                    if(str==end) {
                        av_clear(parsed);
                        return newSVpvf("Unclosed object in template, pos=%ld (..%*s)",
                                        str-template,
                                        (int)(length>10 ? 10 : length),
                                        length>10 ? end-10 : template);
                    }
                    else if(*str=='"') {
                        val_start=++str;
                        while(str<end && *str!='"') str++;
                        if(str==end) {
                            av_clear(parsed);
                            return newSVpvf("Unmatched \" in the argument, pos=%ld (%*s)",
                                            val_start-template,
                                            (int)(end-val_start>10 ? 10 : end-val_start),val_start);
                        }
                        val_end=str++;
                        literal=0;
                    }
                    else if(*str=='\'') {
                        val_start=++str;
                        while(str<end && *str!='\'') str++;
                        if(str==end) {
                            av_clear(parsed);
                            return newSVpvf("Unmatched ' in the argument, pos=%ld (%*s)",
                                            val_start-template,
                                            (int)(end-val_start>10 ? 10 : end-val_start),val_start);
                        }
                        val_end=str++;
                        literal=1;
                    }
                    else if(*str=='{' && str+1<end && str[1]=='\'') {
                        unsigned count=0;
                        str+=2;
                        val_start=str;
                        while(str<end && (count || *str!='\'' || str+1>=end || str[1]!='}')) {
                            if(*str=='{' && str+1<end && str[1]=='\'') {
                                count++;
                                str+=2;
                            }
                            else if(*str=='\'' && str+1<end && str[1]=='}') {
                                count--;
                                str+=2;
                            }
                            else {
                                str++;
                            }
                        }
                        if(str==end) {
                            av_clear(parsed);
                            return newSVpvf("Unmatched {' in the argument, pos=%ld (%*s)",
                                            val_start-template,
                                            (int)(end-val_start>10 ? 10 : end-val_start),val_start);
                        }
                        val_end=str;
                        str+=2;
                        literal=1;
                    }
                    else if(*str=='{') {
                        unsigned count=0;
                        val_start=++str;
                        while(str<end && (count || *str!='}')) {
                            if(*str=='{') {
                                count++;
                            }
                            else if(*str=='}') {
                                count--;
                            }
                            str++;
                        }
                        if(str==end) {
                            av_clear(parsed);
                            return newSVpvf("Unmatched { in the argument, pos=%ld (%*s)",
                                            val_start-template,
                                            (int)(end-val_start>10 ? 10 : end-val_start),val_start);
                        }
                        val_end=str++;
                        literal=0;
                    }
                    else {
                        /* We have to count <%%> to be compatible with older
                         * code -- there are cases where there are no
                         * quotes for both simple things like '<%A b=4%>' and
                         * references like '<%A b=<%C/f%>%>'.
                         *
                         * There is no similar provision for <$A$> to
                         * discourage from using unquoted values.
                        */
                        unsigned count=0;
                        val_start=str;
                        while(str<end && (count || !isspace(*str))) {
                            if(str+1<end) {
                                if(*str=='<' && str[1]=='%') {
                                    count++;
                                    str++;
                                }
                                else if(*str=='%' && str[1]=='>') {
                                    if(!count) break;
                                    count--;
                                    str++;
                                }
                            }
                            str++;
                        }
                        val_end=str;
                        literal=0;
                    }

                    if(literal) {
                        sv=newSVpvn(val_start,val_end-val_start);
                        if(is_unicode) SvUTF8_on(sv);
                        hv_store(args,
                                 text_ptr,name_end-text_ptr,
                                 sv,
                                 0);
                    }
                    else {
                        SV* val=parse_text(aTHX_ val_start,val_end-val_start,is_unicode);
                        if(SvROK(val)) {
                            hv_store(args,text_ptr,name_end-text_ptr,
                                          val,0);
                        }
                        else {
                            av_clear(parsed);
                            return val;
                        }
                    }
                }

                while(str<end && isspace(*str)) str++;
            }

            hv_store(hv,"args",4,newRV_noinc((SV*)args),0);
            av_push(parsed,newRV_noinc((SV*)hv));
        }
    }

    return newRV_noinc((SV*)parsed);
}

/************************************************************************/

MODULE = XAO::PageSupport       PACKAGE = XAO::PageSupport

###############################################################################

unsigned
level()
    CODE:
        RETVAL=stacktop;
    OUTPUT:
        RETVAL


void
reset()
    CODE:
        bufpos=pstack[stacktop=0]=0;


void
push()
    CODE:
        if(stacktop+1>=MAX_STACK) {
            fprintf(stderr,"XAO::PageSupport - maximum stack deep reached!\n");
            return;
        }
        pstack[stacktop++]=bufpos;


SV *
pop(is_unicode)
        short is_unicode;
    CODE:
        char *text;
        STRLEN len;

        if(!buffer) {
            text="";
            len=0;
        }
        else {
            len=bufpos;
            if(stacktop) {
                bufpos=pstack[--stacktop];
                len-=bufpos;
            } else {
                bufpos=0;
            }
            text=buffer+bufpos;
        }
        RETVAL=newSVpvn(text,len);
        if(is_unicode)
            SvUTF8_on(RETVAL);
    OUTPUT:
        RETVAL


unsigned long
bookmark()
    CODE:
        RETVAL=bufpos;
    OUTPUT:
        RETVAL


SV *
peek(len, is_unicode)
        unsigned long len;
        short is_unicode;
    CODE:
        if(!buffer || len>bufpos) {
            RETVAL=newSVpvn("",0);
        }
        else {
            RETVAL=newSVpvn(buffer+len,bufpos-len);
        }
        if(is_unicode)
            SvUTF8_on(RETVAL);
    OUTPUT:
        RETVAL


void
addtext(text)
        STRLEN len=0;
        char * text=SvPV(ST(0),len);
    CODE:
        if(text && len) {
            if(bufpos+len >= bufsize) {
                buffer=realloc(buffer,sizeof(*buffer)*(bufsize+=len+CHUNK_SIZE));
                if(! buffer) {
                    fprintf(stderr,
                            "XAO::PageSupport - out of memory, length=%lu, bufsize=%lu, bufpos=%lu\n",
                            (unsigned long)len,(unsigned long)bufsize,(unsigned long)bufpos);
                    return;
                }
            }
            memcpy(buffer+bufpos,text,len);
            bufpos+=len;
        }


SV *
parse(template,is_unicode)
        STRLEN length=0;
        char *template=SvPV(ST(0),length);
        short is_unicode;
    CODE:
        RETVAL=parse_text(aTHX_ template, length, is_unicode);
    OUTPUT:
        RETVAL
