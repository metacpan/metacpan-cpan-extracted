*******************************************************************************

		        README.txt FOR Testing filter.pl

                               Version 0.11
                         Copyright (C) 2002-2004
                       Ted Pedersen, tpederse@umn.edu
                    Amruta Purandare amruta@cs.pitt.edu
                       University of Minnesota, Duluth

*******************************************************************************


Testing for filter.pl
----------------------

AMRUTA PURANDARE
amruta@cs.pitt.edu
05/07/2003


1. Introduction: 
----------------

This program is a component of a SenseClusters package that filters data by
removing Low frequency sense tags. The scripts and files provided here could 
be used to test the correct behaviour of the program and backward compatibility. 
Tests:
========

These test scripts are written in the files testA*.sh.

2.1.1 Tests A1: 
-----------------
Checks filter.pl's --rank R filter to select Top R most frequent
senses.

------
Data			=> test-A1.data
------

-----------------
Frequency Report 	=> test-A1.report
-----------------

--------------
Filtered Data 		=> test-A1.reqd
--------------

2.1.2 Tests A2:
-----------------
Checks filter.pl's default filter (percent=1% to remove senses
occurring below 1%) when no Filters are selected.
 
------
Data                    => test-A2.data
------

-----------------
Frequency Report        => test-A2.report
-----------------

--------------
Filtered Data           => test-A2.reqd
--------------

2.1.3 Tests A3:
-----------------
Checks filter.pl's --percent P filter to select senses with frequency
P% or more.

------
Data                    => test-A3.data
------

-----------------
Frequency Report        => test-A3.report
-----------------

--------------
Filtered Data           => test-A3.reqd
--------------

2.1.4 Tests A4:
-----------------
Checks the boundary condition on --percent option

------
Data                    => test-A4.data
------

-----------------
Frequency Report        => test-A4.report
-----------------

--------------
Filtered Data           => test-A4.reqd
--------------

2.1.5 Tests A5:
-----------------
Checks filter.pl's --rank R filter when there are ties on frequency
ranks at or below R.

------
Data                    => test-A5.data
------

-----------------
Frequency Report        => test-A5.report
-----------------

--------------
Filtered Data           => test-A5.reqd
--------------

2.1.6 Tests A6:
-----------------
Checks filter.pl when extra tags appear in data.

------
Data                    => test-A6.data
------

-----------------
Frequency Report        => test-A6.report
-----------------

--------------
Filtered Data           => test-A6.reqd
--------------

2.1.7 Tests A7:
-----------------
Checks filter.pl when corresponding count file is given.

------
Data                    => test-A7.data
------

-----------------
Frequency Report        => test-A7.report
-----------------

------
Count 			=> test-A7.count
------

--------------
Filtered Data           => test-A7.reqd
--------------

---------------
Filtered Count 		=> test-A7.count.reqd
---------------

2.1.8 Tests A8:
-----------------
Checks the condition in filter.pl when a sense tag in the data file is not 
listed in the Frequency Report

------
Data                    => test-A8.data
------

-----------------
Frequency Report        => test-A8.report
-----------------

2.1.9 Tests A9:
-----------------
Checks filter.pl's --nomulti option

------
Data                    => test-A9.data
------

-----------------
Frequency Report        => test-A9.report
-----------------

2.1.10 Tests A10:
-----------------
Checks filter.pl when count file is given and nomulti is
selected..

------
Data                    => test-A10.data
------

-----------------
Frequency Report        => test-A10.report
-----------------

-------
Count                   => test-A10.count
-------

---------------
Filtered Count          => test-A10.count.reqd
---------------

2.1.11 Tests A11:
-----------------
Checks filter.pl's default filter (percent=1% to remove senses occurring below
1%) when no Filters are selected but --nomulti is chosen.

------
Data                    => test-A11.data
------

-----------------
Frequency Report        => test-A11.report
-----------------

2.1.12 Tests A12:
-----------------
Checks when percent is set to 0 and nomulti is selected.

------
Data                    => test-A12.data
------

-----------------
Frequency Report        => test-A12.report
-----------------


2.1.13 Tests A13:
-----------------
Checks when percent is set to 0 and count and nomulti are used.

------
Data                    => test-A13.data
------

-----------------
Frequency Report        => test-A13.report
-----------------

-------
Count                   => test-A13.count
-------

2.2 Phase B: Testing filter.pl's behaviour under error conditions.
-------------------------------------------------------------------

The scripts wrtitten to test the error conditions are in testB*.sh files.

2.2.1 Tests B1:
-----------------
Checks the error condition in filter.pl when both --percent and --rank are 
selected.

------
Data                    => test-B1.data
------

-----------------
Frequency Report        => test-B1.report
-----------------

--------------
Filtered Data           => test-B1.reqd
--------------

2.2.2 Tests B2:
-----------------
Checks the error condition in filter.pl when Frequency Report doesn't
follow the required format.

------
Data                    => test-B2.data
------

-----------------
Frequency Report        => test-B2.report
-----------------

--------------
Filtered Data           => test-B2.reqd
--------------

--------------
3. Conclusions:
---------------

We have tested program filter.pl and conclude that it runs correctly.
We have also provided the test scripts so that future versions of 
filter.pl can be compared to the current version against these scripts.

