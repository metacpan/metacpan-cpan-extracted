#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use_ok('Test::Named');

before_launch(sub { ok(1, 'Before Launch Executed') });
before_exit( sub { done_testing() });

exit main( );

sub test_foo {
    ok(1==1,'Test Foo');
}

sub test_bar {
    ok(1==1,'Test Bar');
}

