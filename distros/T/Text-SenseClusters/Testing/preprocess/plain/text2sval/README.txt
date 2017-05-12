*******************************************************************************

		        README.txt FOR Testing text2sval.pl

                               Version 0.01
                         Copyright (C) 2002-2004
                       Ted Pedersen, tpederse@umn.edu
                    Amruta Purandare amruta@cs.pitt.edu
                       University of Minnesota, Duluth

*******************************************************************************


Testing for text2sval.pl
------------------------

AMRUTA PURANDARE
amruta@cs.pitt.edu
12/2/2003


1. Introduction: 
----------------

This program is a component of the SenseClusters package that converts a plain
text instance file into a Senseval-2 formatted XML file. The scripts and files 
provided here could be used to test the correct behaviour of the program and 
backward compatibility. 

2. Tests:
----------

2.1 Normal conditions:
----------------------

Tests written in testA*.sh test text2sval.pl under normal conditions.

Test A1:	Tests text2sval when instance ids and sense tags of TEXT
		instances are provided in the KEY file

Test A2:	Tests text2sval when --key is not specified 

Test A3:	Tests text2sval when KEY file contains only the instance ids

Test A4:	Same as Test A1 but tested on Serve data

2.2 Error conditions:
---------------------

Tests written in testB*.sh test text2sval.pl under error conditions.

Test B1:	KEY file doesn't contain sufficient entries

Test B2:	KEY file contains extra entries

Test B3:	KEY file doesn't show instance tags

3. Conclusions:
---------------

We have tested program text2sval.pl enough to conclude that it runs correctly.
We have also provided the test scripts so that future versions of 
text2sval.pl can be compared to the current version against these scripts.

