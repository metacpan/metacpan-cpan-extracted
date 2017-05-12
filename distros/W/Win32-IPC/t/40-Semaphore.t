#! /usr/bin/perl
#---------------------------------------------------------------------
# t/40-Semaphore.t
#
# Test Win32::Semaphore
#---------------------------------------------------------------------

use strict;
use warnings;
use Test::More tests => 17;

use Win32::Semaphore ();

diag(<<'END_WARNING');
This test should take no more than 10 seconds.
If it takes longer, please kill it with Ctrl-Break (Ctrl-C won't work right).
END_WARNING

# Make sure we can import the functions:
use_ok('Win32::Semaphore', qw(wait_all wait_any INFINITE));

my $s = Win32::Semaphore->new(3,3);
ok($s, 'created $s');

isa_ok($s, 'Win32::Semaphore');

is($s->wait(10), 1, 'wait(10)');

is($s->wait(0), 1, 'wait(0)');

is($s->wait, 1, 'wait()');

is($s->wait(0), 0, 'wait(0) times out');

is($s->wait(10), 0, 'wait(10) times out');

ok($s->release, 'release');

is($s->wait(0), 1, 'wait(0) succeeds now');

ok($s->release(1), 'release(1)');

my $result;
ok($s->release(1,$result), 'release(1,$result)');
is($result, 1, 'count was 1');

ok($s->Release(1,$result), 'Release(1,$result)'); # Deprecated method name
is($result, 2, 'count was 2');

is($s->release(1), 0, 'release(1) fails now');

is($s->wait(2), 1, 'wait(2) succeeds');
