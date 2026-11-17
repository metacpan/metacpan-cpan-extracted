#
#===============================================================================
#
#  DESCRIPTION:  The "clone" flag, on keys registered after the tie:
#                without it the caller gets the cached reference itself,
#                with it a fresh deep copy on every read.
#
#       AUTHOR:  Anton Morozov (antonfin@cpan.org)
#      CREATED:  03.07.2011 19:35:00
#===============================================================================

use strict;
use warnings;
use lib 'blib/lib';

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

is ( ref $data, 'ARRAY', 'key1: the returned reference is the cached one' );
ok ( eq_array( $data, [ 1, 1 ] ), 'key1: holds the data built by the source' );

is ( ref $data2, 'ARRAY', 'key2: the returned reference is a clone' );
ok ( eq_array( $data2, [ 1, 1 ] ), 'key2: holds the data built by the source' );

# Without "clone" the caller shares the cached structure, so a change to the
# returned data is visible on the next read as well.
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

