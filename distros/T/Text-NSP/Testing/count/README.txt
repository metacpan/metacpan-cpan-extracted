Testing for count.pl
--------------------

Satanjeev Banerjee
bane0025@d.umn.edu
14th February, 2002

Ying Liu
liux0395@umn.edu
8th February, 2010

------------------------------------------------------------------------------

			Upgrades since 14th February, 2002	

Date 		Tests Added		Upgrader	Importance

Jan 7,2003	Subtests 4c,4d,4e	Amruta		To test new features 
							of Stop option like
							Perl regex support, 
							AND and OR Modes 
								 
Jan 7,2003      Subtest 10 		Amruta		To test --nontoken
							option

Feb 8,2010      Subtest 11 		Ying		To test --tokenlist
							option
------------------------------------------------------------------------------
							

1. Introduction: 
----------------

We have tested count.pl, a component of Bigram Statistics Package
version 0.5. Following is a description of the aspects of count.pl
that we have tested. We provide the scripts and files used for testing
so that later versions of count.pl can be tested for backward
compatibility.


2. Phases of Testing: 
---------------------

We have divided the testing into two main phases: 

Phase 1: Testing count.pl's behaviour under normal conditions. 
Phase 2: Testing count.pl's response to erroneous conditions. 


2.1. Phase 1: Testing count.pl's behaviour under normal conditions. 
-------------------------------------------------------------------

The script for this phase is 'normal-op.sh'. To run the tests
contained in this script, type "normal-op.sh" at the command prompt.

This script performs several subtests: 

2.1.1. Subtest 1: 
-----------------

This test checks the tokenization process of count.pl using the
--token option.


Subtest a checks what happens when we have /\w+/ as a token. With such
a token, we should get all the contiguous alpha-numeric characters as
tokens. 


