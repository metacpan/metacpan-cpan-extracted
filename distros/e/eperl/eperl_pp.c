/*
**        ____           _ 
**    ___|  _ \ ___ _ __| |
**   / _ \ |_) / _ \ '__| |
**  |  __/  __/  __/ |  | |
**   \___|_|   \___|_|  |_|
** 
**  ePerl -- Embedded Perl 5 Language
**
**  ePerl interprets an ASCII file bristled with Perl 5 program statements
**  by evaluating the Perl 5 code while passing through the plain ASCII
**  data. It can operate both as a standard Unix filter for general file
**  generation tasks and as a powerful Webserver scripting language for
**  dynamic HTML page programming. 
**
**  ======================================================================
**
**  Copyright (c) 1996,1997,1998 Ralf S. Engelschall <rse@engelschall.com>
**
**  This program is free software; it may be redistributed and/or modified
**  only under the terms of either the Artistic License or the GNU General
**  Public License, which may be found in the ePerl source distribution.
**  Look at the files ARTISTIC and COPYING or run ``eperl -l'' to receive
**  a built-in copy of both license files.
**
**  This program is distributed in the hope that it will be useful, but
**  WITHOUT ANY WARRANTY; without even the implied warranty of
**  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
**  Artistic License or the GNU General Public License for more details.
**
**  ======================================================================
**
**  eperl_pp.c -- ePerl preprocessor
*/

#include "eperl_config.h"
#include "eperl_global.h"
#include "eperl_proto.h"

static char ePerl_PP_ErrorString[1024] = "";

/*
**  set PP error string
*/
void ePerl_PP_SetError(char *str, ...)
{
    va_list ap;

    va_start(ap, str);
    vsprintf(ePerl_PP_ErrorString, str, ap);
    va_end(ap);
    return;
}

/*
**  get PP error string
*/
char *ePerl_PP_GetError(void)
{
    return ePerl_PP_ErrorString;
}

