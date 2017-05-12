Testing for phi.pm
-------------------

Ted Pedersen
25th July 2003

1. Introduction: 
----------------

We have tested phi.pm, a component of Ngram Statistics Package version
0.59. File phi.pm implements the Phi Coefficient. Note that phi.pm is not  
a  program by itself, but is a statistical library package that is  
plugged  into statistic.pl. We test here the features of phi.pm by  
running statistic.pl.

Following is a description of the aspects of phi.pm that we have
tested. We provide the scripts and files used for testing so that
later versions of phi.pm can be tested for backward compatibility.

2. Phases of Testing: 
---------------------

We have divided the testing into two main phases: 

Phase 1: Testing phi.pm's response to erroneous conditions. 
Phase 2: Testing phi.pm's behaviour under normal conditions. 


2.1. Phase 1: Testing phi.pm's response to erroneous conditions:
----------------------------------------------------------------------

The script for this phase is 'error-handling.sh'. To run the tests
contained in this script, type "error-handling.sh" at the command
prompt. 

This script performs several subtests: 

2.1.1. Subtest 1: 
-----------------

phi.pm is meant only for bigrams. This test checks if phi.pm throws
an error when provided with larger n-grams.

2.1.2. Subtest 2: 
-----------------

phi.pm requires three frequency values: the frequency of the bigram,
and the two marginal totals (number of bigrams with the token on the
left and number of bigrams with the total on the right). If these are
not provided, phi.pm should throw an error. This test checks for this
error. 

2.1.3. Subtest 3: 
-----------------

The total number of bigrams in the file should be 1 or more. This test
checks if phi.pm does indeed throw an error when passed a total
bigrams value that is less than or equal to zero.

2.1.4. Subtest 4: 
-----------------

The numbers passed to phi.pm should be "valid" in that they should
represent a possible two-by-two table. If this is not the case,
various warnings are thrown by phi.pm. This test checks for these
warnings. 

Following is the input file, test-1.sub-4.cnt: 

17
one<>two<>-1 13 7
one<>three<>18 13 5
one<>four<>10 6 12
two<>two<>10 12 6
two<>four<>1 3 5
three<>four<>1 -1 5
three<>one<>1 18 5
four<>five<>1 1 -1
three<>five<>1 1 18
three<>seven<>1 0 0

The first bigram, "one<>two<>" should elicit a warning that a
frequency value cannot be negative. The next bigram, "one<>three<>"
should elicit the warning that the frequency value (18) cannot exceed
the total number of bigrams. The third bigram, "one<>four<>" should
result in a warning that the frequency value of the bigram (10) cannot
exceed the marginal totals (12). Similarly for the next bigram. The
fifth bigram, "two<>four<>" has no problems and should be calculated
for. The sixth bigram "three<>four<>" must not have a negative value
for the marginal total, the seventh bigram "three<>one<>" has too
large a marginal value (18) since it exceeds the total number of
bigrams, the eighth bigram has a negative marginal total value and the
ninth bigram, "three<>five<>" has too large a marginal total. Finally,
the last bigram "three<>seven<>" again has its bigram frequency
greater than the marginal frequencies. 


2.2. Phase 2: Testing phi.pm's behaviour under normal conditions:
------------------------------------------------------------------

The script for this phase is 'normal-handling.sh'. To run the tests
contained in this script, type "normal-handling.sh" at the command
prompt. 

This script performs a single subtest that checks two things: 

First, it checks if phi.pm works when the frequencies are given in a
non default order. All three frequency values are required, however
they could be in any order. Subtest a checks to see what happens when
the frequencies are in the default order (0-1, 0, 1) and subtest b
checks the situation when they are in a different order (0, 1, 0-1). 

Second it checks the actual calculations of phi.pm. The output target
files, test-2.sub-1-a.reqd and test-2.sub-1-b.reqd, have been checked
manually to see if the scores obtained are correct. 


3. Conclusions:
---------------

Statistical library package phi.pm has been tested for erroneous
conditions and normal operations too. It works! These tests can be
used to check for backward compatibility of newer versions.

