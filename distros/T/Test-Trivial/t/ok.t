#!/usr/bin/perl
use File::Basename qw(dirname);
use lib dirname($0)."/../lib";

use strict;
use warnings;
use Test::Trivial tests => 4;

    OK 1 + 1 == 2;
    # output:
    # ok 1 - 1 + 1 == 2
    
    TODO OK 1 + 1 == 3;
    # output:
    # # Time: 2012-02-28 12:20:19 PM
    # ./example.t:5:1: Test 2 Failed
    # not ok 2 - 1 + 1 == 3
    # #   Failed test '1 + 1 == 3'
    
    my @array = (1,2,3);
    OK @array;
    # output:
    # ok 3 - @array
    
    @array = ();
    TODO OK @array;
    # output:
    # # Time: 2012-02-28 12:20:19 PM
    # ./example.t:18:1: Test 4 Failed
    # not ok 4 - @array
    # #   Failed test '@array'
