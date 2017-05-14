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

#include "jperl.h"

//-----------------------------------------------------------------------
//  Function PLCall.
//  Params  : Variable number of arguments
//  Returns : true/false 
//  Desc    : Calls the PERL function 'fname'. fname can be a subroutine 
//            or a package::method name.
//-----------------------------------------------------------------------
// This is needed since PERL strings need not be \0 terminated
int *PLstrcpy(char *&src, SV *inp)
 {
  if (SvPOK(inp))
     {
      unsigned int len  =  SvCUR(inp);
      char *dest =  SvPV(inp, len);
      src = (char *)malloc((sizeof(char)*len)+1);
      for(int i=0;i<len;i++)
         {
          src[i] = dest[i];
         }
      src[len] = '\0';
     }
  else 
     {
      src = (char *)malloc((sizeof(char)*MAX_SCALAR)+1);
      if (SvIOK(inp))
          sprintf(src,"%d%c",SvIV(inp),'\0');
      else if (SvNOK(inp))
          sprintf(src,"%f%c",SvNV(inp),'\0');
      else
          strcpy(src,"(null)");
     }
  return 0;
 }

//-----------------------------------------------------------------------
// Overloaded PLCall(1) Returns char * using retval
//-----------------------------------------------------------------------
int PLCall(char *&retval, char *fname, char *format, ...)
{
 PL_PARSE_ARGS;

 int count = perl_call_pv(fname, G_SCALAR);
 SPAGAIN;

 if(count != 1) { PL_CLEANUP; return -1; }

 SV *ret = POPs;
 PLstrcpy(retval, ret);

 PL_CLEANUP;
 return 1;
}

//-----------------------------------------------------------------------
// Overloaded PLCall(2) Returns int using retval
//-----------------------------------------------------------------------

int PLCall(int &retval, char *fname, char *format, ...)
{
 PL_PARSE_ARGS;

 int count = perl_call_pv(fname, G_SCALAR);
 SPAGAIN;

 if(count != 1) { PL_CLEANUP; return -1; }

 retval = POPi;
 
 PL_CLEANUP;
 return 1;
}

//-----------------------------------------------------------------------
// Overloaded PLCall(3) Returns double using retval
//-----------------------------------------------------------------------

int PLCall(double &retval, char *fname, char *format, ...)
{
 PL_PARSE_ARGS;

 int count = perl_call_pv(fname, G_SCALAR);
 SPAGAIN;

 if(count != 1) { PL_CLEANUP; return -1; }

 retval = POPn;

 PL_CLEANUP;
 return 1;
}

//-----------------------------------------------------------------------
// Overloaded PLCall(4). Returns Integer Array using retval
//-----------------------------------------------------------------------

int PLCall(int *&retval, char *fname, char *format, ...)
{
 // Fill up Parse and Perl DS conversion code here
 PL_PARSE_ARGS;

 int count = perl_call_pv(fname, G_ARRAY);
 SPAGAIN;
 
 if (count < 1) {  PL_CLEANUP; return -1; }

 // Allocate memory for the variables
 retval = (int *)malloc(sizeof(int)*count);
 for(int i = 0;i < count; i++)
     retval[count-1-i] = POPi;

 PL_CLEANUP;
 return count;
}

//-----------------------------------------------------------------------
// Overloaded PLCall(5). Returns Double Array using retval
//-----------------------------------------------------------------------

int PLCall(double *&retval, char *fname, char *format, ...)
{
 // Fill up Parse and Perl DS conversion code here
 PL_PARSE_ARGS;

 int count = perl_call_pv(fname, G_ARRAY);
 SPAGAIN;
 
 if (count < 1) {  PL_CLEANUP; return -1; }

 // Allocate memory for the variables
 retval = (double *)malloc(sizeof(double)*count);
 for(int i = 0;i < count; i++)
     retval[count-1-i] = POPn;

 PL_CLEANUP;
 return count;
}


//-----------------------------------------------------------------------
// Overloaded PLCall(6). Returns String Array using retval
//-----------------------------------------------------------------------

int PLCall(char **&retval, char *fname, char *format, ...)
{
 // Fill up Parse and Perl DS conversion code here
 PL_PARSE_ARGS;

 int count = perl_call_pv(fname, G_ARRAY);
 SPAGAIN;
 
 if (count < 1) {  PL_CLEANUP; return -1; }

 // Allocate memory for the variables
 retval = (char **)malloc(sizeof(char *)*count);
 for(int i = 0;i < count; i++)
    {
     SV *ret = POPs;
     PLstrcpy(retval[count-1-i],ret);
    }
 PL_CLEANUP;
 return count;
}

//-----------------------------------------------------------------------
// PLEval. Returns String Array using retval
//-----------------------------------------------------------------------

int PLEval(char **&retval, char *command)
{
 dSP;
 ENTER;
 SAVETMPS;

 PUSHMARK(sp);
 PUTBACK;

 int count = perl_eval_sv(newSVpv(command,0), G_ARRAY);
 SPAGAIN;
 
 if (count < 1) {  PL_CLEANUP; return -1; }

 // Allocate memory for the variables
 retval = (char **)malloc(sizeof(char *)*count);
 for(int i = 0;i < count; i++)
    {
     SV *ret = POPs;
     PLstrcpy(retval[count-1-i],ret);
    }
 PL_CLEANUP;
 return count;
}

//-----------------------------------------------------------------------
// Generic version of PLCall. Returns all params as string delimited by
// delim
//-----------------------------------------------------------------------

int PLGeneric(char *&retstr, char *delim, char *fname, char *format, ...)
{
 // Fill up Parse and Perl DS conversion code here
 PL_PARSE_ARGS;

 int count = perl_call_pv(fname, G_ARRAY);
 SPAGAIN;
 
 if (count < 1) {  PL_CLEANUP; return -1; }

 // Allocate memory for the variables
 char **retval = (char **)malloc(sizeof(char *)*count);
 int totalsize=0;
 for(int i = 0;i < count; i++)
    {
     SV *ret = POPs;
     PLstrcpy(retval[count-1-i],ret);
     totalsize += (SvCUR(ret)+1);
    }

 retstr = (char *)malloc((sizeof(char)*totalsize)+1);
 // Store in retval and return
 strcpy(retstr,"");
 for(int i = 0;i < count; i++)
    {
     strcat(retstr,retval[i]);
     if(i < (count - 1)) strcat(retstr,delim);
     free(retval[i]);
    }
 free(retval);

 PL_CLEANUP;
 return count;
}

//-----------------------------------------------------------------------
// PL Load Modules
//-----------------------------------------------------------------------

int PLLoadModule(char *modulename)
{
 perl_require_pv(modulename);
}

//-----------------------------------------------------------------------
// PL Initialize
//-----------------------------------------------------------------------

int PLInit(char *perlfile)
{
 char *args[]  = { "jperl", perlfile };
 int  argcount = 2;

 if (my_perl != NULL)
    {
     perl_destruct(my_perl);
     perl_free(my_perl);
    }

 my_perl = perl_alloc();
 perl_construct(my_perl);
 perl_parse(my_perl, NULL, argcount, args, NULL);
}

//-----------------------------------------------------------------------
// PL Cleanup
//-----------------------------------------------------------------------

int PLClose()
{
 perl_destruct(my_perl);
 perl_free(my_perl);
}
//-----------------------------------------------------------------------
