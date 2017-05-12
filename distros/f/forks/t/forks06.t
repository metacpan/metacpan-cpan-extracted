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
use forks 'stringify'; # must be done _before_ Test::More which loads real threads.pm
use forks::shared;

diag( <<EOD );

These tests exercise deadlock detection and resolution features of forks.

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

use Test::More tests => 11;
use strict;
use warnings;
use POSIX qw(SIGTERM SIGKILL);
use Time::HiRes qw(time);

$SIG{ALRM} = sub { die 'Deadlock resolver failed to terminate a thread'; };
alarm 90;    #give ourselves some time to complete these tests

my $a : shared;
my $b : shared;
my $c : shared;

sub deadlock_thread_pair {
    my $t1 = threads->new(sub {
        lock $a;
        sleep 2;
        lock $b;
        lock $c;
    });
    my $t2 = threads->new(sub {
        lock $b;
        sleep 2;
        lock $a;
        lock $c;
    });
    return ($t1, $t2);
}

#== manually detect and resolve ====================================
my ($thr1, $thr2);
{
    lock $c;
    ($thr1, $thr2) = deadlock_thread_pair();
    sleep 5;
    ok($thr1->is_deadlocked(), "Check if thread $thr1 is deadlocked");
    ok($thr2->is_deadlocked(), "Check if thread $thr2 is deadlocked");

    forks::shared->import(deadlock => {resolve => 1});    #resolve the current deadlock
    sleep 3;

    if ($thr1->is_running()) {
        ok($thr1->is_running(), "Check if thread $thr1 is still running");
        ok(!$thr2->is_running(), "Check if thread $thr2 was auto-killed");
    } else {
        ok($thr2->is_running(), "Check if thread $thr2 is still running");
        ok(!$thr1->is_running(), "Check if thread $thr1 was auto-killed");
    }
    sleep 3;
}
$_->join() foreach threads->list();

#== auto-detect and resolve ========================================
forks::shared->set_deadlock_option(detect => 1);

($thr1, $thr2) = deadlock_thread_pair();
$_->join() foreach threads->list();
ok(!$thr1->is_running(), "Check if thread $thr1 completed (killed or joined)");
ok(!$thr2->is_running(), "Check if thread $thr2 completed (killed or joined)");

#== auto-detect and resolve with TERM signal =======================
SKIP: {
skip 'No longer supported', 2;
forks::shared->set_deadlock_option(resolve_signal => SIGTERM);
($thr1, $thr2) = deadlock_thread_pair();
$_->join() foreach threads->list();
ok(!$thr1->is_running(), "Check if thread $thr1 completed (killed or joined)");
ok(!$thr2->is_running(), "Check if thread $thr2 completed (killed or joined)");
}

#== timed auto-detect and resolve ==================================
my $min_time = 10;
forks::shared->set_deadlock_option(
    detect => 1, period => $min_time, resolve_signal => SIGKILL);

my $t = time();
($thr1, $thr2) = deadlock_thread_pair();
$_->join() foreach threads->list();
cmp_ok($t ,'>', $min_time, 'Check that asynchronous deadlock detection worked' );
ok(!$thr1->is_running(), "Check if thread $thr1 completed (killed or joined)");
ok(!$thr2->is_running(), "Check if thread $thr2 completed (killed or joined)");

alarm 0;    #success: reset alarm

1;
