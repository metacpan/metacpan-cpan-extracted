#!/usr/bin/perl
use File::Basename qw(dirname);
use lib dirname($0)."/../lib";

use strict;
use warnings;
use Test::Trivial tests => 6;

    my $string = "abc";
    TODO ISNT $string => "abc";
    # output:
    # # Time: 2012-02-28 01:45:18 PM
    # ./example.t:2:1: Test 1 Failed
    # not ok 1 - $string != "abc"
    # #   Failed test '$string != "abc"'
    # #          got: 'abc'
    # #     expected: anything else
    
    my @array = (1,2,3);
    TODO ISNT @array => 3;
    # output: 
    # # Time: 2012-02-28 01:45:18 PM
    # ./example.t:12:1: Test 2 Failed
    # not ok 2 - @array != 3
    # #   Failed test '@array != 3'
    # #          got: '3'
    # #     expected: anything else
    
    ISNT "a\nb" => "a\nc";
    # output:
    # ok 3 - "a\nb" != "a\nc"
    
    TODO ISNT [1,2,3,5,8], [1,2,3,5,8];
    # output: 
    # not ok 4 - [1,2,3,5,8] != [1,2,3,5,8]
    # #   Failed test '[1,2,3,5,8] != [1,2,3,5,8]'
    
    ISNT [{a=>1}], [{b=>1}];
    # output: 
    # ok 5 - [{a=>1}] != [{b=>1}]
    
    TODO ISNT substr("abcdef",0,3), "abc";
    # output:
    # # Time: 2012-02-28 01:45:18 PM
    # ./example.t:34:1: Test 6 Failed
    # not ok 6 - substr("abcdef",0,3) != "abc"
    # #   Failed test 'substr("abcdef",0,3) != "abc"'
    # #          got: 'abc'
    # #     expected: anything else
