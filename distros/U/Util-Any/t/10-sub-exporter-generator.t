package main;

use strict;
use lib qw(lib t/lib);
use SubExporterGenerator -test => [min => {-as => "min_under_20", under => 20},
    			       	   min => {-as => "min_under_5", under => 5},
                                   max => {-as => "max_upper_100", upper => 100},
				   uniq => {-as => 'uniq'},
				   ];
use Test::More 'no_plan';

is(min_under_20(100,25,30), 20);
is(min_under_20(100,10,30), 10);
is(min_under_5(100,50,40), 5);
is(min_under_5(100,1,40), 1);
is(max_upper_100(80,25,30), 100);
is(max_upper_100(130,10,30), 130);
is(scalar uniq(1,3,1,4,5,1), 4);