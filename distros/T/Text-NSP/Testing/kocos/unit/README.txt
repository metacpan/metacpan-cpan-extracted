*******************************************************************************

		        README.txt FOR Testing kocos.pl

                               Version 0.05
                         Copyright (C) 2002-2004
                       Ted Pedersen, tpederse@umn.edu
                    Amruta Purandare pura0010@d.umn.edu
                       University of Minnesota, Duluth

                   http://www.d.umn.edu/~tpederse/nsp.html


*******************************************************************************


Testing for kocos.pl
------------------------

AMRUTA PURANDARE
pura0010@d.umn.edu
07/03/2003


1. Introduction: 
----------------

This program is a component of NSP introduced in v0.53 and last modified
in v0.57. It displays the Kth order co-occurrences of a given target word
from a given Bigram output of NSP programs. The scripts and files provided 
here could be used to test the correct behaviour of the program and backward 
compatibility. 

2. Tests:
----------

2.1 Normal conditions:
----------------------

Tests written in testA*.sh test kocos.pl under normal conditions.
Run normal-op.sh to run all test cases testA*.sh 

Subtests ending with alphabets like a,b,c,d show the same test case run on
different orders.

Test A1[a-d]:	Test kocos when co-occurrence graph is a tree.

Test A2[a-b]:	Test kocos when co-occurrence graph has loops.

Test A3[a-b]:	Test kocos when co-occurrence graph is a 4 fold square

Test A4[a-c]:	Test kocos when co-occurrence graph is a complete bipartite

Test A5[a-c]:	Test kocos when co-occurrence graph is a cycle

Test A6[a-d]:	Test kocos when co-occurrence graph is a chain

Test A7[a-e]:	Test kocos when co-occurrence graph has a zigzag shape

Test A8[a-d]:	Test kocos when target is specified via regex option
Test A9[a-c]:		-------- " ---------

Test A10[a-e]:	Test kocos when target is ,

Test A11[a-d]:	Test kocos when target is /\./

Test A12[a-d]:	Test kocos when target is /nA$/

Test A13[a-e]:	Test kocos when data contains puctuations

Test A14[a-d]:	Test kocos when target is /\d/

Test A15[a-c]:	Test kocos when each token in a bigram is a bigram

Test A16[a-e]:	Test kocos when tokens include embedded puctuations

Test A17[a-b]:	Test kocos on some real text data

Test A18[a-c]:	Test kocos when tokens include phone numbers and email ids

Test A19[a-b]:	Test kocos on Hindi transliterated text data


2.2 Error conditions:
---------------------

Tests written in testB*.sh test kocos.pl under error conditions.
Run error-op.sh to run all test cases testB*.sh

Test B1:	Test error condition when order < 1

Test B2:	Test error condition when bigram file is not valid

3. Conclusions:
---------------

We have tested program kocos.pl enough to conclude that it runs correctly.
We have also provided the test scripts so that future versions of 
kocos.pl can be compared to the current version against these scripts.

