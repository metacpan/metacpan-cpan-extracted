#
#===============================================================================
#
#  DESCRIPTION:  Where there is a monotonic clock, timeouts are measured on
#                it: the wall clock going back or forward changes nothing.
#
#       AUTHOR:  Anton Morozov (antonfin@cpan.org)
#===============================================================================

use strict;
use warnings;
use lib 'blib/lib';

use Test::More;

# The wall clock as every route to it reports it, under the test's control.
my $wall = 1_000_000_000;

BEGIN {
    no warnings 'once';
    *CORE::GLOBAL::time = sub () { $wall };
}

my $has_monotonic = eval {
    require Time::HiRes;
    Time::HiRes::clock_gettime( Time::HiRes::CLOCK_MONOTONIC() ) >= 0
};

plan skip_all => 'No monotonic clock on this system' unless $has_monotonic;
plan tests => 5;

{
    no warnings qw(redefine once);
    *Time::HiRes::time = sub () { $wall };
}

use_ok('Tie::Cache::Autoupdater');

tie my %cache, 'Tie::Cache::Autoupdater';

my $i = 0;
$cache{key} = {
    timeout => 1,
    source  => sub { ++$i }
};

is ( $cache{key}, 1, 'the first read calls the source' );

$wall -= 3600;
Time::HiRes::sleep( 1.2 );

is ( $cache{key}, 2, 'a value expires on time although the wall clock went back an hour' );

$wall += 7200;

is ( $cache{key}, 2, 'and does not expire early when the wall clock jumps forward' );

Time::HiRes::sleep( 1.2 );

is ( $cache{key}, 3, 'and keeps expiring on time afterwards' );

1;
