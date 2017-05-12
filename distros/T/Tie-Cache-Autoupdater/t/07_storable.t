#
#===============================================================================
#
#  DESCRIPTION:  test base package possibility
#
#       AUTHOR:  Anton Morozov (antonfin@cpan.org)
#      CREATED:  03.07.2011 19:35:00
#===============================================================================

use strict;
use warnings;
use lib('blib/lib/');
use Test::More tests => 9;

use_ok('Tie::Cache::Autoupdater');

tie my %cache, 'Tie::Cache::Autoupdater';

my $i = 0;
$cache{key1} = {
    timeout => 1,
    source  => \&_test1,
};

my $j = 0;
$cache{key2} = {
    timeout => 1,
    source  => \&_test2,
    clone   => 1
};


my $data  = $cache{key1};
my $data2 = $cache{key2};

is ( ref $data, 'ARRAY' );
ok ( eq_array( $data, [ 1, 1 ] ) );

is ( ref $data2, 'ARRAY' );
ok ( eq_array( $data2, [ 1, 1 ] ) );

# check not cloned logic
$data->[0] = 3;
$data = $cache{key1};
ok ( eq_array( $data, [ 3, 1 ] ) );

# check cloned logic
use Data::Dumper;

$data2->[0] = 3;
print Dumper( $data2 );
$data2 = $cache{key2};
print Dumper( $data2 );
ok ( eq_array( $data2, [ 1, 1 ] ) );

sleep 2;

$data   = $cache{key1};
$data2  = $cache{key2};

ok ( eq_array( $data,  [ 1, 2 ] ) );
ok ( eq_array( $data2, [ 1, 2 ] ) );

sub _test1 { return [ 1, ++$i ] } 
sub _test2 { return [ 1, ++$j ] } 

1;

