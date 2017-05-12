#!/usr/bin/perl
use File::Basename qw(dirname);
use lib dirname($0)."/../lib";

use strict;
use warnings;
use Test::Trivial tests => 9;

    TODO OK 1 == 2;
    # output:
    # # Time: 2012-02-28 04:39:55 PM
    # ./example.t:1:6: Test 1 Failed
    # not ok 1 - 1 == 2 # TODO Test Know to fail
    # #   Failed (TODO) test '1 == 2'
    
    TODO NOK 1 == 1;
    # output:
    # # Time: 2012-02-28 04:39:55 PM
    # ./example.t:8:6: Test 2 Failed
    # not ok 2 - not [1 == 1] # TODO Test Know to fail
    # #   Failed (TODO) test 'not [1 == 1]'
    
    TODO IS "abc" => "ABC";
    # output:
    # # Time: 2012-02-28 04:39:55 PM
    # ./example.t:15:6: Test 3 Failed
    # not ok 3 - "abc" == "ABC" # TODO Test Know to fail
    # #   Failed (TODO) test '"abc" == "ABC"'
    # #          got: 'abc'
    # #     expected: 'ABC'
    
    TODO ISNT "abc" => "abc";
    # output:
    # # Time: 2012-02-28 04:39:55 PM
    # ./example.t:24:6: Test 4 Failed
    # not ok 4 - "abc" != "abc" # TODO Test Know to fail
    # #   Failed (TODO) test '"abc" != "abc"'
    # #          got: 'abc'
    # #     expected: anything else
    
    TODO ISA [] => "HASH";
    # output:
    # # Time: 2012-02-28 04:39:55 PM
    # ./example.t:33:6: Test 5 Failed
    # not ok 5 - [] ISA "HASH" # TODO Test Know to fail
    # #   Failed (TODO) test '[] ISA "HASH"'
    
    TODO ID [] => [];
    # output:
    # # Time: 2012-02-28 04:39:55 PM
    # ./example.t:40:6: Test 6 Failed
    # not ok 6 - [] == [] # TODO Test Know to fail
    # #   Failed (TODO) test '[] == []'
    # #          got: 'ARRAY(0x1c62a28)'
    # #     expected: 'ARRAY(0x1c62a10)'
    
    TODO EQ 123 => 124;
    # output:
    # # Time: 2012-02-28 04:39:55 PM
    # ./example.t:49:6: Test 7 Failed
    # not ok 7 - 123 == 124 # TODO Test Know to fail
    # #   Failed (TODO) test '123 == 124'
    # #          got: '123'
    # #     expected: '124'
    
    TODO LIKE "abc" => qr/^ABC$/;
    # output:
    # # Time: 2012-02-28 04:39:55 PM
    # ./example.t:58:6: Test 8 Failed
    # not ok 8 - "abc" =~ qr/^ABC$/ # TODO Test Know to fail
    # #   Failed (TODO) test '"abc" =~ qr/^ABC$/'
    # #                   'abc'
    # #     doesn't match '(?-xism:^ABC$)'
    
    TODO UNLIKE "abc" => qr/^abc$/;
    # output:
    # # Time: 2012-02-28 04:39:55 PM
    # ./example.t:67:6: Test 9 Failed
    # not ok 9 - "abc" !~ qr/^abc$/ # TODO Test Know to fail
    # #   Failed (TODO) test '"abc" !~ qr/^abc$/'
    # #                   'abc'
    # #           matches '(?-xism:^abc$)'
