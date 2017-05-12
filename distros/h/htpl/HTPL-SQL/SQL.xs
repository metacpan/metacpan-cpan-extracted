#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif


MODULE = HTML::HTPL::SQL		PACKAGE = HTML::HTPL::SQL		


#define BUFF_SIZE 8192
#define QUOTE 1
#define INSIDE 2
#define BACK 4
#define THAT 8
#define ADDTOKEN token = newSVpv(str, dst - str); dst = str; av_push(result, token);
#define CONTROL "=<>,() "
#include <string.h>

AV *
tokenize_sql(sql)
char *sql
CODE:
    AV *result;
    char *ch, *dst;
    char str[BUFF_SIZE];
    int flag = 0;
    SV *token;


    result = newAV();

    ch = sql;
    dst = str;
    
    while (*ch) {
        if ((strchr(CONTROL, *ch)) && flag != QUOTE) {
            if (flag == THAT) {
                ADDTOKEN
                *dst++ = *ch++;
            }
            flag = 0;
        } else if (*ch == '\'') {
            switch(flag) {
                case QUOTE: flag = 0;
                            break;
                default:    flag = QUOTE;
            }
        } else if (*ch == '\\') flag = BACK;
        else  if (*ch == ':' && flag == 0) {
            flag = THAT;
            ADDTOKEN
        } else if (flag == 0) flag = INSIDE;
        *dst++ = *ch++;
    }

    ADDTOKEN

    RETVAL = result;

    OUTPUT:
    RETVAL
