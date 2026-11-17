#
#===============================================================================
#
#  DESCRIPTION:  A named subroutine works as a source just like an
#                anonymous one.
#
#       AUTHOR:  Anton Morozov (antonfin@cpan.org)
#      CREATED:  18.02.2011 15:15:11
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
    source  => \&_test,
};

is ( $cache{key1}, 1, 'first read calls the named subroutine' );
is ( $cache{key1}, 1, 'second read returns the cached value' );

sleep 2;

is ( $cache{key1}, 2, 'read after the timeout calls the subroutine again' );
is ( $cache{key1}, 2, 'the refreshed value is cached in turn' );

sub _test { ++$i }

1;

