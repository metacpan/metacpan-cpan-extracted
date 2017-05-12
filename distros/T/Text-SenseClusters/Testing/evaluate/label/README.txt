******************************************************************************				
			README.txt for Testing label.pl			

				Version 0.13
                         Copyright (C) 2002-2004
                       Ted Pedersen, tpederse@umn.edu
                    Amruta Purandare amruta@cs.pitt.edu
                       University of Minnesota, Duluth

*****************************************************************************

Testing for label.pl
--------------------

AMRUTA PURANDARE
amruta@cs.pitt.edu

11/28/2004

1. Introduction: 
----------------

We test here label.pl program, a component from SenseClusters package
that labels clusters with sense tags. This README describes the aspects of 
the label.pl we tested. The scripts and files provided here could be used 
to test the correct behaviour of the program and backward compatibility. 

2. Phases of Testing: 
---------------------

We have divided the testing into two main phases: 

Phase A: Testing label.pl's behaviour under normal conditions. 
Phase B: Testing label.pl's response to erroneous conditions. 


2.1. Phase A: Testing label.pl's behaviour under normal conditions. 
-------------------------------------------------------------------

These scripts are written in testA*.sh

Tests written in files TestA1* test label.pl when #clusters = #labels

Tests written in files TestA2* test label.pl when #clusters < #labels

Tests written in files TestA3* test label.pl when #clusters > #labels

Test written in file testA4.sh tests label.pl when #clusters=25 and #labels=25

2.2 Phase B: Testing label.pl's behaviour under error conditions.
---------------------------------------------------------------

These scripts are written in testB*.sh

Test B1:	Input file doesn't start with number of unclustered instances.

Test B2:	When the Sense List on the 2nd line of input file 
		doesn't start with //

3. Conclusions:
---------------

We have tested program label.pl and conclude that it runs correctly. 
We have also provided the test scripts so that future versions of label.pl 
can be compared to the current version against these scripts.

