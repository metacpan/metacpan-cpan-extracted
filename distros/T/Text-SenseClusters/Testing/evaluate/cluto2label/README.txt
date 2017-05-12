*******************************************************************************

                     README.txt FOR cluto2label.pl Testing

                               Version 0.13
                         Copyright (C) 2002-2004
                       Ted Pedersen, tpederse@umn.edu
                    Amruta Purandare amruta@cs.pitt.edu
                       University of Minnesota, Duluth

*******************************************************************************
Unit Testing of
cluto2label.pl
-------------

AMRUTA PURANDARE
amruta@cs.pitt.edu
11/21/2003

Introduction:
----------------

The scripts provided here test the behaviour of cluto2label.pl program under
various normal and error conditions.

Tests:
-------
The test scripts are written in the files testA*.sh

Tests A1-4 run cluto2label for various cluto solutions and keys. 
Test A5 tests when some instances are not clustered
Test A6 tests cluto2label when --numthrow is specified
Test A7 tests cluto2label when --perthrow is specified

Conclusions:
---------------

We have tested the cluto2label.pl program enough and say that it behaves
according to our expectations. The test scripts could also be used to check the
backward compatibility when the program is enhanced in future.

