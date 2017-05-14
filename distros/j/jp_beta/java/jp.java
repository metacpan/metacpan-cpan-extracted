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
import java.util.Vector;
import java.util.Enumeration;

class jp
{
 static private int number_of_objects=0;
 static int debug=0;

 // Constructor
 public jp(String perlfile) throws RuntimeException
  {
   if (number_of_objects == 0)
      {
       number_of_objects = 1;
       PLInit(perlfile);
      }
   else
      throw new RuntimeException("Only one instace of Perl allowed");
  }

 // Destructor
 protected void finalize()
 {
  PLClose();
  number_of_objects = 0;
 }

 // Methods for turning on/off debug in the native code
 public void DebugOn() {
   debug=1;
 }

 public void DebugOff() {
   debug=0;
 }

 public String PLCallScalar(String fname) 
        throws RuntimeException
 {
  return IPLCallS(fname);
 }

 public String PLCallScalar(String fname, Object[] args) 
        throws RuntimeException,IllegalArgumentException
 {
  if (args == null) 
      throw new IllegalArgumentException("Arguments cannot be null");

  String[] sargs = ProcessArgs(args);
  return IPLCallS(fname, sargs);

 }

 public String[] PLCallArray(String fname, Object[] args) 
        throws RuntimeException,IllegalArgumentException 
 {
  if (args == null) 
      throw new IllegalArgumentException("Arguments cannot be null");

  String[] sargs = ProcessArgs(args);
  return IPLCallA(fname, sargs);
 }

 public Hashtable PLCallHash(String fname, Object[] args)
        throws RuntimeException,IllegalArgumentException 
 {
  if (args == null)
      throw new IllegalArgumentException("Arguments cannot be null");

  String[] sargs = ProcessArgs(args);
  String[] ret   = IPLCallA(fname, sargs);

  Hashtable retHash = new Hashtable();

  if (ret.length % 2 != 0)
      throw new RuntimeException("Odd number of arguments returned for Hash");

  for(int i=0; i < ret.length; i+=2)
     {
      retHash.put((String)ret[i],(String)ret[i+1]);
     }

  return retHash;
 }


 private String[] ProcessArgs(Object[] args) throws IllegalArgumentException
 {
  int ct  = GetCount(args);
  int sct = 0;
  String[] sargs = new String[ct];

  for(int i=0;i<args.length;i++)
     {
      if (args[i] == null)
          throw new IllegalArgumentException("Arguments cannot be null");

      String type = (args[i].getClass()).getName();
      if (type.equals("java.lang.Integer")   ||
          type.equals("java.lang.Double")    ||
          type.equals("java.lang.Float")     ||
          type.equals("java.lang.String")    ||
          type.equals("java.lang.Long")      ||
          type.equals("java.lang.Short"))
          sargs[sct++] =  (String)args[i].toString();
      else if (type.equals("java.util.Hashtable"))
           {
            Hashtable   H = (Hashtable)args[i];
            Enumeration E = H.keys();

            for(;E.hasMoreElements();)
               {
                Object key   =  E.nextElement();
                sargs[sct++] =  key.toString();
                sargs[sct++] =  (H.get(key)).toString();
               }
           }
      else if (type.equals("java.util.Vector"))
           {
            Vector V = (Vector)args[i];
            for(int j=0; j < V.size(); j++)
               {
                sargs[sct++] = (V.elementAt(j)).toString();
               }
           }
      else 
          throw new IllegalArgumentException("Invalid Argument type "+type);
     }

  return sargs;
 }

 private int GetCount(Object[] args) throws IllegalArgumentException
 {
  int count=0;
  for(int i=0;i<args.length;i++)
     {
      String type = (args[i].getClass()).getName();
      if (debug == 1) System.out.println(type);
      if (type.equals("java.lang.Integer")   ||
          type.equals("java.lang.Double")    ||
          type.equals("java.lang.Float")     ||
          type.equals("java.lang.String")    ||
          type.equals("java.lang.Long")      ||
          type.equals("java.lang.Short"))
          count++;
      else if (type.equals("java.util.Hashtable"))
           count += (((Hashtable)args[i]).size() * 2);
      else if (type.equals("java.util.Vector"))
           count += ((Vector)args[i]).size();
      else 
          throw new IllegalArgumentException("Invalid Argument type "+type);
    
     }
   return count;
 }
 // ----------------------------------------------------------------------
 // PERL call function prototypes
 // ----------------------------------------------------------------------
 // Initialize
 private native void PLInit(String perlfile) throws RuntimeException;

 // Cleanup
 private native void PLClose();

 // Return Perl scalar. Takes no arguments
 private native String   IPLCallS(String fname) throws RuntimeException;

 // Return Perl scalar. Takes any number and type of args
 private native String   IPLCallS(String fname, String[] args)  
         throws RuntimeException;

 // Return Perl Array.  Takes any number and type of args
 private native String[] IPLCallA(String fname, String[] args)
         throws RuntimeException;

 // Return Perl Array.  Takes an expression to evaluate
 public  native String[] IPLEval(String expression)
         throws RuntimeException;

 // Loads a new perl module
 public  native void IPLLoadLibrary(String libname)
         throws RuntimeException;

 // Load library for above call implementation
 static {
         System.loadLibrary("jperl");
        }
}
