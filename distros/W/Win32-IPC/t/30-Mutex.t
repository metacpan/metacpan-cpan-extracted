#! /usr/bin/perl
#---------------------------------------------------------------------
# t/30-Mutex.t
#
# Test Win32::Mutex
#---------------------------------------------------------------------

use strict;
use warnings;
use Test::More tests => 15;

use Win32::Mutex ();

diag(<<'END_WARNING');
This test should take no more than 10 seconds.
If it takes longer, please kill it with Ctrl-Break (Ctrl-C won't work right).
END_WARNING

# Make sure we can import the functions:
use_ok('Win32::Mutex', qw(wait_all wait_any INFINITE));

my $m = Win32::Mutex->new(0, undef); # Unowned mutex
ok($m, 'created unowned mutex');

isa_ok($m, 'Win32::Mutex');

is($m->wait(10), 1, 'wait(10)');

is($m->wait(0), 1, 'wait(0)');

is($m->wait, 1, 'wait()');

ok($m->release, 'release 1');
ok($m->Release, 'Release 2');   # deprecated method name
ok($m->release, 'release 3');

is($m->release, 0, 'release 4 fails');

#---------------------------------------------------------------------
$m = Win32::Mutex->new();   # Unowned mutex (by default)
ok($m, 'created unowned mutex 2');

isa_ok($m, 'Win32::Mutex');

is($m->release, 0, 'release unowned mutex 2 fails');

is($m->wait(2), 1, 'wait(2)');

ok($m->release, 'release unowned mutex 2');
