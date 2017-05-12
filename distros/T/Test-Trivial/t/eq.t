#!/usr/bin/perl
use File::Basename qw(dirname);
use lib dirname($0)."/../lib";

use strict;
use warnings;
use Test::Trivial tests => 14;

    EQ 12 => 12;
    # output:
    # ok 1 - 12 == 12
    
    TODO EQ 12.00001 => 12;
    # output:
    # # Time: 2012-02-28 03:16:49 PM
    # ./example.t:4:1: Test 2 Failed
    # not ok 2 - 12.00001 == 12
    # #   Failed test '12.00001 == 12'
    # #          got: '12.00001'
    # #     expected: '12'
    
    EQ 12.0 => 12;
    # output:
    # ok 3 - 12.0 == 12
    
    EQ 12.0 / 1.0 => 12;
    # output:
    # ok 4 - 12.0 / 1.0 == 12
    
    EQ 0.12E2 => 12;
    # output:
    # ok 5 - 0.12E2 == 12
    
    EQ 1200E-2 => 12;
    # output:
    # ok 6 - 1200E-2 == 12
    
    EQ 0x0C => 12;
    # output:
    # ok 7 - 0x0C == 12
    
    EQ 014 => 12;
    # output:
    # ok 8 - 014 == 12
    
    EQ 0b001100 => 12;
    # output:
    # ok 9 - 0b001100 == 12
    
    EQ "12" => 12;
    # output:
    # ok 10 - "12" == 12
    
    EQ "12.0" => 12;
    # output:
    # ok 11 - "12.0" == 12
    
    EQ "0.12E2" => 12;
    # output:
    # ok 12 - "0.12E2" == 12
    
    EQ "1200E-2" => 12;
    # output:
    # ok 13 - "1200E-2" == 12

    EQ "12 Monkeys" => 12;
    # output:
    # ok 14 - "12 Monkeys" == 12
