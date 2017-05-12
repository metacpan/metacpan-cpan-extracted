Testing for tmi3.pm
-------------------

Original Test Scripts for ll.pm by
Satanjeev Banerjee
bane0025@d.umn.edu
13th February, 2002

Modified for ll3.pm by
Amruta Purandare
pura0010@d.umn.edu
1st November, 2002

Modified for tmi3.pm by 
Ted Pedersen
tpederse@d.umn.edu
25th July, 2003

1. Introduction: 
----------------

We have tested tmi3.pm, a component of Ngram Statistics Package version
0.59. File tmi3.pm implements the true mutual information measure of 
association for 3 dimensions (tri-grams). Note that tmi3.pm is not a  
program by itself, but is a statistical library package that is plugged  
into statistic.pl. We test here the features of tmi3.pm by running  
statistic.pl.

Following is a description of the aspects of tmi3.pm that we have
tested. We provide the scripts and files used for testing so that
later versions of tmi3.pm can be tested for backward compatibility.


2. Phases of Testing: 
---------------------

We have divided the testing into two main phases: 

Phase 1: Testing tmi3.pm's response to erroneous conditions. 
Phase 2: Testing tmi3.pm's behaviour under normal conditions. 


2.1. Phase 1: Testing tmi.pm's response to erroneous conditions:
----------------------------------------------------------------------

The script for this phase is 'error-handling.sh'. To run the tests
contained in this script, type "error-handling.sh" at the command
prompt. 

This script performs several subtests: 

2.1.1. Subtest 1: 
-----------------

tmi3.pm is meant only for trigrams. This test checks if tmi3.pm throws
an error when provided with larger n-grams.

2.1.2. Subtest 2: 
-----------------

tmi3.pm requires 7 frequency values: the frequency of the trigram,
and the 6 marginal totals. If these are not provided, tmi3.pm should throw 
an error. This test checks for this error. 

2.1.3. Subtest 3: 
-----------------

The total number of trigrams in the file should be 1 or more. This test
checks if tmi3.pm does indeed throw an error when passed a total
trigrams value that is less than or equal to zero.

2.1.4. Subtest 4: 
-----------------

The numbers passed to tmi3.pm should be "valid" in that they should
represent a possible 3 D table. If this is not the case,
various warnings are thrown by tmi3.pm. This test checks for these
warnings. 

Following is the input file, test-1.sub-4.cnt: 

35
one<>two<>three<>-2 14 15 11 5 4 6
one<>two<>four<>38 14 13 19 4 7 7
two<>three<>one<>16 14 13 21 4 8 5
two<>three<>five<>4 16 13 23 4 9 11
two<>three<>four<>4 16 -13 23 4 9 11
two<>three<>four<>4 16 13 23 40 9 11

The first trigram should elicit a warning that a frequency value cannot be 
negative. The next trigram should elicit the warning that the frequency value 
(38) cannot exceed the total number of trigrams. The third trigram should
result in a warning that the frequency value of the trigram (10) cannot
exceed the marginal totals. The fourth trigram has no problems and should 
be calculated for. The fifth trigram must not have a negative value
for the marginal total, the sixth trigram has too large a marginal value since 
it exceeds the total number of trigrams.



2.2. Phase 2: Testing tmi3.pm's behaviour under normal conditions:
------------------------------------------------------------------

The script for this phase is 'normal-handling.sh'. To run the tests
contained in this script, type "normal-handling.sh" at the command
prompt. 

This script performs a single subtest that checks two things: 

First, it checks if tmi3.pm works when the frequencies are given in a
non default order. All three frequency values are required, however
they could be in any order. Subtest a checks to see what happens when
the frequencies are in the default order and subtest b checks the situation 
when they are in a different order. 

Second it checks the actual calculations of tmi3.pm. The output target
files, test-2.sub-1-a.reqd and test-2.sub-1-b.reqd, have been checked
manually to see if the scores obtained are correct. 

2.3. Phase 3: Testing tmi3.pm's behaviour relative to ll3.pm
------------------------------------------------------------

True mutual information and the log-likelihood ratio only differ by a 
scaling factor, so they should have a perfect correlation. The only caveat 
to this is that tmi values tend to be much much smaller, and so a lack of 
precision in their values can lead to apparent differences in correlation 
with ll3. However, if sufficient precision is used with tmi3 then they 
will in fact agree. 

3. Conclusions:
---------------

Statistical library package tmi3.pm has been tested for erroneous
conditions and normal operations too. It works! These tests can be
used to check for backward compatibility of newer versions.

