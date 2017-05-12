#
#===============================================================================
#
#       AUTHOR:  Anton Morozov (antonfin@cpan.org)
#      CREATED:  18.02.2011 15:15:11
#===============================================================================

use strict;
use warnings;

use Test::More tests => 5;                      # last test to print

use_ok('Tie::Cache::Autoupdater');

tie my %cache, 'Tie::Cache::Autoupdater';

my $i = 0;
$cache{key1} = {
    timeout => 1,
    source  => \&_test,
};

is ( $cache{key1}, 1, 'Call anonymous subroutine' );
is ( $cache{key1}, 1, 'Return old data' );

sleep 2;

is ( $cache{key1}, 2, 'Call anonymous subroutine one more' );
is ( $cache{key1}, 2, 'Return old data' );

sub _test { ++$i } 

1;


