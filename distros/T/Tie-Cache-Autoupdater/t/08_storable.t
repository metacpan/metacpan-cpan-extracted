#
#===============================================================================
#
#  DESCRIPTION:  The "clone" flag, on keys passed to tie - including an
#                explicit "clone => 0" (compare with t/07_storable.t).
#
#       AUTHOR:  Anton Morozov (antonfin@cpan.org)
#      CREATED:  03.07.2011 19:59:00
#===============================================================================

use strict;
use warnings;
use lib 'blib/lib';

use Test::More tests => 9;

use_ok('Tie::Cache::Autoupdater');

my $i = 0;
my $j = 0;

tie my %cache, 'Tie::Cache::Autoupdater', key1 => {
    timeout => 1,
    source  => \&_test1,
    clone   => 0
}, key2 => {
    timeout => 1,
    source  => \&_test2,
    clone   => 1
};

my $data  = $cache{key1};
my $data2 = $cache{key2};

is ( ref $data, 'ARRAY', 'key1: the returned reference is the cached one' );
ok ( eq_array( $data, [ 1, 1 ] ), 'key1: holds the data built by the source' );

is ( ref $data2, 'ARRAY', 'key2: the returned reference is a clone' );
ok ( eq_array( $data2, [ 1, 1 ] ), 'key2: holds the data built by the source' );

# clone => 0 is the default behaviour: the caller shares the cached structure.
$data->[0] = 3;
$data = $cache{key1};
ok ( eq_array( $data, [ 3, 1 ] ), 'key1: the change leaked into the cache' );

# With "clone" the caller holds a private copy, and the cache is untouched.
$data2->[0] = 3;
$data2 = $cache{key2};
ok ( eq_array( $data2, [ 1, 1 ] ), 'key2: the cache was not affected' );

sleep 2;

$data   = $cache{key1};
$data2  = $cache{key2};

ok ( eq_array( $data,  [ 1, 2 ] ), 'key1: refreshed, the change is gone' );
ok ( eq_array( $data2, [ 1, 2 ] ), 'key2: refreshed' );

sub _test1 { return [ 1, ++$i ] }
sub _test2 { return [ 1, ++$j ] }

1;

