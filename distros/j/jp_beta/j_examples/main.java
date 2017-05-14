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

import java.util.Hashtable;
import java.util.Stack;
import jp;

class main 
{
 public static void main(String[] args) 
  {
   String[] INP = new String[2];
   String t,t1;
   INP[0] = "Hai";
   INP[1] = "New";

   try {
   jp perl = new jp("t.pl");
   // Testing two instances. Sould throw exception
   // jp perl1 = new jp("../t.pl");
   //perl.DebugOn();

   // No args, returns scalar
   System.out.println("Testing no args return scalar................");
   t = perl.PLCallScalar("TestFuncCA");
   System.out.println("Ret from t:"+t);

   // args, returns scalar
   System.out.println("Testing args, return scalar................");
   t1 = perl.PLCallScalar("TestFuncCA",INP);
   if (t1 == null)
       System.out.println("t1 returned null");
   else
       System.out.println(t1);

   // args, returns array
   System.out.println("Testing args, return array................");
   String t2[] = perl.PLCallArray("TestFuncAS",INP);
   for(int i=0;i<t2.length;i++)
      {
       System.out.println(t2[i]);
      }

   // args, returns hash. Should fail since t.pl returns odd no of values
   //System.out.println("Testing args, return Illegal Hash................");
   //Hashtable H = perl.PLCallHash("TestFuncAS",INP);

   // Test returning Hash. Send Object array
   System.out.println("Testing args, return Hash................");
   Hashtable H = perl.PLCallHash("TestFuncHash",INP);
   System.out.println(H.toString());

   // Pass samething back to perl
   Object[] OB = new Object[1];
   OB[0] = H;
   H = perl.PLCallHash("TestFuncHash",OB);
   System.out.println(H.toString());

   // Testing PerlEval
   System.out.println("Testing Eval ............................");
   String[] EvRet = perl.IPLEval("$a = 'This is a test'; $b = reverse($a); return ($a,$b);");
   for(int i=0;i<EvRet.length;i++)
      {
       System.out.println(EvRet[i]);
      }

   }
   catch(IllegalArgumentException e) 
      { 
       System.out.println("Error caught"+e.getMessage()); 
      }
   catch(RuntimeException e) 
      { 
       System.out.println("Error caught"+e.getMessage()); 
      }

  }
}
