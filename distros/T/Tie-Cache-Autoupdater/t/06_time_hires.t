#
#===============================================================================
#
#  DESCRIPTION:  With Time::HiRes available, fractional timeouts are
#                honoured. Skipped if the module is missing.
#
#       AUTHOR:  Anton Morozov (antonfin@cpan.org)
#      CREATED:  18.02.2011 14:48:05
#===============================================================================

use strict;
use warnings;
use lib 'blib/lib';

use Test::More tests => 11;

use_ok('Tie::Cache::Autoupdater');

SKIP: {
    skip 'No Time::HiRes package', 10 unless eval { require Time::HiRes; };

    my $i = 0;

    tie my %cache, 'Tie::Cache::Autoupdater';

    $cache{key1} = {
        timeout => 0.2,
        source  => sub { ++$i }
    };

    $cache{key2} = {
        timeout => 0.4,
        source  => sub { $i + 10 }
    };

    is ( $cache{key1}, 1,  'key1: first read calls the source' );
    is ( $cache{key2}, 11, 'key2: first read calls the source' );

    Time::HiRes::sleep( 0.1 );

    is ( $cache{key1}, 1,   'key1: cached, 0.2 second timeout has not expired' );
    is ( $cache{key2}, 11,  'key2: cached, 0.4 second timeout has not expired' );

    Time::HiRes::sleep( 0.2 );
    is ( $cache{key1}, 2,   'key1: refreshed after 0.2 seconds' );
    is ( $cache{key2}, 11,  'key2: still cached, its timeout is longer' );

    Time::HiRes::sleep( 0.3 );

    is ( $cache{key1}, 3,   'key1: refreshed again' );
    is ( $cache{key2}, 13,  'key2: refreshed after 0.4 seconds' );

    is ( $cache{key1}, 3,   'key1: the refreshed value is cached' );
    is ( $cache{key2}, 13,  'key2: the refreshed value is cached' );
}

1;

