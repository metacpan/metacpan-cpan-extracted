#!/usr/bin/perl

use strict;
use warnings;

use Test::Builder::Tester tests => 3;
use Test::More;
use Test::NoWarnings;

use lib 'lib';
use_ok( 'Test::UniqueTestNames', qw/ had_unique_test_names /);

my $expected_output = 'ok 1 - The object isa Foo
ok 2 - The object isa Foo
ok 3 - The object isa Foo
ok 4 - all test names unique';

test_out( $expected_output );

my @data = (bless( [], 'Foo' )) x 3;
isa_ok( $_, 'Foo' ) for @data;

had_unique_test_names();
test_test( "passes when there are multiple isa_oks, since isa_ok creates its own test name" );
