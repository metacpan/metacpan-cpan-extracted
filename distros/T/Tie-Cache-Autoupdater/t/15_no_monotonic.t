#
#===============================================================================
#
#  DESCRIPTION:  With Time::HiRes present but no working monotonic clock, the
#                module falls back to Time::HiRes::time - fractional timeouts
#                still work.
#
#       AUTHOR:  Anton Morozov (antonfin@cpan.org)
#===============================================================================

use strict;
use warnings;
use lib 'blib/lib';

use Test::More;

plan skip_all => 'No Time::HiRes package' unless eval { require Time::HiRes; 1 };
plan tests => 5;

# clock_gettime() returns -1 when the clock it is asked for is not available.
{
    no warnings qw(redefine once);
    *Time::HiRes::clock_gettime = sub (;$) { -1 };
}

use_ok('Tie::Cache::Autoupdater');

is ( \&Tie::Cache::Autoupdater::_now, \&Time::HiRes::time,
    'timeouts are measured with Time::HiRes::time' );

tie my %cache, 'Tie::Cache::Autoupdater';

my $i = 0;
$cache{key} = {
    timeout => 0.3,
    source  => sub { ++$i }
};

is ( $cache{key}, 1, 'the first read calls the source' );
is ( $cache{key}, 1, 'and the value is cached' );

Time::HiRes::sleep( 0.5 );

is ( $cache{key}, 2, 'a fractional timeout still expires on time' );

1;
