*******************************************************************************

		        README.txt FOR Testing wordvec.pl

                               Version 0.3
                         Copyright (C) 2002-2004
                       Ted Pedersen, tpederse@umn.edu
                    Amruta Purandare amruta@cs.pitt.edu
                       University of Minnesota, Duluth

*******************************************************************************


Testing for wordvec.pl
------------------------

AMRUTA PURANDARE
amruta@cs.pitt.edu
05/31/2004


1. Introduction: 
----------------

This program is a component of the SenseClusters package that constructs 
word vectors. The scripts and files provided here could be used to test 
the correct behaviour of the program and backward compatibility. 

2. Tests:
----------

2.1 Normal conditions:
----------------------

Tests written in testA*.sh test wordvec.pl under normal conditions.

Tests A1-A10 test wordvec when the feature file does not exist and is to be 
automatically created by wordvec, while tests A11-20 run the same tests as
A1-A10 but when the features file is provided by the user.

Test A1  :
Test A11 :	 Tests wordvec when input is created by combig

Test A2  :
Test A12 :	 Tests wordvec when input is created by count

Test A3  :
Test A13 :	 Tests wordvec when input is created by statistic

Test A4  :
Test A14 :	 Tests wordvec when bigrams include punctuations like
		 period, comma

Test A5  :
Test A15 :	 Tests wordvec on Hindi transliterated data

Test A6  :
Test A16 :	 Tests wordvec when each token in a bigram is a word pair

Test A7  :
Test A17 :	 Tests wordvec on data containing phone nos and email ids

Test A8  :
Test A18 :	 Tests wordvec's --binary option

Test A9  :
Test A19 :	 Tests --extarget option in wordvec

Test A10 :
Test A20 :	 Simple test added after adding sparse support. Uses sample
		 bigrams from Serve data


Each of the above tests actually runs several tests that test options 
--wordorder and --dense internally within the test. Expected test results 
that end with 
	1. test-A*a*.reqd - run wordvec with --wordorder = follow 
	2. test-A*b*.reqd - run wordvec with --wordorder = precede
	3. test-A*c*.reqd - run wordvec with --wordorder = nocare
	4. test-A*1.reqd - run wordvec with --dense
	5. test-A*2.reqd - run wordvec without --dense

2.2 Error conditions:
----------------------

Tests written in testB*.sh test wordvec.pl under error conditions.

Test B1:        Tests wordvec under the floating point over/under flow errors.

3. Conclusions:
---------------

We have tested program wordvec.pl enough to conclude that it runs correctly.
We have also provided the test scripts so that future versions of 
wordvec.pl can be compared to the current version against these scripts.

