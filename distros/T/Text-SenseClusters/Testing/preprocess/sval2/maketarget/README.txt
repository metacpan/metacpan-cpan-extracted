*******************************************************************************

		     README.txt FOR Testing maketarget.pl

		   $Id: README.txt,v 1.5 2008/03/25 00:59:57 tpederse Exp $
                         Copyright (C) 2002-2006
                       Ted Pedersen, tpederse@umn.edu
                    Amruta Purandare amruta@cs.pitt.edu
                       University of Minnesota, Duluth

*******************************************************************************


Testing for maketarget.pl
--------------------------

AMRUTA PURANDARE
amruta@cs.pitt.edu
06/02/2004


1. Introduction:
----------------

This program is a component of the SenseClusters package that automatically
creates a Perl regex for the target word. The scripts and files provided here 
could be used to test the correct behaviour of the program and backward 
compatibility. 

2. Tests:
---------

2.1 Normal conditions:
----------------------

Tests written in testA*.sh test maketarget.pl under normal conditions.

Test A1  :	Tests on a preprocessed data in which all letters are in 
		lowercase

Test A2  :	Tests if maketarget.pl retains the case-sensivity of different 
		forms of a target word

Test A3  :	Tests when there are two distinct target words in the SVAL2
		file

Test A4  :	Tests when the target word has only one form

2.2 Error conditions:
----------------------

Tests written in testB*.sh test maketarget.pl under error conditions.

Test B1  :	Tests when the SVAL2 file does not contain any <head> tags

3. Conclusions:
---------------

We have tested program maketarget.pl and conclude that it runs correctly.
We have provided the test scripts so that future versions of 
maketarget.pl can be compared to the current version against these scripts.

