#
#===============================================================================
#
#  DESCRIPTION:  test base package possibility
#
#       AUTHOR:  Anton Morozov (antonfin@cpan.org)
#      CREATED:  18.02.2011 14:48:05
#===============================================================================

use strict;
use warnings;
use lib('blib/lib/');
use Test::More tests => 11;                      # last test to print

use_ok('Tie::Cache::Autoupdater');

SKIP: {
    skip 'No Time::HiRes package', 10 unless eval { require Time::HiRes; };

    my $i = 0;

    tie my %cache, 'Tie::Cache::Autoupdater'; 

    $cache{key1} = {
        timeout => 0.2,
        source  => sub { ++$i }
    };

    $cache{key2} = {
        timeout => 0.4,
        source  => sub { $i + 10 }
    };

    is ( $cache{key1}, 1, 'Call anonymous subroutine' );
    is ( $cache{key2}, 11, 'Call anonymous subroutine' );

    Time::HiRes::sleep( 0.1 );

    is ( $cache{key1}, 1,   'Old data' );
    is ( $cache{key2}, 11,  'Old data' );

    Time::HiRes::sleep( 0.2 );
    is ( $cache{key1}, 2,   'New data' );
    is ( $cache{key2}, 11,  'Old data' );

    Time::HiRes::sleep( 0.3 );

    is ( $cache{key1}, 3,   'Call new data' );
    is ( $cache{key2}, 13,  'Return new data' );

    is ( $cache{key1}, 3,   'Old data' );
    is ( $cache{key2}, 13,  'Old data' );
}

1;

