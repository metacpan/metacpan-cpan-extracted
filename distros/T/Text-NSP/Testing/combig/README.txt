*******************************************************************************

		        README.txt FOR Testing combig.pl

                               Version 0.02
                         Copyright (C) 2002-2004
                       Ted Pedersen, tpederse@umn.edu
                    Amruta Purandare pura0010@d.umn.edu
                       University of Minnesota, Duluth

                   http://www.d.umn.edu/~tpederse/code.html


*******************************************************************************


Testing for combig.pl
------------------------

AMRUTA PURANDARE
pura0010@d.umn.edu
03/22/2004


1. Introduction: 
----------------

This program is a component of a SenseClusters package that combines bigrams
having same constituent words in reverse orders. The scripts and files 
provided here could be used to test the correct behaviour of the program and 
backward compatibility. 

2. Tests:
----------

2.1 Normal conditions:
----------------------

Tests written in testA*.sh test combig.pl under normal conditions.
Run normal-op.sh to run all test cases testA*.sh 

Test A1  :	Tests combig for a normal output of count.pl

Test A2  :	Tests combig for extended output of count.pl

Test A3  :	Tests combig when all bigrams occur in both orders

Test A4  :	Tests combig on a directed bipartite graph

Test A5  :	Tests combig on a directed cyclic graph

Test A6  :	Test added during version 0.02 to test the correctness
		of the new data structure

2.2 Error conditions:
---------------------

Tests written in testB*.sh test combig.pl under error conditions.
Run error-op.sh to run all test cases testB*.sh

Test B1 :	Tests combig when input comes from statistics.pl

Test B2 :	Tests combig when input comtains trigrams

Test B3 :	Tests combig when input doesnt contain total number of 
		bigrams

3. Conclusions:
---------------

We have tested program combig.pl enough to conclude that it runs correctly.
We have also provided the test scripts so that future versions of 
combig.pl can be compared to the current version against these scripts.