Subtest b checks what happens when we have the tokens /\w+/ and
/[.,;:']/. With these two tokens, we should get all that we got with
subtest a and all the punctuation marks. If there are two punctuation
marks together, then we should get them as two separate tokens. 


Subtest c uses the following token definitions: 

     /th/
     /nd/
     /\w+/

This test shows the effect of having two token definitions, where one
definition completely encompasses another definition. Given a piece of
text and a list of regular expressions, program count.pl tries to
match regular expressions against the text, starting with the first
character in the text. If multiple regular expressions match, the
regex that occurs the earliest in the list is chosen. This test
demonstrates the importance of the order of the input regex's. 

In the output file (test-1.sub-1-c.reqd), the word "the" is broken up
everytime into tokens "th" and "e" because /th/ appears before
/\w+/ in the list. However, "second" remains "second" and does not
break up into "seco" and "nd" because /nd/ does not match at the start
of the string. The only regex that does match is /\w+/ and it matches
the whole word (including the "nd" in the end) and so /nd/ never gets
a chance to match in thist test file. 


Subtest d uses /.../ as a token definition. This says that every set
of three consecutive characters forms a token.


Subtest e uses /\w\w\w/ as a token definition. This says that every
set of three consecutive alphanumeric charactesr forms a token. 

Subtest f uses /\w+\s+\w+/ as a token definition. This says that every
token consists of two banks of alphanumeric characters separated by
one bank of white space characters.


2.1.2. Subtest 2:
-----------------

This subtest checks various combinations of --ngram and --window. 

Subtest a uses the option --ngram 3 and does not use the --window
option. Thus the window size would default to 3. 

Subtest b uses the option --ngram 3 and --window 4. 

Subtest c uses the option --ngram 4 and does not use the --window
option. Thus the window size would default to 4.

Subtest d uses the options --ngram 4 and --window 5. 

Subtest e uses the options --ngram 1.

2.1.3. Subtest 3:
-----------------

This subtest checks the options --set_freq_combo and --get_freq_combo

Subtest a uses the option --get_freq_combo with --ngram 3 to check if
we are getting the correct default combinations for window size 3. 

Subtest b uses the option --get_freq_combo with --ngram 4 to check if
we are getting the correct default combinations for window size 4. 

Subtest c uses the option --set_freq_combo to set a user-defined
set of frequency combinations, with the option --ngram 3. Switch
--get_freq_combo is used to check if we are getting back the same
frequency combination file.

Subtest d uses the option --set_freq_combo to set a user-defined set
of frequency combinations, with the option --ngram 4. Switch
--get_freq_combo is used to check if we are getting back the same
frequency combination file. 


2.1.4. Subtest 4: 
-----------------

This subtest checks the option --stop. 

Subtest a uses the option --stop with --ngram set to 2. 

Subtest b uses the option --stop with --ngram set to 4. 

Subtest c uses the option --stop set to a stopfile which contains valid Perl 
regular expressions but without extended option @stop.mode. Hence count.pl will
use the default stop mode AND for this test.

Subtest d uses the option --stop set to a stopfile which contains valid Perl
regular expressions and extended option @stop.mode set to OR. Hence count.pl
will eliminate all bigrams in which at least one word is a stop word as per 
the given regexs.  

Subtest e uses the option --stop set to a stopfile which contains valid Perl
regular expressions and extended option @stop.mode set to AND. Hence count.pl
will eliminate all bigrams in which all words are stop words as per the given 
regexs.

2.1.5. Subtest 5:
-----------------

This subtest checks the options --frequency and --remove

Subtest a runs count.pl with option --frequency 2

Subtest b runs count.pl with option --frequency 4

Subtest c runs count.pl with option --remove 2

Subtest d runs count.pl with option --remove 4


2.1.6. Subtest 6:
-----------------

This subtest checks the switch --newLine. 

Subtest a runs count.pl without switch --newLine.

Subtest b runs count.pl with switch --newLine, and we note the
difference on the same input file. 


2.1.7. Subtest 7:
-----------------

This subtest checks the option --histogram.

Subtest a runs count.pl with the option --histogram using bigrams.

Subtest b runs count.pl with the option --histogram using --ngram 3.


2.1.8. Subtest 8:
-----------------

This subtest checks count.pl's capacity to take a directory as an
input and use all text files lying there in. Also checks the switch
--recurse. 

Subtest a runs count.pl without the switch --recurse and with the
data-dir which is a directory containing two text files and four
subdirectories also containing text files. Since --recurse has not
been used, only the two text files directly in the data-dir directory
should be used for processing. 

Subtest b runs count.pl with the switch --recurse and with the
data-dir. This time all the text files in all the subdirectories of
data-dir should also be processed. 

2.1.9. Subtest 9:
-----------------

This subtest checks count.pl's --extended switch.

2.1.10. Subtest 10:
-----------------

This subtest checks count.pl's nontoken option. 

Subtest a checks if count.pl removes every occurrence of a given nontoken 
sequence when there is only single sequence in the nontoken file

Subtest b checks if count.pl removes every occurrence of given nontoken 
sequences when there are multiple sequences in the nontoken file

Subtest c checks if count.pl removes every occurrence of given nontoken 
sequences when the sequences use Perl Regex features like character classes

2.1.11 Subtest 11:
-----------------

This subtest checks count.pl's tokenlist option. 

Subtest a checks if count.pl print out all the bigrams of the text 


2.2. Phase 2: Testing count.pl's response to erroneous conditions:
------------------------------------------------------------------

The script for this phase is 'error-handling.sh'. To run the tests
contained in this script, type "error-handling.sh" at the command
prompt.

This script performs several subtests: 

2.2.1. Subtest 1: 
-----------------

This subtest checks the response of count.pl when not provided with
the source file!

2.2.2. Subtest 2: 
-----------------

This subtest checks the response of count.pl when given a source file
that does not exist!

2.2.3. Subtest 3:
-----------------

This subtest checks the response of count.pl when given --ngram 0.

2.2.4. Subtest 4:
-----------------

This subtest checks the response of count.pl when given --ngram 1
--window 2. Note that with --ngram 1, we can only have --window 1 (the
default). 

2.2.5. Subtest 5:
-----------------

This subtest checks the response of count.pl when given a window size
less than the ngram size. 

2.2.6. Subtest 6:
-----------------

This subtest checks the response of count.pl when given a non-existent
file with --stop.

2.2.7. Subtest 7:
-----------------

This subtest checks the response of count.pl when given a non-existent
file with --token.

2.2.8. Subtest 8:
-----------------

This subtest checks the response of count.pl when given a frequency
combination file that has indices incosistent with the current n-gram
size. 


3. Evaluation of execution time of count.pl on big files:
---------------------------------------------------------

The following experiments were conducted on machine csdev01 at the
Univ of Minnesota, Duluth, Computer Science Department laboratory. 

scarp.txt is the etext "The Scarlet Pimpernel" by Baroness Orczy
obtained from the following url:
ftp://ibiblio.org/pub/docs/books/gutenberg/etext93/scarp10.txt

wc scarp.txt:   10661   86332  507081 scarp10.txt

1> time count.pl scarp.2.cnt scarp10.txt
   50.0u 0.0s 0:50 98% 0+0k 0+0io 0pf+0w

2> time count.pl --ngram 3 scarp.3.cnt scarp10.txt 
   120.0u 0.0s 2:01 98% 0+0k 0+0io 0pf+0w

3> time count.pl --ngram 4 scarp.4.cnt scarp10.txt
   242.0u 1.0s 4:06 98% 0+0k 0+0io 0pf+0w


4. Conclusions:
---------------

We have tested program count.pl and conclude that it runs
correctly. We have also provided the test scripts so that future
versions of count.pl can be compared to the current version against
these scripts.

