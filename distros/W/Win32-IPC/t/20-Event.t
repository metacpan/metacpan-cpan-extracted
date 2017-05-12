#! /usr/bin/perl
#---------------------------------------------------------------------
# t/20-Event.t
#
# Test Win32::Event
#---------------------------------------------------------------------

use strict;
use warnings;
use Test::More 0.88 tests => 20; # recent version

use Win32::Event ();

diag(<<'END_WARNING');
This test should take no more than 10 seconds.
If it takes longer, please kill it with Ctrl-Break (Ctrl-C won't work right).
END_WARNING

# Make sure we can import the functions:
use_ok('Win32::Event', qw(wait_all wait_any INFINITE));

my $e = Win32::Event->new(1,1); # Manual-reset, currently signalled
ok($e, 'created manual-reset event');

isa_ok($e, 'Win32::Event');

is($e->wait(10), 1, 'wait(10)');

is($e->wait(0), 1, 'wait(0)');

is($e->wait, 1, 'wait()');

is($e->wait(undef), 1, 'wait(undef)');

ok($e->reset, 'reset event');

is($e->wait(0), 0, 'wait(0) times out');

is($e->wait(10), 0, 'wait(10) times out');

ok($e->set, 'set event');

is($e->wait(0), 1, 'wait(0) succeeds now');

#---------------------------------------------------------------------
$e = Win32::Event->new(0,0);    # Auto-reset, unsignalled
ok($e, 'created auto-reset event');

isa_ok($e, 'Win32::Event');

is($e->wait(0), 0, 'wait(0) times out again');

ok($e->set, 'set event 2');

is($e->wait(2), 1, 'wait(2) succeeds');

is($e->wait(3), 0, 'wait(3) times out');

ok($e->set, 'set event 3');

is($e->wait(4), 1, 'wait(4) succeeds');
