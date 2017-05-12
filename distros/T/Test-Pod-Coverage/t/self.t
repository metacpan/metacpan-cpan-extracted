#!perl -T

use lib "t";
use strict;
use Test::Pod::Coverage tests=>1;

pod_coverage_ok( "Test::Pod::Coverage", "T:P:C itself is OK" );
