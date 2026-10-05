#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use JSON::MaybeXS;
use WWW::Keycloak::Diff;

my $diff = 'WWW::Keycloak::Diff';

subtest 'same' => sub {
  ok( $diff->same( 'a', 'a' ), 'equal strings' );
  ok( !$diff->same( 'a', 'b' ), 'different strings' );
  ok( $diff->same( 3600, '3600' ), 'number and string' );
  ok( $diff->same( undef, undef ), 'both undef' );
  ok( !$diff->same( undef, '' ), 'undef is not empty' );
  ok( !$diff->same( 'x', undef ), 'value and undef' );
  for my $true ( \1, JSON::MaybeXS::true, 'true', 1 ) {
    for my $other ( \1, JSON::MaybeXS::true, 'true' ) {
      ok( $diff->same( $true, $other ), 'true in any spelling' );
    }
    ok( !$diff->same( $true, \0 ), 'true is not false' );
  }
  for my $false ( \0, JSON::MaybeXS::false, 'false' ) {
    ok( $diff->same( $false, 0 ), 'false in any spelling' );
  }
  ok( !$diff->same( 'true', 'yes' ), 'a string that only looks boolean' );
  ok( !$diff->same( 1, 2 ), 'numbers stay numbers' );
  ok( $diff->same( [qw( a b )], [qw( a b )] ), 'equal lists' );
  ok( $diff->same( [qw( a b )], [qw( b a )] ), 'lists of plain values are sets: Keycloak sorts them' );
  ok( !$diff->same( [qw( a b )], [qw( a b c )] ), 'but not the same set' );
  ok( !$diff->same( [qw( a a b )], [qw( a b b )] ), 'counts matter' );
  ok( !$diff->same( [ { a => 1 }, { b => 1 } ], [ { b => 1 }, { a => 1 } ] ), 'lists of structures keep their order' );
  ok( $diff->same( [ { a => 1, b => 2 } ], [ { b => 2, a => 1 } ] ), 'key order inside does not' );
};

subtest 'changes' => sub {
  my $current = {
    id          => 'uuid',
    clientId    => 'cli',
    enabled     => JSON::MaybeXS::true,
    publicClient => JSON::MaybeXS::false,
    redirectUris => ['https://a/*'],
    attributes  => { 'oauth2.device.authorization.grant.enabled' => 'false', 'pkce.code.challenge.method' => 'S256' }
  };
  is_deeply( $diff->changes( $current, { clientId => 'cli', enabled => \1 } ), {}, 'nothing to do' );
  is_deeply( $diff->changes( $current, { publicClient => \1 } ), { publicClient => \1 }, 'one top-level key' );
  is_deeply(
    $diff->changes( $current, { attributes => { 'oauth2.device.authorization.grant.enabled' => 'true' } } ),
    { attributes => { 'oauth2.device.authorization.grant.enabled' => 'true', 'pkce.code.challenge.method' => 'S256' } },
    'a nested hash comes back merged, the untouched key kept'
  );
  is_deeply( $diff->changes( $current, { attributes => { 'pkce.code.challenge.method' => 'S256' } } ), {}, 'a nested key that already matches' );
  is_deeply( $diff->changes( $current, { redirectUris => [ 'https://a/*', 'https://b/*' ] } ), { redirectUris => [ 'https://a/*', 'https://b/*' ] }, 'a list is replaced' );
  is_deeply( $diff->changes( $current, { description => 'new' } ), { description => 'new' }, 'a key the current state lacks' );
  is_deeply( $diff->changes( {}, { a => { b => 1 } } ), { a => { b => 1 } }, 'nested hash where there was none' );
  is_deeply( $diff->changes( { a => 'scalar' }, { a => { b => 1 } } ), { a => { b => 1 } }, 'a hash where there was a scalar' );
  is_deeply( $diff->changes( undef, { a => 1 } ), { a => 1 }, 'undef current' );
  is_deeply( $current->{attributes}{'oauth2.device.authorization.grant.enabled'}, 'false', 'the current state is not modified' );
};

subtest 'merge' => sub {
  my $merged = $diff->merge( { a => 1, h => { x => 1, y => 2 }, l => [1] }, { b => 2, h => { y => 3, z => 4 }, l => [2] } );
  is_deeply( $merged, { a => 1, b => 2, h => { x => 1, y => 3, z => 4 }, l => [2] }, 'deep for hashes, replacing everything else' );
  is_deeply( $diff->merge( undef, { a => 1 } ), { a => 1 }, 'undef current' );
};

done_testing;
