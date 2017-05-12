#!perl -wT
# Win32::GUI test suite.
# $Id: 05_Timer_01_OEM.t,v 1.3 2006/05/16 18:57:26 robertemay Exp $
#
# test coverage of Timers

use strict;
use warnings;

BEGIN { $| = 1 } # Autoflush

use Test::More tests => 14;

use Win32::GUI();

my $ctrl = "Timer";
my $class = "Win32::GUI::$ctrl";

my $elapse = 500; # ms

# Test the basic construction, and timing:

my @times;


my $W = new Win32::GUI::Window(
    -name => "TestWindow",
);
isa_ok($W, "Win32::GUI::Window", "\$W");

my $t0 = Win32::GetTickCount();
my $C = $W->AddTimer('T1', $elapse);
isa_ok($C,$class, "\$W->AddTimer creats $class object");
isa_ok($W->T1, $class, "\$W->T1 contains a $class object");
is($C, $W->T1, "Parent references $ctrl");

my $id = $C->{-id};
ok(($id > 0), "timer's -id > 0");
ok(defined $W->{-timers}->{$id}, "Timer's id is stored in parent");
is($W->{-timers}->{$id}, 'T1', "Timer's name is stored in parent");

is($C->{-name}, 'T1', "Timer's name is stored in timer object");
is($C->{-handle}, $W->{-handle}, "Parent's handle is stored in timer object");
is($C->{-interval}, $elapse, "Timer interval is stored in timer object");

Win32::GUI::Dialog();

is(scalar(@times), 3, "Timer went off 3 times");

my $delta = 150; #ms
for my $interval (@times) {
	ok((abs($interval - $elapse) < $delta), "Timer interval(${interval}ms) appropriate");
}

sub T1_Timer
{
	my $t1 = Win32::GetTickCount();
	push @times, ($t1 - $t0);
	$t0 = $t1;
	return scalar(@times) == 3 ? -1 : 0;
}
