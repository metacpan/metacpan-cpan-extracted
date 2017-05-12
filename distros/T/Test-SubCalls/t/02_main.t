#!/usr/bin/perl

# Main testing for Test::SubCalls

use strict;
BEGIN {
	$| = 1;
	$^W = 1;
}
use File::Spec::Functions ':ALL';

# Set up
use Test::Builder::Tester tests => 18;
use Test::More;
use Test::SubCalls;

# Until CPAN #14389 is fixed, create a false HARNESS_ACTIVE value
# if it doesn't exists to prevent a warning in test_test.
$ENV{HARNESS_ACTIVE} ||= 0;




# Set up the tracking
my $rv = undef;
eval { $rv = sub_track('Foo::foo'); };
is( $rv, 1, 'Set up tracking for Foo::foo ok' );
is( $@, '', "Set up for Foo::foo didn't die" );
$rv = undef;
eval { $rv = sub_track('Foo::bar'); };
is( $rv, 1, 'Set up tracking for Foo::bar ok' );
is( $@, '', "Set up for Foo::bar didn't die" );
$rv = undef;
eval { $rv = sub_track('Foo::baz'); };
is( $rv, undef, 'Failed to set up tracking for Foo::baz' );
like( $@, qr/^Test::SubCalls::sub_track : The sub 'Foo::baz' does not exist/,
	"Set up for Foo::baz died" );

# Does a normal setup and run work
test_out("ok 1 - Foo::bar was called 0 times");
test_out("ok 2 - Foo::foo was called 2 times");
test_out("ok 3 - Custom message");
test_out("ok 4 - Foo::bar was called 1 times");
sub_calls('Foo::bar', 0);
Foo::foo();
Foo::foo();
Foo::bar();
sub_calls('Foo::foo', 2);
sub_calls('Foo::foo', 2, 'Custom message' );
sub_calls('Foo::bar', 1);
test_test('Good tracking passes');

# Test incorrect value
test_out("not ok 1 - Foo::foo was called 3 times");
test_fail(+3);
test_err("#          got: 2");
test_err("#     expected: 3");
sub_calls('Foo::foo', 3);
test_test('Bad tracking fails');

# Test nonexistant value
$rv = undef;
eval { $rv = sub_calls('Foo::baz'); };
is( $rv, undef, 'Failed to check calls for Foo::baz' );
like( $@, qr/^Test::SubCalls::sub_calls : Cannot test untracked sub 'Foo::baz'/,
	"Call check for Foo::baz died" );

# Reset bad
$rv = undef;
eval { $rv = sub_reset('Foo::baz'); };
is( $rv, undef, 'Failed to check calls for Foo::baz' );
like( $@, qr/^Test::SubCalls::sub_reset : Cannot reset untracked sub 'Foo::baz'/,
	"Call check for Foo::baz died" );

# Reset single good
$rv = sub_reset('Foo::foo');
ok( $rv, 'sub_reset returns true' );
sub_calls('Foo::foo', 0, 'sub_reset actually resets sub count');

# Reset multiple good
Foo::foo();
sub_calls('Foo::foo', 1, 'Set Foo::foo back to 1 for sub_reset_all test');
$rv = sub_reset_all();
is( $rv, 1, 'sub_reset_all returns true' );
sub_calls('Foo::foo', 0, 'sub_reset_all actually resets sub count');
sub_calls('Foo::bar', 0, 'sub_reset_all actually resets sub count');





#####################################################################
# Test Package

package Foo;

sub foo { 1 }
sub bar { 1 }

1;
