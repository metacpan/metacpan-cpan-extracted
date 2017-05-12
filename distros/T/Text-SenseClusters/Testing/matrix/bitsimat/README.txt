*******************************************************************************

		     README.txt FOR Testing bitsimat.pl

                               Version 0.02
                         Copyright (C) 2002-2004
                       Ted Pedersen, tpederse@umn.edu
                    Amruta Purandare amruta@cs.pitt.edu
                       University of Minnesota, Duluth

*******************************************************************************


Testing for bitsimat.pl
------------------------

AMRUTA PURANDARE
amruta@cs.pitt.edu
02/16/2004

1. Introduction: 
----------------

This program is a component of the SenseClusters package that constructs a 
similarity matrix for the given binary vectors. The scripts and files provided 
here could be used to test the correct behaviour of the program and backward 
compatibility. 

2. Tests:
----------

2.1 Normal conditions:
----------------------

Tests written in testA*.sh test bitsimat.pl under normal conditions.

Test A1		Tests bitsimat for default measure 
		Sub tests test matrices with
		m > n
		m < n
		m == n

Test A2		Tests when --measure = match

Test A3		Tests when --measure = dice

Test A4		Tests when --measure = overlap

Test A5		Tests when --measure = jaccard

Test A6		Tests when --measure = cosine

Test A7		Tests when input contains <keyfile> tag

Test A8		Tests on highly sparse bit vectors including
		null vectors 

Each of the above tests verifies both the dense and sparse formatted bit 
vectors.

2.2 Error conditions:
----------------------

Tests written in testB*.sh test bitsimat.pl under error conditions.

Test B1		Tests when vector doesn't show
		#rows #cols #nnz or #rows #cols in the header line 

Test B2		Tests when vectors show wrong column entries 

3. Conclusions:
---------------

We have tested program bitsimat.pl enough to conclude that it runs correctly.
We have also provided the test scripts so that future versions of 
bitsimat.pl can be compared to the current version against these scripts.

