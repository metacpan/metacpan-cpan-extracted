*******************************************************************************

		     README.txt FOR Testing order1vec.pl

                               Version 0.06
                         Copyright (C) 2002-2004
                       Ted Pedersen, tpederse@umn.edu
                    Amruta Purandare amruta@cs.pitt.edu
                       University of Minnesota, Duluth

*******************************************************************************


Testing for order1vec.pl
-------------------------

AMRUTA PURANDARE
amruta@cs.pitt.edu
01/16/2004


1. Introduction:
----------------

This program is a component of the SenseClusters package that constructs
first order context vectors. The scripts and files provided here could be 
used to test the correct behaviour of the program and backward compatibility.

2. Tests:
----------

2.1 Normal conditions:
----------------------

Tests written in testA*.sh test order1vec.pl under normal conditions.

Test A1:	Tests order1vec on unigram features that do not include the 
		target word

Test A2:	Tests order1vec on unigram features that include the target 
		word which is delimited in <head> </head> tags

Test A3:	Tests order1vec on unigram features and frequency context
		vectors

Test A4:	Tests order1vec on POS tagged data

Test A5:	Tests order1vec on space separated bigram features

Test A6:	Tests order1vec on NSP bigram features 

Test A7:	Tests order1vec on NSP bigrams with window specified

Test A8:	Tests if order1vec creates correct cluto files

Test A9:	Tests cases A2, A3, A4, A5 when --extarget is specified

Test A10:	Tests order1vec on email data 

Test A11:	Tests order1vec on nameconflate data

Test A12: Tests order1vec in feature-by-context mode, with --testregex option
					and --rlabel and --clabel options
					
Additionally, each of the above test case tests output in both sparse and
dense formats. Expected result files ending with test*a.reqd verify the
correct dense format while those ending with test*b.reqd verify the 
sparse formatted output.

2.2 Error conditions:
---------------------

Currently No error tests added

3. Conclusions:
---------------

We have tested program order1vec.pl and conclude that it runs correctly.
We have also provided the test scripts so that future versions of 
order1vec.pl can be compared to the current version against these scripts.

