#
#===============================================================================
#
#  DESCRIPTION:  A missing or false timeout falls back to the default of
#                one second, and re-registering a key discards whatever was
#                cached for it.
#
#       AUTHOR:  Anton Morozov (antonfin@cpan.org)
#===============================================================================

use strict;
use warnings;
use lib 'blib/lib';

use Test::More tests => 10;

use_ok('Tie::Cache::Autoupdater');

my $i = 0;

tie my %cache, 'Tie::Cache::Autoupdater',
    no_timeout   => { source => sub { ++$i } },
    zero_timeout => { source => sub { ++$i }, timeout => 0 };

is ( $cache{no_timeout}, 1, 'a key registered without a timeout works' );
is ( $cache{no_timeout}, 1, 'and caches its value' );

is ( $cache{zero_timeout}, 2, 'a zero timeout works as well' );
is ( $cache{zero_timeout}, 2, 'and is replaced by the default, so it caches too' );

my $j = 0;
$cache{stored_without_timeout} = { source => sub { ++$j } };

is ( $cache{stored_without_timeout}, 1,
    'a key registered after the tie needs no timeout either' );
is ( $cache{stored_without_timeout}, 1, 'and caches its value as well' );

sleep 2;

is ( $cache{no_timeout}, 3, 'the default timeout is one second, and it does expire' );

# Storing to a key that is already registered describes it anew: the source
# is replaced and the cached value is dropped, without waiting for a timeout.
$cache{no_timeout} = { timeout => 60, source => sub { 'replaced' } };

is ( $cache{no_timeout}, 'replaced', 're-registering a key switches to the new source at once' );
is ( $i, 3, 'and the old source is not called again' );

1;

