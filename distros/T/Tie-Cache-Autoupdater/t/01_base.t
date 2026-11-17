#
#===============================================================================
#
#  DESCRIPTION:  A key registered after the tie is cached and refreshed
#                once its timeout has expired.
#
#       AUTHOR:  Anton Morozov (antonfin@cpan.org)
#      CREATED:  18.02.2011 14:48:05
#===============================================================================

use strict;
use warnings;
use lib 'blib/lib';

use Test::More tests => 5;

use_ok('Tie::Cache::Autoupdater');

tie my %cache, 'Tie::Cache::Autoupdater';

my $i = 0;
$cache{key1} = {
    timeout => 1,
    source  => sub { ++$i; }
};

is ( $cache{key1}, 1, 'first read calls the source' );
is ( $cache{key1}, 1, 'second read returns the cached value' );

sleep 2;

is ( $cache{key1}, 2, 'read after the timeout calls the source again' );
is ( $cache{key1}, 2, 'the refreshed value is cached in turn' );

1;

