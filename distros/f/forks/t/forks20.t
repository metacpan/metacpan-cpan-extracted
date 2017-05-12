#!/usr/local/bin/perl -T -w
BEGIN {
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    } elsif (!grep /blib/, @INC) {
        chdir 't' if -d 't';
        unshift @INC, ('../blib/lib', '../blib/arch');
    }
}

BEGIN {delete $ENV{THREADS_DEBUG}} # no debugging during testing!

use forks; # must be done _before_ Test::More which loads real threads.pm
use forks::shared;
use Config;

my ($reason,$tests,$entries);
BEGIN {
    $entries = 25;
    $tests = 3 + (3 * $entries);

    eval {require Thread::Queue};
    $reason = '';
    $reason = 'Thread::Queue not found'
     unless defined $Thread::Queue::VERSION;

    $tests = 1 if $reason;
} #BEGIN

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

use Test::More tests => $tests;
use strict;
use warnings;

diag( <<EOD );

These tests validate compatibility with Thread::Queue.

EOD

SKIP: {
    skip $reason, $tests if $reason;

    my $q = Thread::Queue->new;
    isa_ok( $q,'Thread::Queue', "Check if object has correct type" );

#------------------------------------------------------------------------
# queueing from child thread, dequeuing from main thread

    threads->new( sub {
        $q->enqueue( 1..$entries );
    } )->join;

    is( $q->pending,$entries,"Check all $entries entries on queue" );

    foreach (1..$entries) {
        my $value = $q->dequeue;
        is( $value,$_,"Check whether '$_' gotten from queue in main" );
    }

#------------------------------------------------------------------------
# queueing from main thread, non-blocking dequeuing from child thread

    $q = Thread::Queue->new( 1..$entries );

    is( $q->pending,$entries,"Check all $entries entries on queue" );

    threads->new( sub {
        foreach (1..$entries) {
            my $value = $q->dequeue_nb;
            is( $value,$_,"Check '$_' gotten from queue in child" );
        }
    } )->join;

#------------------------------------------------------------------------
# queueing and dequeueing from child threads

    my $enqueue = threads->new( sub {
        foreach (1..$entries) {
            $q->enqueue( $_ );
        }
    } );

    my $dequeue = threads->new( sub {
        foreach (1..$entries) {
            my $value = $q->dequeue;
            is( $value,$_,"Check '$_' gotten from queue in other child" );
        }
    } );

    $enqueue->join;
    $dequeue->join;

#------------------------------------------------------------------------
} #SKIP

1;
