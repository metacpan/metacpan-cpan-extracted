#
#===============================================================================
#
#  DESCRIPTION:  A source returning a list of two or more values is cached
#                as a reference to an array holding them.
#
#       AUTHOR:  Anton Morozov (antonfin@cpan.org)
#      CREATED:  18.02.2011 15:15:11
#===============================================================================

use strict;
use warnings;
use lib 'blib/lib';

use Test::More tests => 6;

use_ok('Tie::Cache::Autoupdater');

tie my %cache, 'Tie::Cache::Autoupdater';

my $i = 0;
$cache{key1} = {
    timeout => 1,
    source  => \&_test,
};

my $data = $cache{key1};

is ( ref $data, 'ARRAY', 'a returned list is cached as an array reference' );
ok ( eq_array( $data, [ 1, 1 ] ), 'the array holds the returned values' );

$data = $cache{key1};
ok ( eq_array( $data, [ 1, 1 ] ), 'second read returns the cached array' );

sleep 2;

$data = $cache{key1};

ok ( eq_array( $data, [ 1, 2 ] ), 'read after the timeout rebuilds the array' );
ok ( eq_array( $data, [ 1, 2 ] ), 'the rebuilt array is cached in turn' );

sub _test { return ( 1, ++$i ) }

1;

