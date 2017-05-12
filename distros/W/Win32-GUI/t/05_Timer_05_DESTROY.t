#!perl -wT
# Win32::GUI test suite.
# $Id: 05_Timer_05_DESTROY.t,v 1.2 2006/05/16 18:57:26 robertemay Exp $
#
# test coverage of Timers

use strict;
use warnings;

BEGIN { $| = 1 } # Autoflush

use Test::More tests => 11;

use Win32::GUI();

my $ctrl = "Timer";
my $class = "Test::$ctrl";

my $elapse = 500; # ms

# Test DESTRUCTION
{
	my $W = new Win32::GUI::Window(
	    -name => "TestWindow",
	);
	my $C = Test::Timer->new($W, 'T1', $elapse);

	# DESTROY tests
	is($Test::Timer::x, 0, "DESTROY not called yet");
	undef $C; # should still be a reference from the parent object
	is($Test::Timer::x, 0, "DESTROY not called yet");
	undef $W; # should reduce ref count to parent to zero, and in turn Timer
	is($Test::Timer::x, 1, "DESTROY called when parent destroyed");
}

{
	my $W = new Win32::GUI::Window(
	    -name => "TestWindow",
	);
	my $C = Test::Timer->new($W, 'T1', $elapse);

	my $id = $C->{-id};
	ok(defined $W->{-timers}->{$id}, "Timer's id is stored in parent");
	is($C, $W->T1, "Reference sotered in Parent");
	
	# DESTROY tests
	$Test::Timer::x = 0;
	is($Test::Timer::x, 0, "DESTROY not called yet");
	undef $C; # should still be a reference from the parent object
	is($Test::Timer::x, 0, "DESTROY not called yet");
	$W->{T1} = undef; # naughty way to remove timer
	is($Test::Timer::x, 1, "DESTROY called when parent reference removed");
	ok(!defined $W->{-timers}->{$id}, "DESTROY() tidies parent");
	ok(!defined $W->{T1}, "DESTROY() tidies parent");
	undef $W;
	is($Test::Timer::x, 1, "DESTROY not called when parent destroyed");
}

package Test::Timer;
our (@ISA, $x);

BEGIN {
	@ISA = qw(Win32::GUI::Timer);
	$x = 0;
}

sub DESTROY
{
	++$x;
	shift->SUPER::DESTROY();
}

