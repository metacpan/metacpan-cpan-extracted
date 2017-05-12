#!perl -wT
# Win32::GUI test suite.
# $Id: 05_Timer_03_Interval.t,v 1.3 2006/05/16 18:57:26 robertemay Exp $
#
# test coverage of Timers

use strict;
use warnings;

BEGIN { $| = 1 } # Autoflush

use Test::More tests => 11;

use Win32::GUI();

my $ctrl = "Timer";
my $class = "Win32::GUI::$ctrl";

my $elapse = 500; # ms

# Test the basic construction, and timing:

my @times;

my $W = new Win32::GUI::Window(
    -name => "TestWindow",
    -onTimer => \&_process_timer,
);
my $t0 = Win32::GetTickCount();
my $C = $W->AddTimer('T1', $elapse);

is($C->Interval(), $elapse, "Interval() returns timer interval");

@times=();
Win32::GUI::Dialog();

is(scalar(@times), 3, "Timer went off 3 times");
my $delta = 150; #ms
for my $interval (@times) {
	ok((abs($interval - $elapse) < $delta), "Timer interval(${interval}ms) appropriate");
}

is($C->Interval($elapse+500), $elapse, "Interval(SET) returns prior timer interval");
is($C->Interval(), $elapse+500, "Interval() returns new timer interval");

@times=();
Win32::GUI::Dialog();

is(scalar(@times), 3, "Timer went off 3 times");
for my $interval (@times) {
	ok((abs($interval-($elapse+500)) < $delta), "Timer interval(${interval}ms) appropriate");
}

sub _process_timer
{
	my $t1 = Win32::GetTickCount();
	push @times, ($t1 - $t0);
	$t0 = $t1;
	return scalar(@times) == 3 ? -1 : 0;
}
