#!/usr/bin/perl
use File::Basename qw(dirname);
use lib dirname($0)."/../lib";

use strict;
use warnings;
use Test::Trivial tests => 6;

    my $string = "abc";
    IS $string => "abc";
    # output:
    # ok 1 - $string == "abc"
    
    my @array = (1,2,3);
    IS @array => 3;
    # output: 
    # ok 2 - @array == 3
    
    TODO IS "a\nb\n" => "a\nc\n";
    # output:
    # # Time: 2012-02-28 01:27:33 PM
    # ./example.t:10:1: Test 3 Failed
    # not ok 3 - "a\nb\n" == "a\nc\n"
    # #   Failed test '"a\nb\n" == "a\nc\n"'
    # # --- got
    # # +++ expected
    # # @@ -1,2 +1,2 @@
    # #  a
    # # -b
    # # +c
    
    IS [1,2,3,5,8], [1,2,3,5,8];
    # output: 
    # ok 4 - [1,2,3,5,8] == [1,2,3,5,8]
    
    TODO IS [{a=>1}], [{b=>1}];
    # output: 
    # # Time: 2012-02-28 01:27:33 PM
    # ./example.t:26:1: Test 5 Failed
    # not ok 5 - [{a=>1}] == [{b=>1}]
    # #   Failed test '[{a=>1}] == [{b=>1}]'
    # #     Structures begin differing at:
    # #          $got->[0]{b} = Does not exist
    # #     $expected->[0]{b} = '1'
    
    IS substr("abcdef",0,3), "abc";
    # output:
    # ok 6 - substr("abcdef",0,3) == "abc"
