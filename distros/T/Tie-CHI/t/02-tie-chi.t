#!/usr/bin/env perl
#
use Tie::CHI;
use File::Temp qw(tempdir);
use Test::More;
use Test::Deep;
use strict;
use warnings;

my $root_dir = tempdir( 'tie-chi-XXXX', TMPDIR => 1, CLEANUP => 1 );
my %cache;
tie %cache, 'Tie::CHI', { driver => 'File', root_dir => $root_dir };
test();
untie %cache;

my $datastore = {};
tie %cache, 'Tie::CHI', CHI->new( driver => 'Memory', datastore => $datastore );
test();

done_testing();

sub test {
    ok( !%cache, "cache is empty" );
    is( $cache{foo}, undef, "foo not defined" );

    @cache{qw(foo bar baz blargh)} = ( 5, 6, [ 7, 8 ], 9 );
    ok( scalar(%cache), "cache is not empty" );
    cmp_set( [ keys(%cache) ], [qw(foo bar baz blargh)], "4 keys" );
    ok( exists( $cache{foo} ), "foo exists" );
    is( $cache{foo}, 5, "foo=5" );
    cmp_deeply( $cache{baz}, [ 7, 8 ], "baz=[7, 8]" );

    delete( @cache{qw(foo baz)} );
    tied(%cache)->_cache->expire('blargh');
    ok( scalar(%cache),            "cache is not empty" );
    ok( !exists( $cache{foo} ),    "foo does not exist" );
    ok( !exists( $cache{blargh} ), "blargh does not exist" );
    ok( keys(%cache) >= 1 && keys(%cache) <= 2, "between 1 and 2 keys" );
    is( $cache{bar}, 6, "bar=6" );

    %cache = ();
    ok( !%cache, "cache is empty again" );
}
