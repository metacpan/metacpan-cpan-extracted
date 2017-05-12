#!/usr/local/bin/perl -w
my @custom_inc;
BEGIN {
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @custom_inc = @INC = '../lib';
    } elsif (!grep /blib/, @INC) {
        chdir 't' if -d 't';
        unshift @INC, (@custom_inc = ('../blib/lib', '../blib/arch'));
    }
}

BEGIN {delete $ENV{THREADS_DEBUG}} # no debugging during testing!

no if $] >= 5.008, warnings => 'threads';
use forks; # must be done _before_ Test::More which loads real threads.pm
use forks::shared;

diag( <<EOD );

These tests check inter-thread signaling.

EOD

# "Unpatch" Test::More, who internally tries to disable threads
BEGIN {
    no warnings 'redefine';
    if ($] < 5.008001) {
        require forks::shared::global_filter;
        import forks::shared::global_filter 'Test::Builder';
        require Test::Builder;
        *Test::Builder::share = \&threads::shared::share;
        *Test::Builder::lock = \&threads::shared::lock;
        Test::Builder->new->reset;
    }
}

# Patch Test::Builder to add fork-thread awareness
{
    no warnings 'redefine';
    my $_sanity_check_old = \&Test::Builder::_sanity_check;
    *Test::Builder::_sanity_check = sub {
        my $self = $_[0];
        # Don't bother with an ending if this is a forked copy.  Only the parent
        # should do the ending.
        if( $self->{Original_Pid} != $$ ) {
            return;
        }
        $_sanity_check_old->(@_);
    };
}

use Test::More tests => 3;
use strict;
use warnings;

my $thr = threads->new(sub { while (1) { sleep 1; } });
sleep 3;
$thr->kill('TERM');
sleep 3;
ok(!$thr->is_running(), 'Check that thread is no longer running');

my $gotsig : shared = 0;
$thr = threads->new(sub {
    $SIG{TERM} = sub { $gotsig = 1; CORE::exit(); };
    while (1) { sleep 1; }
});
sleep 3;
$thr->kill('TERM');
sleep 3;
ok(!$thr->is_running(), 'Check that thread is no longer running');
ok($gotsig, 'Check that custom signal handler was used');

foreach (threads->list()) {
    $_->join() if $_->is_joinable; #check before join, in case target system has non-standard/reliable signal behavior
}

1;
