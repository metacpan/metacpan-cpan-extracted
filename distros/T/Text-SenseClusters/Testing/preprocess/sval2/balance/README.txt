*******************************************************************************

                        README.txt FOR balance.pl Testing

                               Version 0.11
                         Copyright (C) 2002-2004
                       Ted Pedersen, tpederse@umn.edu
                    Amruta Purandare amruta@cs.pitt.edu
                       University of Minnesota, Duluth

*******************************************************************************
Unit Testing of
balance.pl
-----------

AMRUTA PURANDARE
amruta@cs.pitt.edu
05/03/2003

Introduction:
----------------

The scripts provided here test the behaviour of balance.pl program under
various normal and error conditions.

Tests:
-------
The test scripts are written in the files testA*.sh

Tests A[1-7] run and test balance.pl by selecting different number of instances
from different XML files. 

TestA8 tests balance.pl when --count option is selected and count file is to be
updated along with XML file.

Error conditions in balance.pl are fairly trivial and hence are not tested 
using formal test scripts.

Conclusions:
---------------

We have tested the balance.pl program enough and say that it behaves
according to our expectations. The test scripts could also be used to check the
backward compatibility when the program is enhanced in future.

