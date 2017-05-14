/*JPERL Beta

  PERL Access routines in Java

  ---------------------------------------------------------------------
  Copyright (c) 1998, S Balamurugan, Texas Instruments India.
  All Rights Reserved.
  ---------------------------------------------------------------------

  Permission to  use, copy, modify, and  distribute this  software and
  its documentation for  NON-COMMERCIAL  purposes and without fee   is
  hereby granted provided that  this  copyright notice appears  in all
  copies.  Please  refer LICENCE  for  further  important  copyright 
  and licensing information.

  BECAUSE THE PROGRAM IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
  FOR  THE PROGRAM.  THE   PROGRAM IS  PROVIDED ON   AN "AS  IS" BASIS
  WITHOUT  WARRANTY OF  ANY     KIND, EITHER EXPRESSED   OR   IMPLIED,
  INCLUDING,  BUT   NOT   LIMITED  TO,   THE  IMPLIED   WARRANTIES  OF
  MERCHANTABILITY AND FITNESS FOR  A PARTICULAR PURPOSE. THE AUTHOR OR
  TEXAS INSTRUMENTS  SHALL NOT BE LIABLE FOR  ANY  DAMAGES SUFFERED BY
  LICENSEE AS  A RESULT   OF  USING, MODIFYING OR   DISTRIBUTING  THIS
  SOFTWARE OR ITS DERIVATIVES.

  ---------------------------------------------------------------------*/

#include <EXTERN.h>
#include <perl.h>

#define  MAX_SIZE   1024
#define  MAX_SCALAR 40

// Global Setup
static PerlInterpreter *my_perl = NULL;

// -------------------------------------------------------------------------
// MACRO PL_PARSE_ARGS. I dont like big macros, but this has to be...
// Does the argument parsing and conversion to Perl DS 
// -------------------------------------------------------------------------
#define PL_PARSE_ARGS  va_list element;      \
 int num, *iarr;                             \
 double *darr;                               \
 char  **carr;                               \
 char local_format[MAX_SIZE], *p;            \
 strcpy(local_format,format);                \
 va_start(element,format);                   \
 p = strtok(local_format,"%");               \
 dSP;                                        \
 ENTER;                                      \
 SAVETMPS;                                   \
 PUSHMARK(sp);                               \
 while ( p != NULL )                         \
  {                                          \
   if(strlen(p) > 1)                         \
     {                                                                      \
      printf("PLCall: Ignoring bad format string '%s'\n",p);                \
     }                                                                      \
   else                                                                     \
     {                                                                      \
      switch (p[0])                                                         \
       {                                                                    \
        case 'd': XPUSHs(sv_2mortal(newSViv(va_arg(element,int))));         \
                  break;                                                    \
        case 'f': XPUSHs(sv_2mortal(newSVnv(va_arg(element,double))));      \
                  break;                                                    \
        case 's': XPUSHs(sv_2mortal(newSVpv(va_arg(element,char *),0)));    \
                  break;                                                    \
        case 'I': num  = (int)va_arg(element,int);                          \
                  iarr = (int *)va_arg(element,int *);                      \
                  for(int i=0;i<num;i++)                                    \
                     XPUSHs(sv_2mortal(newSViv(iarr[i])));                  \
                  break;                                                    \
        case 'F': num  = (int)va_arg(element,int);                          \
                  darr = (double *)va_arg(element,double *);                \
                  for(int i=0;i<num;i++)                                    \
                     XPUSHs(sv_2mortal(newSVnv(darr[i])));                  \
                  break;                                                    \
        case 'S': num  = (int)va_arg(element,int);                          \
                  carr = (char **)va_arg(element,char **);                  \
                  for(int i=0;i<num;i++)                                    \
                     XPUSHs(sv_2mortal(newSVpv(carr[i],0)));                \
                  break;                                                    \
        default : printf("PLCall: Ignoring bad format string '%s'\n",p);    \
                  break;                                                    \
       }                                                                    \
     }                                                                      \
   p = strtok(NULL,"%");                                                    \
  }                                                                         \
 PUTBACK;
// ----------------------------------------------------------------------


// -------------------------------------------------------------------------
// MACRO for Cleanup after Perl calls
// -------------------------------------------------------------------------
#define PL_CLEANUP  PUTBACK; FREETMPS; LEAVE;


// -------------------------------------------------------------------------
// Function Prototypes
// -------------------------------------------------------------------------
int PLInit(char *perlfile);
int PLLoadModule(char *modulename);
int PLClose();

int PLCall(char *&retval, char *fname, char *format, ...);
int PLCall(int &retval, char *fname, char *format, ...);
int PLCall(double &retval, char *fname, char *format, ...);
int PLCall(int *&retval, char *fname, char *format, ...);
int PLCall(double *&retval, char *fname, char *format, ...);
int PLCall(char **&retval, char *fname, char *format, ...);
int PLEval(char **&retval, char *command);
int PLGeneric(char *&retstr, char *delim, char *fname, char *format, ...);
