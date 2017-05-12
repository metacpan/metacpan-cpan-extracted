*******************************************************************************

		        README.txt FOR Testing keyconvert.pl

                               Version 0.01
                         Copyright (C) 2002-2004
                       Ted Pedersen, tpederse@umn.edu
                    Amruta Purandare amruta@cs.pitt.edu
                       University of Minnesota, Duluth

*******************************************************************************


Testing for keyconvert.pl
----------------------

AMRUTA PURANDARE
amruta@cs.pitt.edu
02/09/2003

1. Introduction: 
----------------

This program is a component of a SenseClusters package that converts a
Senseval2 Key file to equivalent SenseClusters Key file format. The scripts 
and files provided here could be used to test the correct behaviour of the 
program and backward compatibility. 

Tests:
======

These test scripts are written in the files testA*.sh.

2.1 Tests A1: 
-----------------
Tests program keyconvert.pl on sample keyfiles
------
INPUT			=> test-A1.keyin
------

--------------
EXPECTED OUTPUT		=> test-A1.keyout
--------------
 
2.2. Test A2:
-----------------
Tests program keyconvert.pl on actual Senseval keyfile.

------
INPUT                   => fine.key
------

Checks if the number of lines in fine.key and the file created by the 
keyconvert.pl match.

2.3. Test A3:
-----------------
Tests program keyconvert.pl when attach_P is set.

------
INPUT                   => test-A3.keyin
------

------
OUTPUT                   => test-A3.keyout
------

Checks if the number of lines in fine.key and the file created by the
keyconvert.pl match.

3. Conclusions:
---------------

We have tested program keyconvert.pl and conclude that it runs correctly.
We have also provided the test scripts so that future versions of keyconvert.pl 
can be compared to the current version against these scripts.

