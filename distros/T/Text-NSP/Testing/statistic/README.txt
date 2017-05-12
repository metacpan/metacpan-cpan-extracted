Testing for statistic.pl
------------------------

Satanjeev Banerjee
bane0025@d.umn.edu

Amruta Purandare
pura0010@d.umn.edu

June 14, 2004

1. Introduction: 
----------------

We have tested statistic.pl, a component of Bigram Statistics Package
version 0.5. Following is a description of the aspects of statistic.pl
that we have tested. We provide the scripts and files used for testing
so that later versions of statistic.pl can be tested for backward
compatibility.


2. Phases of Testing: 
---------------------

We have divided the testing into two main phases: 

Phase 1: Testing statistic.pl's response to erroneous conditions. 
Phase 2: Testing statistic.pl's behaviour under normal conditions. 


2.1. Phase 1: Testing statistic.pl's response to erroneous conditions:
----------------------------------------------------------------------

The script for this phase is 'error-handling.sh'. To run the tests
contained in this script, type "error-handling.sh" at the command
prompt. 

This script performs several subtests: 

2.1.1. Subtest 1: 
-----------------

This test checks the response of statistic.pl when an ngram in the
input ngram file does not have the expected number of tokens. The
expected number of tokens is equal to the value specified by the
--ngram switch, or 2 if this switch is not enforced.

This test is run with the file test-1.sub-1.cnt as the input ngram
file. This file has trigrams in it, and so statistic.pl should be run
with --ngram 3. Subtest a does not do so, and rather relies on the
default '2'. This should result in the error in file
test-1.sub-1-a.reqd.

Note that statistic.pl always requires a library to run with. If we
use a particular library here, future changes to that particular
library may cause these tests to break down through no fault of
statistic.pl. Hence we provide library test "test_1_sub_3_d.pm" for
this subtest (and similar library files for the other subtests). This
library always returns a 0 value.

Subtest b checks the same thing using --ngram 4 for which too we
should get an error. Finally subtest c checks for --ngram 3 for which
there should be no error.

2.1.2. Subtest 2: 
-----------------

This test checks to see what happens when the number of frequency
values in the input file does not match with the number expected. The
number of frequency values expected are either equal to the frequency
combinations set by switch --set_freq_combo, or equal to the default
number that count.pl creates from the current size of ngrams. 

File test-1.sub-2.cnt has trigrams in it, but with only 4 frequency
values as opposed to the possible 7. This file was created using
test-1.sub-2.freq_combo.txt file with the --set_freq_combo switch. So
statistic.pl should also be run with --set_freq_combo
test-1.sub-2.freq_combo.txt. Subtest a checks what happens if we dont
provide this file! The expected error message is in file
test-1.sub-2-a.reqd. 

Subtest b runs it with the requisite frequency combination file, and
so there should be no error for this run. 

2.1.3. Subtest 3: 
-----------------

The statistic library being loaded by statistic.pl must implement two
mandatory functions: initializeStatistic() and
calculateStatistic(). This test checks what happens when these
mandatory functions are not defined in the statistic library file. 

In subtest a we use statistical library file test_1_sub_3_a.pm which
neither defines nor exports the symbols &calculateStatistic and
&initializeStatistic. The error that statistic.pl should give is in
file test-1.sub-3-a.reqd. 

In subtest b we use statistical library file test_1_sub_3_b.pm which
defines initializeStatistic but not calculateStatistic, while in
subtest c we use statistical library file test_1_sub_3_c.pm which
defines calculateStatistic but not initializeStatistic. In both these
cases, statistic.pl should give an error, as in files
test-1.sub-3-b.reqd and test-1.sub-3-c.reqd respectively. 

Statistical library test-1.sub-3-d.pm defines both, and so we should
not get any error on this file, as tested in subtest d. 

2.1.4. Subtest 4: 
-----------------

This subtest checks statistic.pl's reaction when less than the
required number of files are provided to it on the commandline. 

Subtest a checks statistic.pl's reaction when only a library file is
provided while subtest b does the same for when only the library and
the destination files are provided. 

2.1.5. Subtest 5: 
-----------------

It is possible that the input ngram file does not have the main ngram
frequency. This might be alright, except that if a --frequency cut-off
is provided, it would be impossible to execute (since the ngram
frequency is missing). In this situation, statistic.pl provides a
warning that the frequency cut-off requested is being ignored. This
subtest checks for this warning. 

