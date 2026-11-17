#
#===============================================================================
#
#  DESCRIPTION:  Keys passed to tie behave exactly like keys registered
#                afterwards (compare with t/02_base_list.t).
#
#       AUTHOR:  Anton Morozov (antonfin@cpan.org)
#      CREATED:  18.02.2011 14:48:05
#===============================================================================

use strict;
use warnings;
use lib 'blib/lib';

use Test::More tests => 11;

use_ok('Tie::Cache::Autoupdater');

my $i = 0;

tie my %cache, 'Tie::Cache::Autoupdater',
    key1 => {
        timeout => 2,
        source  => sub { ++$i }
    },
    key2 => {
        timeout => 4,
        source  => sub { $i + 10 }
    };

is ( $cache{key1}, 1,  'key1: first read calls the source' );
is ( $cache{key2}, 11, 'key2: first read calls the source' );

sleep 1;

is ( $cache{key1}, 1,   'key1: cached, timeout has not expired' );
is ( $cache{key2}, 11,  'key2: cached, timeout has not expired' );

sleep 2;

is ( $cache{key1}, 2,   'key1: refreshed after its 2 second timeout' );
is ( $cache{key2}, 11,  'key2: still cached, its timeout is longer' );

sleep 3;

is ( $cache{key1}, 3,   'key1: refreshed again' );
is ( $cache{key2}, 13,  'key2: refreshed after its 4 second timeout' );

is ( $cache{key1}, 3,   'key1: the refreshed value is cached' );
is ( $cache{key2}, 13,  'key2: the refreshed value is cached' );

1;