/*
**  expand #include directives in buffer
*/
char *ePerl_PP_Process(char *cpInput, char **cppINC, int mode)
{
    char *cpOutBuf = NULL;
    char *cpEND;
    char *cps;
    char *cp;
    char *cp2;
    char *cp3;
    char *cp4;
    char *cpT = NULL;
    char *cpInBuf = NULL;
    char *cpBuf;
    char caName[1024];
    char caArg[1024];
    char caStr[1024];
    int n;
    int l1;
    int l2;
    int nBuf;
    int nOut;
    int nOutBuf;
    int i;
    FILE *fp;

    if (strlen(cpInput) == 0) {
        /* make sure we return a buffer which the caller can free() */
        cpOutBuf = (char *)malloc(sizeof(char) * 1);
        *cpOutBuf = NUL;
        return cpOutBuf;
    }

    if (mode == 1) {
        /* treat input as buffer */
        cpBuf = cpInput;
        nBuf = strlen(cpBuf);
    }
    else {
        /* treat input as filename */

        if (strncmp(cpInput, "http://", 7) == 0) {
            fp = HTTP_openURLasFP(cpInput);
        }
        else if (*cpInput == '/') {
            fp = fopen(cpInput, "r");
        }
        else {
            fp = fopen(cpInput, "r");
            if (fp == NULL) {
                /* we have to try in all include directories! */
                for (i = 0; cppINC[i] != NULL; i++) {
                    sprintf(caName, "%s/%s", cppINC[i], cpInput);
                    if ((fp = fopen(caName, "r")) != NULL)
                        break;
                }
            }
        }
        if (fp == NULL) {
            ePerl_PP_SetError("Cannot open source file `%s' for reading", cpInput);
            return NULL;
        }
        nBuf = 16384;
        if ((cpInBuf = (char *)malloc(sizeof(char) * nBuf)) == NULL) {
            ePerl_PP_SetError("Cannot allocate %d bytes of memory", nBuf);
            return NULL;
        }
        i = 0;
        while ((n = fread(cpInBuf+i, 1, 16384, fp)) > 0) {
            i += n;
            if (n < 16384 && feof(fp))
                break;
            else {
                nBuf += 16384;
                if ((cpInBuf = (char *)realloc(cpInBuf, nBuf)) == NULL) {
                    ePerl_PP_SetError("Cannot reallocate %d bytes of memory", nBuf);
                    return NULL;
                }
                continue;
            }
        }
        cpInBuf[i] = '\0';
        cpBuf = cpInBuf;
        nBuf = i;
        fclose(fp);
    }

    cpEND = cpBuf+nBuf;
    cps = cpBuf;
    nOutBuf = 64;
    cpOutBuf = (char *)malloc(64);
    nOut = 0;

    while (cps < cpEND) {
        /*
         *   search for any more directives
         */
        cp = NULL;
        if (cps == cpBuf || ((cps > cpBuf) && (*(cps-1) == '\n'))) {
            if ((strncmp(cps, "#include",  8) == 0) && (cp == NULL)) cp = cps;
            if ((strncmp(cps, "#sinclude", 9) == 0) && (cp == NULL)) cp = cps;
            if ((strncmp(cps, "#if",       3) == 0) && (cp == NULL)) cp = cps;
            if ((strncmp(cps, "#elsif",    6) == 0) && (cp == NULL)) cp = cps;
            if ((strncmp(cps, "#else",     5) == 0) && (cp == NULL)) cp = cps;
            if ((strncmp(cps, "#endif",    6) == 0) && (cp == NULL)) cp = cps;
            if ((strncmp(cps, "#c",        2) == 0) && (cp == NULL)) cp = cps;
        }
        if (((cpT = strnstr(cps, "\n#include",  cpEND-cps)) != NULL) && ((cpT < cp) || (cp == NULL))) cp = cpT+1;
        if (((cpT = strnstr(cps, "\n#sinclude", cpEND-cps)) != NULL) && ((cpT < cp) || (cp == NULL))) cp = cpT+1;
        if (((cpT = strnstr(cps, "\n#if",       cpEND-cps)) != NULL) && ((cpT < cp) || (cp == NULL))) cp = cpT+1;
        if (((cpT = strnstr(cps, "\n#elsif",    cpEND-cps)) != NULL) && ((cpT < cp) || (cp == NULL))) cp = cpT+1;
        if (((cpT = strnstr(cps, "\n#else",     cpEND-cps)) != NULL) && ((cpT < cp) || (cp == NULL))) cp = cpT+1;
        if (((cpT = strnstr(cps, "\n#endif",    cpEND-cps)) != NULL) && ((cpT < cp) || (cp == NULL))) cp = cpT+1;
        if (((cpT = strnstr(cps, "\n#c",        cpEND-cps)) != NULL) && ((cpT < cp) || (cp == NULL))) cp = cpT+1;

        if (cp != NULL && (cp == cpBuf || (cp > cpBuf && *(cp-1) == '\n'))) {
            /* 
             *  Ok, one more directive found...
             */

            /* allocate space and add data up to directive */
            i = cp-cps;
            nOutBuf += i;
            if ((cp2 = (char *)realloc(cpOutBuf, nOutBuf)) == NULL) {
                ePerl_PP_SetError("Failed on realloc(buf, %d)", nOutBuf);
                free(cpOutBuf);
                return NULL;
            }
            cpOutBuf = cp2;
            strncpy(cpOutBuf+nOut, cps, cp-cps);
            nOut += i;

            /* 
             *  now process the specific directives...
             */
            if (strncmp(cp, "#include", 8) == 0) {
                /* 
                 *  found a #include directive
                 */
                cps = cp+8;
            
                /* skip whitespaces */
                for ( ; cps < cpEND && (*cps == ' ' || *cps == '\t'); cps++)
                    ;
                /* skip possible quotation mark or opening angle bracket */
                if (*cps == '"' || *cps == '<')
                    cps++;

                /* check for EOL */
                if (*cps == '\n') {
                    ePerl_PP_SetError("Missing filename or URL for #include directive");
                    free(cpOutBuf);
                    return NULL;
                }

                /* copy the filename and skip to end of line */
                for (i = 0; cps < cpEND && 
                            (*cps != ' ' && *cps != '\t' && 
                             *cps != '>' && *cps != '"'  &&
                             *cps != '\n'                  );  )
                    caName[i++] = *cps++;
                caName[i++] = NUL;
                for ( ; cps < cpEND && *cps != '\n'; cps++)
                    ;
                if (*cps == '\n')
                    cps++;
    
                /* recursive usage */
                if ((cp = ePerl_PP_Process(caName, cppINC, 0 /*mode=file*/)) == NULL)
                    return NULL;
            }
            else if (strncmp(cp, "#sinclude", 9) == 0) {
                /* 
                 *  found a #sinclude directive
                 */
                cps = cp+9;
            
                /* skip whitespaces */
                for ( ; cps < cpEND && (*cps == ' ' || *cps == '\t'); cps++)
                    ;
                /* skip possible quotation mark or opening angle bracket */
                if (*cps == '"' || *cps == '<')
                    cps++;

                /* check for EOL */
                if (*cps == '\n') {
                    ePerl_PP_SetError("Missing filename or URL for #sinclude directive");
                    free(cpOutBuf);
                    return NULL;
                }

                /* copy the filename and skip to end of line */
                for (i = 0; cps < cpEND && 
                            (*cps != ' ' && *cps != '\t' && 
                             *cps != '>' && *cps != '"'  &&
                             *cps != '\n'                  );  )
                    caName[i++] = *cps++;
                caName[i++] = NUL;
                for ( ; cps < cpEND && *cps != '\n'; cps++)
                    ;
                if (*cps == '\n')
                    cps++;
    
                /* recursive usage */
                if ((cp = ePerl_PP_Process(caName, cppINC, 0 /*mode=file*/)) == NULL)
                    return NULL;

                /* make it secure by removing all begin/end delimiters!! */
                if ((cp2 = (char *)malloc(strlen(cp))) == NULL)
                    return NULL;
                l1 = strlen(ePerl_begin_delimiter);
                l2 = strlen(ePerl_end_delimiter);
                for (cp3 = cp, cp4 = cp2; *cp3 != NUL; ) {
                    if (strncasecmp(cp3, ePerl_begin_delimiter, l1) == 0)
                        cp3 += l1;
                    else if (strncasecmp(cp3, ePerl_end_delimiter, l2) == 0)
                        cp3 += l2;
                    else
                        *cp4++ = *cp3++;
                }
                *cp4 = NUL;
                free(cp);
                cp = cp2;
            }
            else if (strncmp(cp, "#if", 3) == 0) {
                /* 
                 *  found a #if directive
                 */
                cps = cp+3;

                /* skip whitespaces */
                for ( ; cps < cpEND && (*cps == ' ' || *cps == '\t'); cps++)
                    ;
                if (*cps == '\n') {
                    ePerl_PP_SetError("Missing expression for #if directive");
                    free(cpOutBuf);
                    return NULL;
                }

                /* copy the argument and create replacement string */
                for (i = 0; cps < cpEND && *cps != '\n'; )
                    caArg[i++] = *cps++;
                caArg[i++] = NUL;
                if (*cps == '\n')
                    cps++;
                sprintf(caStr, "%s if (%s) { _%s//\n", 
                        ePerl_begin_delimiter, caArg, ePerl_end_delimiter);
                cp = caStr;
            }
            else if (strncmp(cp, "#elsif", 6) == 0) {
                /* 
                 *  found a #elsif directive
                 */
                cps = cp+6;

                /* skip whitespaces */
                for ( ; cps < cpEND && (*cps == ' ' || *cps == '\t'); cps++)
                    ;
                if (*cps == '\n') {
                    ePerl_PP_SetError("Missing expression for #elsif directive");
                    free(cpOutBuf);
                    return NULL;
                }

                /* copy the argument and create replacement string */
                for (i = 0; cps < cpEND && *cps != '\n'; )
                    caArg[i++] = *cps++;
                caArg[i++] = NUL;
                if (*cps == '\n')
                    cps++;
                sprintf(caStr, "%s } elsif (%s) { _%s//\n", 
                        ePerl_begin_delimiter, caArg, ePerl_end_delimiter);
                cp = caStr;
            }
            else if (strncmp(cp, "#else", 5) == 0) {
                /* 
                 *  found a #else directive
                 */
                cps = cp+5;

                /* skip to end of line */
                for (i = 0; cps < cpEND && *cps != '\n'; cps++)
                    ;
                if (*cps == '\n')
                    cps++;

                /* create replacement string */
                sprintf(caStr, "%s } else { _%s//\n", 
                        ePerl_begin_delimiter, ePerl_end_delimiter);
                cp = caStr;
            }
            else if (strncmp(cp, "#endif", 6) == 0) {
                /* 
                 *  found a #endif directive
                 */
                cps = cp+6;

                /* skip to end of line */
                for (i = 0; cps < cpEND && *cps != '\n'; cps++)
                    ;
                if (*cps == '\n')
                    cps++;

                /* create replacement string */
                sprintf(caStr, "%s } _%s//\n", 
                        ePerl_begin_delimiter, ePerl_end_delimiter);
                cp = caStr;
            }
            else if (strncmp(cp, "#c", 2) == 0) {
                /* 
                 *  found a #c directive
                 */
                cps = cp+2;

                /* skip to end of line */
                for (i = 0; cps < cpEND && *cps != '\n'; cps++)
                    ;
                if (*cps == '\n')
                    cps++;

                /* create replacement string: just a newline 
                 * to preserve line numbers */
                sprintf(caStr, "\n");
                cp = caStr;
            }

            /* allocate space and add replacement data */
            i = strlen(cp);
            nOutBuf += i;
            if ((cp2 = (char *)realloc(cpOutBuf, nOutBuf)) == NULL) {
                ePerl_PP_SetError("Failed on realloc(buf, %d)", nOutBuf);
                free(cpOutBuf);
                return NULL;
            }
            cpOutBuf = cp2;
            strcpy(cpOutBuf+nOut, cp);
            nOut += i;

            continue;
        }
        else {
            /* no more found */

            /* allocate space and add data */
            nOutBuf += (cpEND-cps);
            if ((cp2 = (char *)realloc(cpOutBuf, nOutBuf)) == NULL) {
                ePerl_PP_SetError("Failed on realloc(buf, %d)", nOutBuf);
                free(cpOutBuf);
				/* XXX free(cp); */
                return NULL;
            }
            cpOutBuf = cp2;
            strcpy(cpOutBuf+nOut, cps);

            break;
        }
    }

    if (cpInBuf)
        free(cpInBuf);

    return cpOutBuf;
}

char *ePerl_PP(char *cpBuf, char **cppINC)
{
    return ePerl_PP_Process(cpBuf, cppINC, 1 /*mode=buffer*/);
}

/*EOF*/
