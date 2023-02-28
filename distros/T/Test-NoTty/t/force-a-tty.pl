#!perl

use strict;
use warnings;

# This code assumes that it is in package main, and someone has already imported
# Test::More (or the Test2 equivalent)

my $dev_tty = '/dev/tty';

# Someone, somewhere, is going to try to cheat...
BAIL_OUT("$dev_tty is now missing - Makefile.PL should have checked for this")
    unless -e $dev_tty;

# Someone, somewhere, is going to try to cheat...
BAIL_OUT("$dev_tty is now missing - Makefile.PL should have checked for this")
    unless -e $dev_tty;

my $pty;
if (open my $tty, '+<', $dev_tty) {
    # That would be *bad*:
    close $tty
        or die "Failed to *close* $dev_tty: $!";
} else {
    # We don't *have* a controlling terminal, so we need to create one just so
    # that we can test getting rid of it :-)
    note("Using IO::Pty to create a controlling terminal...");
    require IO::Pty;
    $pty = IO::Pty->new;
    # This is still the term Open Group are using for this end:
    $pty->make_slave_controlling_terminal();

    if (open my $tty, '+<', $dev_tty) {
        note("Our pseudo-terminal is now our controlling terminal \\o/");
        # That would be *bad*:
        close $tty
            or die "Failed to *close* our pseudo-tty: $!";
    } else {
        die "Failed to attach our pseudo-tty as $dev_tty";
    }
    # We now return you to your regularly scheduled programming...
}

END {
    if ($pty) {
        local $SIG{HUP} = sub {
            note("Got a HUP when closing my controlling terminal - this is expected");
        };
        my $got = $pty->close;
    }
}

1;
