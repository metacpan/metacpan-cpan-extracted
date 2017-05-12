#!/usr/bin/perl
use File::Basename qw(dirname);
use lib dirname($0)."/../lib";

use strict;
use warnings;
use Test::Trivial tests => 5;

    LIKE "abc" => qr{^a};
    # output:
    # ok 1 - "abc" =~ qr{^a}
    
    LIKE "ABC" => qr{^a}i;
    # output:
    # ok 2 - "ABC" =~ qr{^a}i
    
    LIKE "ABC" => qr/^(?i:a)/;
    # output:
    # ok 3 - "ABC" =~ qr/^(?i:a)/
    
    use Regexp::Common;
    LIKE "123.456E3" => qr[$RE{num}{real}];
    # output:
    # ok 4 - "123.456E3" =~ qr[$RE{num}{real}]
    
    TODO LIKE "foo" => qr{bar};
    # output:
    # # Time: 2012-02-28 03:44:35 PM
    # ./example.t:18:1: Test 5 Failed
    # not ok 5 - "foo" =~ qr{bar}
    # #   Failed test '"foo" =~ qr{bar}'
    # #                   'foo'
    # #     doesn't match '(?-xism:bar)'
