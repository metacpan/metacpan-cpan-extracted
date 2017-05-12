THESE TEST CASES ORIGINALLY BELONGS TO THE SenseTools PACKAGE 
(http://www.d.umn.edu/~tpederse/sensetools.html) DEVELOPED 
BY SATANJEEV BANERJEE AND DR. TED PEDERSEN. IT HAS BEEN 
INCLUDED IN SenseClusters DISTRIBUTION FOR CONVENIENCE REASONS.

Testing for preprocess.pl
-------------------------

Satanjeev Banerjee
bane0025@d.umn.edu
2001-10-28

Ted Pedersen
tpederse@umn.edu
2003-05-02                  (added tests for nontoken option)

1. Introduction: 
----------------

We have tested preprocess.pl, a component of SenseTools version 0.3.  
Following is a description of the aspects of preprocess.pl that we have  
tested. Also provided below is an inventory of the various files in this  
directory (SenseTools-0.3/Testing/preprocess), and the role of each file.  
We provide the scripts and files used for testing so that later versions  
of preprocess.pl can be tested for backward compatibility. 


2. Phases of Testing: 
---------------------

We have divided the testing into three main phases of testing: 

Phase 1: Testing of commandline options
Phase 2: Demonstration of preprocess.pl's response to "tricky" cases.
Phase 3: Evaluation of execution time on big files.


2.1. Phase 1 of Testing: Testing of Commandline Options
-------------------------------------------------------

This phase has been divided into four tests as follows.

 Test 1: Tests the options --token, --useLexelt, --useSenseid, --removeNotToken.
 Test 2: Tests the options --xml, --noxml, --count, --nocount.
 Test 3: Tests the options --split, --seed.

2.1.1 Test 1: --token, --useLexelt, --useSenseid, --removeNotToken:
-------------------------------------------------------------------

File test-1.sh contains the scripts that run preprocess.pl against
input and compare the output against the "required" output. Following
are the various subtests involved included in test-1.sh. To re-run
these tests, go "test-1.sh".

Subtest 1:      Testing preprocess.pl without any options
Command line:   preprocess.pl SOURCE
Files involved: 

  test-1.xml                     => the source file being tested on
  test-1.sub-1.word1.xml.reqd    => the required output for first word's xml file
  test-1.sub-1.word1.count.reqd  => the required output for first word's count file
  test-1.sub-1.word2.xml.reqd    => the required output for second word's xml file
  test-1.sub-1.word2.count.reqd  => the required output for second word's count file
  test-1.sub-1.word3.xml.reqd    => the required output for third word's xml file
  test-1.sub-1.word3.count.reqd  => the required output for third word's count file


Subtest 2:      Testing preprocess.pl with a token file
Command line:   preprocess.pl SOURCE --token TOKEN
Files involved: 

  test-1.xml                     => the source file being tested on
  test-1.sub-2.token.txt         => the token file 
  test-1.sub-2.word1.xml.reqd    => the required output for first word's xml file
  test-1.sub-2.word1.count.reqd  => the required output for first word's count file
  test-1.sub-2.word2.xml.reqd    => the required output for second word's xml file
  test-1.sub-2.word2.count.reqd  => the required output for second word's count file
  test-1.sub-2.word3.xml.reqd    => the required output for third word's xml file
  test-1.sub-2.word3.count.reqd  => the required output for third word's count file


Subtest 3:      Testing preprocess.pl with a token file and with option --useLexelt selected
Command line:   preprocess.pl SOURCE --useLexelt --token TOKEN
Files involved: 

  test-1.xml                     => the source file being tested on
  test-1.sub-3.token.txt         => the token file 
  test-1.sub-3.word1.xml.reqd    => the required output for first word's xml file
  test-1.sub-3.word1.count.reqd  => the required output for first word's count file
  test-1.sub-3.word2.xml.reqd    => the required output for second word's xml file
  test-1.sub-3.word2.count.reqd  => the required output for second word's count file
  test-1.sub-3.word3.xml.reqd    => the required output for third word's xml file
  test-1.sub-3.word3.count.reqd  => the required output for third word's count file


Subtest 4:      Testing preprocess.pl with a token file and with option --useSenseid selected
Command line:   preprocess.pl SOURCE --useSenseid --token TOKEN
Files involved: 

  test-1.xml                     => the source file being tested on
  test-1.sub-4.token.txt         => the token file 
  test-1.sub-4.word1.xml.reqd    => the required output for first word's xml file
  test-1.sub-4.word1.count.reqd  => the required output for first word's count file
  test-1.sub-4.word2.xml.reqd    => the required output for second word's xml file
  test-1.sub-4.word2.count.reqd  => the required output for second word's count file
  test-1.sub-4.word3.xml.reqd    => the required output for third word's xml file
  test-1.sub-4.word3.count.reqd  => the required output for third word's count file


Subtest 5:      Testing preprocess.pl with a token file and --removeNotToken
Command line:   preprocess.pl SOURCE --token TOKEN --removeNotToken
Files involved: 

  test-1.xml                     => the source file being tested on
  test-1.sub-2.token.txt         => the token file 
  test-1.sub-5.word1.xml.reqd    => the required output for first word's xml file
  test-1.sub-5.word1.count.reqd  => the required output for first word's count file
  test-1.sub-5.word2.xml.reqd    => the required output for second word's xml file
  test-1.sub-5.word2.count.reqd  => the required output for second word's count file
  test-1.sub-5.word3.xml.reqd    => the required output for third word's xml file
  test-1.sub-5.word3.count.reqd  => the required output for third word's count file

2.1.2 Test 2: --xml, --count, --noxml, --nocount:
-------------------------------------------------

File test-2.sh contains the scripts that run preprocess.pl against
various input and compare the output against the "required"
output. Following are the various subtests involved included in
test-2.sh. To re-run these tests, go "test-2.sh".

Subtest 1:      Testing preprocess.pl with --xml
Command line:   preprocess.pl SOURCE --xml out.xml
Files involved: 

  test-1.xml                     => the source file being tested on
  test-2.sub-1.xml.reqd          => the required output xml file
  test-1.sub-1.word1.count.reqd  => the required output for first word's count file
  test-1.sub-1.word2.count.reqd  => the required output for second word's count file
  test-1.sub-1.word3.count.reqd  => the required output for third word's count file


Subtest 2:      Testing preprocess.pl with --count
Command line:   preprocess.pl SOURCE --count out.count
Files involved: 

  test-1.xml                     => the source file being tested on
  test-2.sub-2.count.reqd        => the required output count file
  test-1.sub-1.word1.xml.reqd    => the required output for first word's xml file
  test-1.sub-1.word2.xml.reqd    => the required output for second word's xml file
  test-1.sub-1.word3.xml.reqd    => the required output for third word's xml file


Subtest 3:      Testing preprocess.pl with --xml --nocount
Command line:   preprocess.pl SOURCE --xml out.xml --nocount
Files involved: 

  test-1.xml                     => the source file being tested on
  test-2.sub-1.xml.reqd          => the required output xml file


Subtest 4:      Testing preprocess.pl with --count --noxml
Command line:   preprocess.pl SOURCE --count out.count --noxml
Files involved: 

  test-1.xml                     => the source file being tested on
  test-2.sub-2.count.reqd        => the required output count file


2.1.3. Test 3: --split, --seed:
-------------------------------

File test-3.sh contains the scripts that run preprocess.pl against
various input and compare the output against the "required"
output. Following are the various subtests involved included in
test-3.sh. To re-run these tests, go "test-3.sh".

Subtest 1:      Testing preprocess.pl with --split 75 --seed 1
Command line:   preprocess.pl SOURCE --split 25 --seed 1
Files involved: 

  test-1.sub-2.word1.xml.reqd    => the source file being tested on
  test-3.sub-1.test.count.reqd   => the required output test count file
  test-3.sub-1.test.xml.reqd     => the required output test xml file
  test-3.sub-1.train.count.reqd  => the required output training count file
  test-3.sub-1.train.xml.reqd    => the required output training xml file


Subtest 2:      Testing preprocess.pl with --split 25 --seed 1
Command line:   preprocess.pl SOURCE --split 75 --seed 1
Files involved: 

  test-1.sub-2.word1.xml.reqd    => the source file being tested on
  test-3.sub-2.test.count.reqd   => the required output test count file
  test-3.sub-2.test.xml.reqd     => the required output test xml file
  test-3.sub-2.train.count.reqd  => the required output training count file
  test-3.sub-2.train.xml.reqd    => the required output training xml file

2.1.4. Test 4: 
--------------


2.1.5. Test 5: 
--------------


2.1.6. Test 6: --putSentenceTags:
---------------------------------

File test-6.sh contains the scripts that run preprocess.pl against
file test-6.xml and tests the option --putSentenceTags. To re-run
these tests, go "test-6.sh".

Subtest 1:      Testing preprocess.pl with --putSentenceTags
Command line:   preprocess.pl SOURCE --putSentenceTags --token FILE
Files involved: 

  test-6.sh                      => the test script
  test-6.xml.reqd                => the source file being tested on
  test-6.token.txt               => the token file
  test-6.xml.reqd                => the required output xml file
  test-6.count.reqd              => the required output count file

2.1.7. Test 7: --nontoken:
--------------------------

File test-7.sh contains the scripts that run preprocess.pl against file 
test-7.xml and tests the option --nontoken. To re-run these tests, submit  
"test-7.sh".

Subtest 1:      Testing preprocess.pl with --nontoken
Command line:   preprocess.pl SOURCE --nontoken FILE
Files involved: 

  test-7.sh                => the test script
  test-7.xml               => the source file being tested on
  test-7.nontoken.txt      => the nontoken file
  test-7.sub-1.xml.reqd    => the required output for first word's xml file
  test-7.sub-1.count.reqd  => the required output for first word's count file


Subtest 2:      Testing preprocess.pl with --nontoken and --token
Command line:   preprocess.pl SOURCE --token TOKEN --nontoken NONTOKEN
Files involved: 

 test-7.sh                   => the test script
 test-7.xml                  => the source file being tested on
 test-7.sub-1.nontoken.txt   => the nontoken file
 test-7.sub-2.token.txt      => the token file
 test-7.sub-2.xml.reqd       => the required output for first word's xml file
 test-7.sub-2.count.reqd     => the required output for first word's count file

2.2. Phase 2: Demonstration of preprocess.pl's Response to "Tricky" Cases:
--------------------------------------------------------------------------

2.2.1. Test 1: Unusual Tokens:
------------------------------

This test checks and demonstrates preprocess.pl's behaviour when faced 
with unusual tokens. "Usual" tokens assume that words are space 
separated... but this may not always be true. This test investigates this 
issue.

File test-4.sh contains the scripts that run preprocess.pl against various  
input and compare the output against the "required" output. Following are  
the various subtests involved included in test-4.sh. To re-run these  
tests, go "test-4.sh".

Subtest 1:      Testing preprocess with the token /.../, that is a
		three-character sequence 

Command line:   preprocess.pl SOURCE --token TOKEN 
Files involved: 

  test-4.xml                     => the source file being tested on
  test-4.sub-1.token.txt         => the token file
  test-4.sub-1.count.reqd        => the required output count file
  test-4.sub-1.xml.reqd          => the required output xml file


Subtest 2:      Testing preprocess with the token /\w\w\w/, that is a
		three-alphanum-character sequence. 
Command line:   preprocess.pl SOURCE --token TOKEN 
Files involved: 

  test-4.xml                     => the source file being tested on
  test-4.sub-2.token.txt         => the token file
  test-4.sub-2.count.reqd        => the required output count file
  test-4.sub-2.xml.reqd          => the required output xml file


Subtest 3:      Testing preprocess with the token /\w+\s+\w+/, that is
		two words separated by white space. 
Command line:   preprocess.pl SOURCE --token TOKEN 
Files involved: 

  test-4.xml                     => the source file being tested on
  test-4.sub-3.token.txt         => the token file
  test-4.sub-3.count.reqd        => the required output count file
  test-4.sub-3.xml.reqd          => the required output xml file


Subtest 4:      Testing preprocess with tokens that capture xml tags
Command line:   preprocess.pl SOURCE --token TOKEN 
Files involved: 

  test-4.xml                     => the source file being tested on
  test-4.sub-4.token.txt         => the token file
  test-4.sub-4.count.reqd        => the required output count file
  test-4.sub-4.xml.reqd          => the required output xml file


2.2.2. Test 2: Source File with No New Line:
--------------------------------------------

It is not necessary that the input SOURCE file be "well
mannered". That is, xml tags outside the <context> </context> region
need not be on lines of their own, nor may they appear flush to the
left of the text region. This test investigates preprocess.pl's
behaviour when faced with such a SOURCE file.

The input file, test-5.xml is exactly the same as test-1.xml except
for the fact that test-5.xml has no new line characters. This allows
us to check the "worst-case" situation for xml-tags... they are all on
the same line!

This test, test-5.sh, is different from test-1.sh only in the input
file, test-5.xml. Every thing else is the same, and hence the
"required" files are also the same as test 1 (section 2.1.1).

2.3 Phase 3: Evaluation of Execution Time on Big Files:
-------------------------------------------------------

Run on following architecture: Sun Ultra 5 running SunOS 5.8. 

time preprocess.pl lex.xml
68.0u 1.0s 2:29 46% 0+0k 0+0io 0pf+0w

wc output on lex.xml: 

94109 1032866 7028848

3. Conclusion:
--------------

The major features of preprocess.pl have been tested. Testing has also
been done for some "borderline" cases. This is version 0.1... these
tests can be used to check for backward compatibility of future
versions of preprocess.pl. 

