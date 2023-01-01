#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 3;

use_ok('Test::Named');

exit main( @ARGV );

sub test_foo {
    ok(1==1,'Test Foo');
}

sub test_bar {
    ok(1==1,'Test Bar');
}

