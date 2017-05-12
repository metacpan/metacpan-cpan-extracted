*******************************************************************************

		     README.txt FOR Testing mat2harbo.pl

                               Version 0.04
                         Copyright (C) 2002-2004
                       Ted Pedersen, tpederse@umn.edu
                    Amruta Purandare amruta@cs.pitt.edu
                       University of Minnesota, Duluth

*******************************************************************************


Testing for mat2harbo.pl
------------------------

AMRUTA PURANDARE
amruta@cs.pitt.edu
06/01/2004


1. Introduction: 
----------------

This program is a component of the SenseClusters package that converts a
sparse matrix in SenseClusters format to Harwell-Boeing sparse format. The 
scripts and files provided here could be used to test the correct behaviour of 
the program and backward compatibility. 

2. Tests:
----------

2.1 Normal conditions:
----------------------

Tests written in testA*.sh test mat2harbo.pl under normal conditions.

Test A1  :	Tests mat2harbo when the input matrix is sparse rectangular 

Test A2	 :	Tests mat2harbo when the input matrix is 0% sparse

Test A3  :	Tests mat2harbo when the input matrix is of real numbers
		including -ve numbers 	

Test A4  :	Tests mat2harbo when the input matrix is square 

Test A5  :	Tests mat2harbo on real values with --numform specified	

Test A6  :	Tests mat2harbo's title, id,cpform, rpform, numform options 

Test A7  :	Tests mat2harbo on belladit data whose HB matrix is already 
		available

Test A8  :	Tests mat2harbo on some large sample matrices from LSI corpora

Test A9	 :	Tests --param option with all parameters default
		Conditions Tested - when maxprs = k, N/4

Test A10 :	Tests options --k and --rf

Test A11 :	Tests options --iter, --k, --rf together 



2.2 Error conditions:
----------------------

Tests written in testB*.sh form test mat2harbo.pl under error conditions.

Test B1  :	Incorrect numeric format for --cpform/--rpform/--numform

Test B2  :	Null column

Test B3  :	Formatting errors: overflow, underflow

3. Conclusions:
---------------

We have tested program mat2harbo.pl enough to conclude that it runs correctly.
We have also provided the test scripts so that future versions of 
mat2harbo.pl can be compared to the current version against these scripts.

