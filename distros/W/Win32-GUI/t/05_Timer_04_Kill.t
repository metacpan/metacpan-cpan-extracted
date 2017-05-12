#!perl -wT
# Win32::GUI test suite.
# $Id: 05_Timer_04_Kill.t,v 1.2 2006/05/16 18:57:26 robertemay Exp $
#
# test coverage of Timers

use strict;
use warnings;

BEGIN { $| = 1 } # Autoflush

use Test::More tests => 19;

use Win32::GUI();

my $ctrl = "Timer";
my $class = "Test::$ctrl";

my $elapse = 500; # ms

# Test the Kill method

my $W = new Win32::GUI::Window(
    -name => "TestWindow",
);
my $C = Test::Timer->new($W, 'T1', $elapse);
isa_ok($C,$class, "new creates $class object");
isa_ok($C,"Win32::GUI::Timer", "$class is a subclass of Win32::GUI::Timer");
isa_ok($W->T1, $class, "\$W->T1 contains a $class object");
isa_ok($W->T1,"Win32::GUI::Timer", "\$W->T1 contains a subclass of Win32::GUI::Timer");
is($C, $W->T1, "Parent references $ctrl");

my $id = $C->{-id};
ok(($id > 0), "timer's -id > 0");
ok(defined $W->{-timers}->{$id}, "Timer's id is stored in parent");
is($W->{-timers}->{$id}, 'T1', "Timer's name is stored in parent");

is($C->{-name}, 'T1', "Timer's name is stored in timer object");
is($C->{-handle}, $W->{-handle}, "Parent's handle is stored in timer object");
is($C->{-interval}, $elapse, "Timer interval is stored in timer object");

# Kill tests
is($C->Kill(), $elapse, "Kill() returns timer interval");
is($C->Interval(), 0, "Kill() sets inteval to zero");
is($Test::Timer::x, 0, "DESTROY not called yet");
ok(!defined($C->Kill(1)), "Kill(1) returns undef");
is($Test::Timer::x, 1, "Kill(1) calls DESTROY");
ok(!defined $W->{-timers}->{$id}, "Kill(1) tidies parent");
ok(!defined $W->{T1}, "Kill(1) tidies parent");
undef $C; #should remove last reference
is($Test::Timer::x, 2, "DESTROY called for object destruction");

package Test::Timer;
our (@ISA, $x);
BEGIN {
	@ISA = qw(Win32::GUI::Timer);
	$x = 0;
}


sub DESTROY
{
	my $self = shift;

	++$x;
	$self->SUPER::DESTROY(@_);
}

