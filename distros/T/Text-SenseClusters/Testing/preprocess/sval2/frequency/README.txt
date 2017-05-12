*******************************************************************************

		        README.txt FOR Testing frequency.pl

                               Version 0.11
                         Copyright (C) 2002-2004
                       Ted Pedersen, tpederse@umn.edu
                    Amruta Purandare amruta@cs.pitt.edu
                       University of Minnesota, Duluth

*******************************************************************************


Testing for frequency.pl
----------------------

AMRUTA PURANDARE
amruta@cs.pitt.edu
05/07/2003


1. Introduction: 
----------------

This program is a component of a SenseClusters package which displays Sense
frequency distribution for a given file. The scripts and files 
provided here could be used to test the correct behaviour of the program and 
backward compatibility. 

Tests:
========

These test scripts are written in the files testA*.sh.

2.1 Tests A1: 
-----------------
Testing frequency.pl when Source has balanced distribution.
------
INPUT			=> test-A1.source
------

--------------
EXPECTED OUTPUT		=> test-A1.reqd
--------------
 
2.2. Test A2:
-----------------
Testing frequency.pl when Source has only one sense(100%).

------
INPUT                   => test-A2.source
------

--------------
EXPECTED OUTPUT         => test-A2.reqd
--------------

2.3. Test A3:
-----------------
Testing frequency.pl when Source has 2 senses in ratio(66:33)
------
INPUT                   => test-A3.source
------

--------------
EXPECTED OUTPUT         => test-A3.reqd
--------------

2.4. Tests A4:
-----------------
Testing frequency.pl when Source is a part of actual Senseval-2.

------
INPUT                   => test-A4.source
------

--------------
EXPECTED OUTPUT         => test-A4.reqd
--------------

2.5. Tests A5:
-----------------
Testing frequency.pl when Source is a part of actual Senseval-2 And single
sense tag occurs.

------
INPUT                   => test-A5.source
------

--------------
EXPECTED OUTPUT         => test-A5.reqd
--------------

There are no special error checks in this program and hence aren't 
tested using formal test scripts.

3. Conclusions:
---------------

We have tested program frequency.pl and conclude that it runs correctly.
We have also provided the test scripts so that future versions of 
frequency.pl can be compared to the current version against these scripts.

