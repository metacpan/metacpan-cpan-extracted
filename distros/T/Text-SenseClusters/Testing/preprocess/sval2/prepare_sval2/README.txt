*******************************************************************************

	   	     README.txt FOR Testing prepare_sval2.pl

                               Version 0.11
                         Copyright (C) 2002-2004
                       Ted Pedersen, tpederse@umn.edu
                    Amruta Purandare amruta@cs.pitt.edu
                       University of Minnesota, Duluth

*******************************************************************************


Testing for prepare_sval2.pl
--------------------------

AMRUTA PURANDARE
amruta@cs.pitt.edu
05/07/2003


1. Introduction: 
----------------

This program is a component of a SenseClusters package which preprocesses
Senseval-2 Data. The scripts and files provided here could be used to test 
the correct behaviour of the program and backward compatibility. 

2. Tests:
==========

Tests which check behaviour of prepare_sval2.pl under normal conditions are Type A
tests.

Tests which check behaviour of prepare_sval2.pl under error conditions are Type B
tests.

2.1 TYPE A :
------------
These test scripts are written in the files testA*.sh.

2.1.1 Tests A1: 
-----------------
Testing if P tags are getting removed.

------
INPUT			=> test-A1.data
------

--------------
EXPECTED OUTPUT		=> test-A1.reqd
--------------
 
2.1.2. Test A2:
-----------------
Testing if attach_P is working.
------
INPUT                   => test-A2.data
------

--------------
EXPECTED OUTPUT         => test-A2.reqd
--------------

2.1.3. Test A3:
-----------------
Testing if prepare_sval2 attaches NOTAGs when Input is untagged.
------
INPUT                   => test-A3.data
------

--------------
EXPECTED OUTPUT         => test-A3.reqd
--------------

2.1.4. Tests A4:
-----------------
Testing if prepare_sval2 attaches tags from KEY file.

------
INPUT                   => test-A4.data
------

--------------
EXPECTED OUTPUT         => test-A4.reqd
--------------

2.1.5. Tests A5:
-----------------
Testing when some instances do not have tags in KEY file.
------
INPUT                   => test-A5.data
------

--------------
EXPECTED OUTPUT         => test-A5.reqd
--------------

2.1.6. Tests A6:
-----------------
Testing when KEY file has tags for already tagged data.

------
INPUT                   => test-A6.data
------

--------------
EXPECTED OUTPUT         => test-A6.reqd
--------------

2.1.7. Tests A7:
-----------------
Testing when some instances are not attached any tag. 

------
INPUT                   => test-A7.data
------

--------------
EXPECTED OUTPUT         => test-A7.reqd
--------------

2.1.8. Tests A8:
-----------------
Testing when instances are tagged with single tag=P.
------
INPUT                   => test-A8.data
------

--------------
EXPECTED OUTPUT         => test-A8.reqd
--------------

2.2 TYPE B:
------------
These scripts are written in testB*.sh

2.2.1. Tests B1:
-----------------
Testing an error condition when data is partially tagged.
------
INPUT                   => test-B1.data
------

--------------
EXPECTED OUTPUT         => test-B1.reqd
--------------


3. Conclusions:
---------------
We have tested program prepare_sval2.pl and conclude that it runs correctly.
We have also provided the test scripts so that future versions of 
prepare_sval2.pl can be compared to the current version against these scripts.

