*******************************************************************************

	               README.txt FOR Integration Testing of 
			NSP programs count.pl and statistic.pl
				with kocos.pl

                               Version 0.05
                         Copyright (C) 2002-2004
                       Ted Pedersen, tpederse@umn.edu
                    Amruta Purandare pura0010@d.umn.edu
                       University of Minnesota, Duluth

                   http://www.d.umn.edu/~tpederse/nsp.html


*******************************************************************************


Integration Testing 
for count.pl,statistic.pl
with kocos.pl
--------------------

AMRUTA PURANDARE
pura0010@d.umn.edu
07/03/2003

1. Introduction: 
----------------

The scripts provided here test the i/o compatibility between 
NSP programs (count,statistic) and kocos program.

Tests:
========

A single test script written as integration.sh runs the following tests 
which check compatibility of kocos.pl with count.pl and statistic.pl

2.1 Tests A1: 
-----------------
Tests the compatibility when count output is normal.  

------
INPUT			=> test-A1.in 
------

----------------
INTERMEDIATE o/p	=> test-A1.out
----------------

--------------
EXPECTED OUTPUT		 
--------------			order 1 => test-A1a.reqd
				order 2 => test-A1b.reqd
				order 3 => test-A1c.reqd 
				order 4 => test-A1d.reqd
				

2.2. Test A2:
-----------------
Tests the compatibility when count output is extended.

------
INPUT                   => test-A2.in
------

----------------
INTERMEDIATE o/p        => test-A2.out
----------------

--------------
EXPECTED OUTPUT
--------------                  order 1 => test-A2a.reqd
                                order 2 => test-A2b.reqd
                                order 3 => test-A2c.reqd
                                order 4 => test-A2d.reqd
                             
2.3. Test A3:
-----------------
Tests the compatibility when statistic output is used for kocos.

------
INPUT                   => test-A3.in
------

----------------
INTERMEDIATE o/p        => test-A3.count test-A3.out
----------------

--------------
EXPECTED OUTPUT
--------------                  order 1 => test-A3a.reqd
                                order 2 => test-A3b.reqd
                                order 3 => test-A3c.reqd
                                order 4 => test-A3d.reqd
                               


3. Conclusions:
---------------

We have tested programs count.pl and statistic.pl with kocos.pl for their i/o 
compatibilities and conclude that they run correctly.
