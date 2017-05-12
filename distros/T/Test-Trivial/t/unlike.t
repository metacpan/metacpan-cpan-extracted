#!/usr/bin/perl
use File::Basename qw(dirname);
use lib dirname($0)."/../lib";

use strict;
use warnings;
use Test::Trivial tests => 5;

    UNLIKE "abc" => qr{^A};
    # output:
    # ok 1 - "abc" !~ qr{^A}
    
    TODO UNLIKE "ABC" => qr{^a}i;
    # output:
    # # Time: 2012-02-28 03:54:31 PM
    # ./example.t:5:1: Test 2 Failed
    # not ok 2 - "ABC" !~ qr{^a}i
    # #   Failed test '"ABC" !~ qr{^a}i'
    # #                   'ABC'
    # #           matches '(?i-xsm:^a)'
    
    TODO UNLIKE "ABC" => qr/^(?i:a)/;
    # output:
    # # Time: 2012-02-28 03:54:31 PM
    # ./example.t:14:1: Test 3 Failed
    # not ok 3 - "ABC" !~ qr/^(?i:a)/
    # #   Failed test '"ABC" !~ qr/^(?i:a)/'
    # #                   'ABC'
    # #           matches '(?-xism:^(?i:a))'
    
    use Regexp::Common;
    TODO UNLIKE "123.456E3" => qr[$RE{num}{int}];
    # output:
    # # Time: 2012-02-28 03:54:31 PM
    # ./example.t:24:1: Test 4 Failed
    # not ok 4 - "123.456E3" !~ qr[$RE{num}{int}]
    # #   Failed test '"123.456E3" !~ qr[$RE{num}{int}]'
    # #                   '123.456E3'
    # #           matches '(?-xism:(?:(?:[+-]?)(?:[0123456789]+)))'
    
    UNLIKE "foo" => qr{bar};
    # output:
    # ok 5 - "foo" !~ qr{bar}
