#!/usr/bin/perl

use strict;
use warnings;

my $package = 'Test::MockObject';
use Test::More tests => 3;
use_ok( $package );

my $mock = Test::MockObject->new();

$mock->mock(
    foo => sub { 'foo' },
    bar => sub { 'bar' },
);

is( $mock->foo(), 'foo', 'mock one in multi-mock' );
is( $mock->bar(), 'bar', 'mock two in multi-mock' );
