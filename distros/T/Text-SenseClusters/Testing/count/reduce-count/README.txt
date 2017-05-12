*******************************************************************************

		     README.txt FOR Testing reduce-count.pl

                               Version 0.01
                         Copyright (C) 2002-2004
                       Ted Pedersen, tpederse@umn.edu
                    Amruta Purandare amruta@cs.pitt.edu
                       University of Minnesota, Duluth

*******************************************************************************


Testing for reduce-count.pl
---------------------------

AMRUTA PURANDARE
amruta@cs.pitt.edu
05/25/2004


1. Introduction:
----------------

This program is a component of the SenseClusters package that reduces 
the given bigram file by retaining only those bigrams in which one
of the words occurs in the given unigram file. The scripts and files 
provided here could be used to test the correct behaviour of the program 
and backward compatibility. 

2. Tests:
---------

2.1 Normal conditions:
----------------------

Tests written in testA*.sh test reduce-count.pl under normal conditions.

Test A1:	Tests reduce-count when the stop words are removed and 
		tokens do not contain punctuations

Test A2:	Tests reduce-count when tokens in bigrams and unigrams
		include punctuations

Test A3:	Tests reduce-count when tokens include leading, lagging
		and internal blank spaces

Test A4:	Tests reduce-count when the bigram file is created 
		with --extended option in NSP

2.2 Error conditions:
----------------------

Tests written in testB*.sh test reduce-count.pl under error conditions.

Test B1:	Tests reduce-count when user enters a bigram file in place of
		the unigram file.

3. Conclusions:
---------------

We have tested program reduce-count.pl and conclude that it runs correctly.
We have provided the test scripts so that future versions of 
reduce-count.pl can be compared to the current version against these scripts.

