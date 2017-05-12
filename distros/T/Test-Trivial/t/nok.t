#!/usr/bin/perl
use File::Basename qw(dirname);
use lib dirname($0)."/../lib";

use strict;
use warnings;
use Test::Trivial tests => 4;

    TODO NOK 1 + 1 == 2;
    # output:
    # # Time: 2012-02-28 12:25:45 PM
    # ./example.t:1:1: Test 1 Failed
    # not ok 1 - not [1 + 1 == 2]
    # #   Failed test 'not [1 + 1 == 2]'
    
    NOK 1 + 1 == 3;
    # output:
    # ok 2 - not [1 + 1 == 3]
    
    my @array = (1,2,3);
    TODO NOK @array;
    # output:
    # # Time: 2012-02-28 12:25:45 PM
    # ./example.t:13:1: Test 3 Failed
    # not ok 3 - not [@array]
    # #   Failed test 'not [@array]'
    
    @array = ();
    NOK @array;
    # output:
    # ok 4 - not [@array]