2.1.6 Subtest 6:
----------------

Tests if statistic.pl correctly detects the error when tokens include
the marker sequence <||>. This marker is internally used to separate
N-gram strings stored according to their statistic scores. The hash
structure we use stores all N-grams with a particular score separated
by <||> sequence in a hash. Having <||> within any N-gram tokens 
results into program malfunctioning. Hence, in such case, the program
is expected to abort with error message as shown in test-1.sub-6.reqd

2.2. Phase 2: Testing statistic.pl's behaviour under normal operation: 
----------------------------------------------------------------------

The script for this phase is 'normal-op.sh'. To run the tests
contained in this script, type "normal-op.sh" at the command
prompt.

This script performs several subtests: 

2.2.1. Subtest 1: 
-----------------

This subtest checks if set_freq_combo and get_freq_combo are working
fine or not. File test-2.sub-1-a.cnt has trigrams in it but without
all the frequency values. We will use switch --set_freq_combo to
provide statistic.pl with the necessary frequency combination file
(test-2.sub-1-a.freq_combo.txt) and then use --get_freq_combo to check
if we get exactly the same file again.

2.2.2. Subtest 2:
-----------------

In this subtest we observe the effect of using switch --frequency. In
subtest a, we use --frequency 2 to cut off all the ngrams with
frequency 1 while in subtest b, we use --frequency 3 to cut off
everything but the top ngram (which has a frequency of 3). 

2.2.3. Subtest 3:
-----------------

This subtest tests the --rank switch. Subtest a runs statistic.pl with
--rank 6 and subtest b with --rank 3. 

2.2.4. Subtest 4:
-----------------

This subtest checks the --precision switch. Subtest a runs
statistic.pl with --precision 0 which implies that we dont want any
places of decimal. Note that this is not an erroneous condition!
Subtest b runs it with --precision 5 and subtest c with --precision
10. 

2.2.5. Subtest 5: 
-----------------

In this subtest we check the effect of using the switch
--score. Subtest a runs statistic.pl using a score cutoff of 0.8 and
subtest b does the same with a cutoff of 1.2. 

2.2.6. Subtest 6: 
-----------------

This subtest tests the --format switch. The expected output is in file
test-2.sub-6.reqd. 

2.2.7. Subtest 7: 
-----------------

This subtest tests the --extended switch. The input file,
test-2.sub-7.cnt, has extended information (since it was created by
count.pl with the switch --extended). Subtest a runs statistic.pl on
this file with the --extended switch. The expected output, which
should have all the extended information preserved, as well as some
additional information, is in file test-2.sub-7-a.reqd. Subtest b runs
statistic.pl on this file without the --extended switch. The expected
output, which should have no extended information, is in file
test-2.sub-7-b.reqd.


3. Evaluation of execution time of count.pl on big files:
---------------------------------------------------------

The following experiments were conducted on machine csdev01 at the
Univ of Minnesota, Duluth, Computer Science Department laboratory. 

scarp.2.cnt was obtained by running count.pl on the etext "The Scarlet
Pimpernel" by Baroness Orczy obtained from the following url:
ftp://ibiblio.org/pub/docs/books/gutenberg/etext93/scarp10.txt

wc scarp.2.cnt: 45792  137374 1051531

1> time statistic.pl dice scarp.dice scarp.2.cnt
   23.0u 0.0s 0:24 95% 0+0k 0+0io 0pf+0w

2> time statistic.pl ll scarp.ll scarp.2.cnt
   35.0u 0.0s 0:36 96% 0+0k 0+0io 0pf+0w

3> time statistic.pl x2 scarp.x2 scarp.2.cnt
   30.0u 0.0s 0:31 95% 0+0k 0+0io 0pf+0w

4> time statistic.pl leftFisher scarp.leftFisher scarp.2.cnt
   71.0u 0.0s 1:12 98% 0+0k 0+0io 0pf+0w

5> time statistic.pl mi scarp.mi scarp.2.cnt
   28.0u 0.0s 0:29 96% 0+0k 0+0io 0pf+0w 


4. Conclusions:
---------------

Program statistic.pl has been run with a variety of switches, and
its response has been noted. These tests can be used to check for
backward compatibility of newer versions.

