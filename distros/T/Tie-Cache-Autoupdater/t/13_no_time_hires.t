#
#===============================================================================
#
#  DESCRIPTION:  Time::HiRes is optional. With it hidden from the loader,
#                the module must still compile and cache, falling back to
#                the built-in time().
#
#       AUTHOR:  Anton Morozov (antonfin@cpan.org)
#===============================================================================

use strict;
use warnings;
use lib 'blib/lib';

use Test::More tests => 5;

# Make "require Time::HiRes" fail, however the module is loaded afterwards.
BEGIN {
    delete $INC{'Time/HiRes.pm'};
    unshift @INC, sub {
        die "Time::HiRes is hidden by $0\n" if $_[1] eq 'Time/HiRes.pm';
        return;
    };
}

use_ok('Tie::Cache::Autoupdater');

ok ( !exists $INC{'Time/HiRes.pm'}, 'the module loaded without Time::HiRes' );

tie my %cache, 'Tie::Cache::Autoupdater';

my $i = 0;
$cache{key1} = {
    timeout => 1,
    source  => sub { ++$i }
};

is ( $cache{key1}, 1, 'the cache works on the built-in time()' );
is ( $cache{key1}, 1, 'and still caches' );

sleep 2;

is ( $cache{key1}, 2, 'and still refreshes once the timeout has expired' );

1;

