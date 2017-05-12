THESE TEST CASES ORIGINALLY BELONGS TO THE SenseTools PACKAGE 
(http://www.d.umn.edu/~tpederse/sensetools.html) DEVELOPED 
BY SATANJEEV BANERJEE AND DR. TED PEDERSEN. IT HAS BEEN 
INCLUDED IN SenseClusters DISTRIBUTION FOR CONVENIENCE REASONS.

Testing for nsp2regex.pl:
-------------------------

Satanjeev Banerjee
bane0025@d.umn.edu

2001-10-28

Ted Pedersen
tpederse@umn.edu 

2003-05-10             (changed name from bsp2regex to nsp2regex)

1. Introduction: 
----------------

We have tested nsp2regex.pl, a component of SenseTools version
0.1. Following is a description of the aspects of nsp2regex.pl
that we have tested. Also provided below is an inventory of the
various files in this directory (SenseTools-0.1/Testing/nsp2regex),
and the role of each file. We provide the scripts and files used for
testing so that later versions of preprocess.pl can be tested for
backward compatibility. 


2. Phases of Testing: 
---------------------

We have divided the testing into two main phases of testing: 

Phase 1: Testing of commandline options
Phase 2: Evaluation of execution time on big files.


2.1 Phase 1 of Testing: Testing of Commandline Options:
-------------------------------------------------------

Following are the various subtests involved in this test:

Subtest  1: Testing nsp2regex.pl without a token file on bigrams with 
	    default window size.
Subtest  2: Testing nsp2regex.pl with a token file on bigrams with
	    default window size.
Subtest  3: Testing nsp2regex.pl without a token file on bigrams with 
	    window size = 3.
Subtest  4: Testing nsp2regex.pl with a token file on bigrams with
	    window size = 3.
Subtest  5: Testing nsp2regex.pl without a token file on bigrams with 
	    window size = 10.
Subtest  6: Testing nsp2regex.pl with a token file on bigrams with
	    window size = 10.
Subtest  7: Testing nsp2regex.pl without a token file on trigrams with 
	    default window size.
Subtest  8: Testing nsp2regex.pl with a token file on trigrams with
	    default window size.
Subtest  9: Testing nsp2regex.pl without a token file on trigrams with 
	    window size = 4.
Subtest 10: Testing nsp2regex.pl with a token file on trigrams with
	    window size = 4.
Subtest 11: Testing nsp2regex.pl without a token file on trigrams with 
	    window size = 10.
Subtest 12: Testing nsp2regex.pl with a token file on trigrams with
	    window size = 10.
Subtest 13: Testing nsp2regex.pl without a token file on bigrams that
	    contain characters that need to be escaped. 
Subtest 14: Testing nsp2regex.pl with a token file on bigrams that
	    contain characters that need to be escaped.

2.1.1. Files involved for these sub-tests: 
------------------------------------------

The source file for Subtest 2i-1: sub-i.source
The required output file for Subtest 2i-1: sub-i.source.reqd

The source file for Subtest 2i: sub-i.source
The required output file for Subtest 2i: sub-i.token.reqd

1 <= i <= 7

2.2 Details of Phase 2: Evaluation of Execution Time on Big Files:
------------------------------------------------------------------

Run on following architecture: Sun Ultra 5 running SunOS 5.8. 

time nsp2regex.pl big.bigram > big.regex
13.620u 0.440s 0:15.93 88.2%	0+0k 0+0io 316pf+0w

wc output on big.bigram:

137376  412122 3154593

3. Conclusion:
--------------

The major features of nsp2regex.pl have been tested. Several types of
inputs have been used for this testing, including some "borderline"
cases. This is version 0.1... these tests can be used to check for
backward compatibility of future versions of nsp2regex.pl

