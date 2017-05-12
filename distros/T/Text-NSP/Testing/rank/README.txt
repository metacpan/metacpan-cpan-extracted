Testing for rank.pl
-------------------

Satanjeev Banerjee
bane0025@d.umn.edu

1. Introduction: 
----------------

We have tested rank.pl, a component of Bigram Statistics Package
version 0.5. Following is a description of the aspects of rank.pl that
we have tested. We provide the scripts and files used for testing so
that later versions of rank.pl can be tested for backward
compatibility.


2. Phases of Testing: 
---------------------

We have divided the testing into two main phases: 

Phase 1: Testing rank.pl's behaviour under normal conditions. 
Phase 2: Testing rank.pl's response to erroneous conditions. 


2.1. Phase 1: Testing rank.pl's behaviour under normal conditions. 
-------------------------------------------------------------------

The script for this phase is 'normal-op.sh'. To run the tests
contained in this script, type "normal-op.sh" at the command prompt.

This script performs several subtests: 

2.1.1. Subtest 1: 
-----------------

This test checks to see if we get a value of 1 if we give rank.pl the
same ngram frequency file twice, and -1 if we give rank.pl the ngrams
in exactly reverse order.

Subtest a compares two files with ngrams in reverse order.
Subtest b compares the first file of subtest a against itself.
Subtest c compares the second file of subtest a against itself.

2.1.2. Subtest 2:
-----------------

This subtest checks what happens when one of the files has tied
ranks. The way ranks are given by statistic.pl to ngrams following a
bunch of tied ngrams is different from the ranking required by
rank.pl. Reranking is therefore done by rank.pl. This test checks if
the reranking is done correctly. 

2.1.3. Subtest 3:
-----------------

This subtest checks what happens when one file has more ngrams than
the other. Only those ngrams that occur in both files are used, and
are reranked. This test checks if this happens correctly.

2.1.4. Subtest 4: 
-----------------

This subtest checks the switch --precision

Subtest a does not use --precision.
Subtest b uses the switch --precision 10.
Subtest c uses the switch --precision 0.
Subtest d uses the switch --precision 1.

2.1.4. Subtest 5:
-----------------

This subtest runs rank.pl on two files first in some order, then in
the opposite order. Both times, the output should be the same. 


2.2. Phase 2: Testing rank.pl's response to erroneous conditions:
------------------------------------------------------------------

The script for this phase is 'error-handling.sh'. To run the tests
contained in this script, type "error-handling.sh" at the command
prompt.

This script performs several subtests: 

2.2.1. Subtest 1: 
-----------------

This subtest checks the response of rank.pl when the source file
cannot be opened. 

2.2.2. Subtest 2: 
-----------------

This subtest checks the response of rank.pl when only one source file
is provided. 


3. Evaluation of execution time of count.pl on big files:
---------------------------------------------------------

The following experiment was conducted on machine hh33809 at the Univ
of Minnesota Duluth, Computer Science Department laboratory.

Each input text had 15,181 bigrams to be compared. 

1> time rank.pl report.mi report.dice 
   2.560u 0.010s 0:02.58 99.6%	0+0k 0+0io 320pf+0w


4. Conclusions:
---------------

We have tested program rank.pl and conclude that it runs correctly. We
have also provided the test scripts so that future versions of rank.pl
can be compared to the current version against these scripts.
