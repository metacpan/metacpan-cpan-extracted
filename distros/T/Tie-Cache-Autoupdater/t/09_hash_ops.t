#
#===============================================================================
#
#  DESCRIPTION:  Standard hash operations on a tied cache: exists, delete,
#                keys, each, clear, boolean context and untie.
#
#       AUTHOR:  Anton Morozov (antonfin@cpan.org)
#===============================================================================

use strict;
use warnings;
use lib 'blib/lib';

use Test::More tests => 16;

use_ok('Tie::Cache::Autoupdater');

my %calls;

tie my %cache, 'Tie::Cache::Autoupdater',
    key1 => { timeout => 60, source => sub { $calls{key1}++; 'one' } },
    key2 => { timeout => 60, source => sub { $calls{key2}++; 'two' } };

ok (  exists $cache{key1}, 'exists is true for a registered key' );
ok ( !exists $cache{absent}, 'exists is false for a key that was never registered' );
is_deeply ( \%calls, {}, 'exists calls no source subroutine' );

is ( $cache{absent}, undef, 'reading an unregistered key returns undef' );

is_deeply ( [ sort keys %cache ], [ qw( key1 key2 ) ],
    'keys lists the registered keys' );

my %seen;
while ( my ( $k, $v ) = each %cache ) { $seen{ $k } = $v }
is_deeply ( \%seen, { key1 => 'one', key2 => 'two' },
    'each returns every key together with its value' );

ok ( %cache, 'a cache with registered keys is true in boolean context' );

delete $cache{key1};
ok ( !exists $cache{key1}, 'delete unregisters the key' );
is ( $cache{key1}, undef, 'a deleted key reads as undef' );
is_deeply ( [ keys %cache ], [ 'key2' ], 'the remaining key is untouched' );

%cache = ();
is_deeply ( [ keys %cache ], [], 'assigning an empty list unregisters everything' );
ok ( !%cache, 'an empty cache is false in boolean context' );

untie %cache;
is_deeply ( \%cache, {}, 'after untie the hash is an ordinary empty hash' );

# A cache does not have to live as long as the program: it is released,
# together with everything it has cached, when its hash goes out of scope.
{
    tie my %scoped, 'Tie::Cache::Autoupdater',
        key => { timeout => 60, source => sub { 'scoped' } };

    is ( $scoped{key}, 'scoped', 'a cache can live in a nested scope' );
}
ok ( 1, 'and is released when that scope ends' );

1;

