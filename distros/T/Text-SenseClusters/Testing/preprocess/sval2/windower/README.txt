*******************************************************************************

		        README.txt FOR Testing windower.pl

                               Version 0.05
                         Copyright (C) 2002-2004
                       Ted Pedersen, tpederse@umn.edu
                    Amruta Purandare amruta@cs.pitt.edu
                       University of Minnesota, Duluth

*******************************************************************************


Testing for windower.pl
------------------------

AMRUTA PURANDARE
amruta@cs.pitt.edu
12/08/2003


1. Introduction: 
----------------

This program is a component of a SenseClusters package that displays tokens 
within the specified window around the target word. The scripts and files 
provided here could be used to test the correct behaviour of the program and 
backward compatibility. 

2. Tests:
----------

2.1 Normal conditions:
----------------------

Tests written in testA*.sh test windower.pl under normal conditions.

Test A1 :	Tests windower 
		1. on default target and token regex files
		2. when context has less than W words on left/right 
		3. when some contexts cross line boundaries 
		4. when context includes some non-token characters
		
Test A2 :	Tests windower on a special tokenization scheme for POS 
		tagged data

Test A3 :	Tests windower when token definitions include punctuations

Test A4 :	Same as A1 but --plain is ON

Test A5 :	Same as A2 with --plain ON

2.2 Error conditions:
---------------------

Tests written in testB*.sh test windower.pl under error conditions.

Test B1 :	Tests windower when <context> tag is found without
		corresponding <instance> tag after last </instance>

Test B2 :	Tests windower when target word is missing in some contexts

3. Conclusions:
---------------

We have tested program windower.pl enough to conclude that it runs correctly.
We have also provided the test scripts so that future versions of 
windower.pl can be compared to the current version against these scripts.

