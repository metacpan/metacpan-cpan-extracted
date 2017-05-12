#!/usr/bin/perl -w

use Test::More tests => 5;

# This must come before we use Test::Fork.
my $Forked_Pid;
BEGIN {
    *CORE::GLOBAL::fork = sub () {
        return $Forked_Pid = CORE::fork;
    };
}

use Test::Fork;

is fork_ok(1, sub { pass }), $Forked_Pid, 'fork_ok() returns the child PID';
ok $Forked_Pid, '...just make sure we got a PID';
is $?, 0, 'No leak from $?';
