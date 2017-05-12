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

use forks::BerkeleyDB; # must be done _before_ Test::More which loads real threads.pm
use forks::BerkeleyDB::shared;

diag( <<EOD );

These tests validate overloaded sleep behavior.

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

use Test::More tests => 6;
use strict;
use warnings;
use Time::HiRes;

# Check that main thread waits full 5 seconds after CHLD signal
my $t1 = threads->new(sub { sleep 1; });
my $time = sleep 5;
$t1->join();
cmp_ok(sprintf("%.0f", $time), '==', 5,'check that main thread sleeps full 5 seconds after CHLD signal');

# Check that main thread waits full 5 seconds after CHLD signal
$t1 = threads->new(sub { sleep 1; });
$time = Time::HiRes::sleep 5;
$t1->join();
cmp_ok(sprintf("%.0f", $time), '==', 5,'check that main thread sleeps full 5 seconds after CHLD signal');

# Check that main thread waits full 5 seconds after CHLD signal
SKIP: {
	skip('usleep not supported on this platform',1) unless &Time::HiRes::d_usleep;
	$t1 = threads->new(sub { sleep 1; });
	$time = Time::HiRes::usleep 5000000;
	$t1->join();
	cmp_ok(sprintf("%.0f", $time / 10**6), '==', 5,'check that main thread sleeps full 5 seconds after CHLD signal');
}

# Check that main thread waits full 5 seconds after CHLD signal
SKIP: {
	skip('nanosleep not supported on this platform',1) unless &Time::HiRes::d_nanosleep;
	$t1 = threads->new(sub { sleep 1; });
	$time = Time::HiRes::nanosleep 5000000000;
	$t1->join();
	cmp_ok(sprintf("%.0f", ($time / 10**9)), '==', 5,'check that main thread sleeps full 5 seconds after CHLD signal');
}

# Check that main thread waits full 5 seconds after CHLD signal
my $cnt = 0;
$SIG{CHLD} = sub { $cnt++ };
$t1 = threads->new(sub { sleep 1; });
$time = sleep 5;
$t1->join();
cmp_ok(sprintf("%.0f", $time), '==', 5,'check that main thread sleeps full 5 seconds after custom CHLD signal');
cmp_ok($cnt, '>=', 1,'check that custom CHLD signal was called');

1;
