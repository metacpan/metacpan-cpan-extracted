#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;

use_ok('Test::Named');

diag('test_bar should be ignored');
exit main( 'foo' );

sub test_foo {
    ok(1==1,'Test Foo');
}

sub test_bar {
    ok(1==1,'Test Bar');
}

