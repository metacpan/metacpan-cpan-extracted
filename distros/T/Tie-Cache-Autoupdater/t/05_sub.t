#
#===============================================================================
#
#       AUTHOR:  Anton Morozov (antonfin@cpan.org)
#      CREATED:  18.02.2011 15:15:11
#===============================================================================

use strict;
use warnings;

use Test::More tests => 6;                      # last test to print

use_ok('Tie::Cache::Autoupdater');

tie my %cache, 'Tie::Cache::Autoupdater';

my $i = 0;
$cache{key1} = {
    timeout => 1,
    source  => \&_test,
};

my $data = $cache{key1};

is ( ref $data, 'ARRAY' );
ok ( eq_array( $data, [ 1, 1 ] ) );

$data = $cache{key1};
ok ( eq_array( $data, [ 1, 1 ] ) );

sleep 2;

$data = $cache{key1};

ok ( eq_array( $data, [ 1, 2 ] ) );
ok ( eq_array( $data, [ 1, 2 ] ) );

sub _test { return ( 1, ++$i ) } 

1;

