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

int main(int argc, char **argv, char **env)
 {
  // --------------------------------------------------------------------
  // Min reqs to run ....
  // PLInit("t.pl");
  // Call func returning int and taking 3 parsms
  // PLCall(I,"TestFuncI","%d%f%s",33,100.00,"2nd Call");  
  // PLClose();
  // --------------------------------------------------------------------

  // More complex examples .........
  // Variables
  int A=1;
  char *C = "How U doin?";
  char *S;
  double D;
  int    I;

  // Init The program to load
  // Non existent PERL files cause SEGV!! Do more error checking...
  PLInit("t.pl");


  // Testing Array of string. Passing odd number of elements to Hash
  // Perl should crib...
  char **LAS;
  int ct = PLCall(LAS,"TestFuncHash","%s%f%d","Hai",(float)100,100);
  for(int i=0;i<ct;i++)
    {
     printf("LAS%s\n",LAS[i]);
    }

  // Testing Array of string
  // Returns -1 on error, otherwise returns number read
  // All allocations are done in PLCall. Free is left to user
  char **AS;
  ct = PLCall(AS,"TestFunc","%s%f%f","Hai",(float)100,100.00);
  for(int i=0;i<ct;i++)
    {
     printf("AS%s\n",AS[i]);
    }

  // Testing Array of double
  double *AD;
  ct = PLCall(AD,"TestFuncAD","");
  for(int i=0;i<ct;i++)
    {
     printf("AD%f\n",AD[i]);
    }
  // User has to free it

  // Testing PLGeneric
  char *complete;
  PLGeneric(complete,"||","TestFuncAS","");
  printf("Comp:%s\n",complete);

  // Testing Interger, Double call back
  PLCall(I,"TestFuncI","%d%f%s",33,100.00,"2nd Call");
  PLCall(D,"TestFuncD","%d%f%s",33,100.00,"2nd Call");

  printf("I=%d\nD=%f\nS=%s\n",I,D,"");

  // Testing passing Array of Integer,Double
  // Has to pass number of elements
  // before passing the array. If user misses this one out, could cause
  // SEGV!!!!
  int IA[]    = { 10,20,30 };
  double DA[] = { 0.10, 0.20 } ;
  PLCall(I,"TestFuncAI","%d%I%f%I%F",1,3,IA,0.50,3,IA,2,DA);
  printf("Array of Int ret I=%d\n",I);
 
  // Testing passing Array of Integer,Double
  char *CA[]  = { "One","Two","Three","Four","Five", "Six" };
  PLCall(I,"TestFuncCA","%d%S%d",10,6,CA,10);

  // Good practise to typecast if passing values directly
  //PLCall(S,"TestFunc","%d%f%s",33,(double)100,"2nd Call");

  //Test of error condition
  //PLCall(S,"TestFunc","%xx%f%s",33,100,"3rd Call");
  //PLCall(S,"TestFunc","%x%f%s",33,100,"4th Call");

  // Load additional modules
  //PLLoadModule("TT.pm");
  //Run PERL sub directly
  //perl_call_pv("TT::name", G_DISCARD | G_NOARGS);

  // Testing Perl Eval
  char **EvalRet;
  // Can return scalar as return $a;
  ct = PLEval(EvalRet,"$a = 'This is a Test'; $b = reverse($a); return ($a,$b);");
  for(int i=0;i<ct;i++)
    {
     printf("Eval %s\n",EvalRet[i]);
    }

  PLClose();
 }

