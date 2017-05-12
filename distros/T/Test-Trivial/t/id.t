#!/usr/bin/perl
use File::Basename qw(dirname);
use lib dirname($0)."/../lib";

use strict;
use warnings;
use Test::Trivial tests => 5;

    my $arr1 = my $arr2 = [];
    ID $arr1 => $arr2;
    # output:
    # ok 1 - $arr1 == $arr2
    
    TODO ID $arr1 => [];
    # output:
    # # Time: 2012-02-28 02:35:38 PM
    # ./example.t:6:1: Test 2 Failed
    # not ok 2 - $arr1 == []
    # #   Failed test '$arr1 == []'
    # #          got: 'ARRAY(0x186fd80)'
    # #     expected: 'ARRAY(0x188c588)'
    
    my $hash1 = my $hash2 = {};
    ID $hash1 => $hash2;
    # output:
    # ok 3 - $hash1 == $hash2
    
    TODO ID $hash1 => {};
    # output:
    # # Time: 2012-02-28 02:35:38 PM
    # ./example.t:20:1: Test 4 Failed
    # not ok 4 - $hash1 == {}
    # #   Failed test '$hash1 == {}'
    # #          got: 'HASH(0x189bcc8)'
    # #     expected: 'HASH(0x1ee95b8)'
    
    my %hash = ();
    my $hash3 = \%hash;
    
    ID $hash3 => \%hash;
    # output:
    # ok 5 - $hash3 == \%hash
