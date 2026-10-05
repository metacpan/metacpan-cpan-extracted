#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use JSON::MaybeXS;
use WWW::Authentik::Diff;

my $diff = 'WWW::Authentik::Diff';

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

  # authentik hands lists back in its own order and the order never carries meaning
  ok( $diff->same( [qw( a b )], [qw( a b )] ), 'equal lists' );
  ok( $diff->same( [qw( a b )], [qw( b a )] ), 'a list is a set' );
  ok( !$diff->same( [qw( a b )], [qw( a b b )] ), 'but not a set that forgets how many' );
  ok( !$diff->same( [qw( a b )], [qw( a c )] ), 'different members' );
  ok( $diff->same( [ { a => 1 }, { b => 2 } ], [ { b => 2 }, { a => 1 } ] ), 'a list of hashes is a set too' );
  ok( $diff->same( [ { a => 1, b => 2 } ], [ { b => 2, a => 1 } ] ), 'key order inside does not matter' );
  ok( $diff->same( [], [] ), 'two empty lists' );
  ok( !$diff->same( [], undef ), 'an empty list is not undef' );

  # authentik trims every text field it stores, so the trimmed form of what
  # was asked for is as close as the wanted state can get
  ok( $diff->same( 'two lines', "two lines\n" ), 'a stored value without the trailing newline' );
  ok( $diff->same( 'padded both', '  padded both  ' ), 'and without the padding on either side' );
  ok( !$diff->same( "two lines\n", 'two lines' ), 'but not the other way round' );
  ok( !$diff->same( '  keep me  ', 'keep me' ), 'so whitespace inside attributes is still a difference' );
  ok( !$diff->same( 'a b', 'ab' ), 'and inner whitespace is never ignored' );
  ok( $diff->same( '', '   ' ), 'an empty value against nothing but whitespace' );
};

subtest 'changes' => sub {
  my $current = {
    pk                => 1,
    name              => 'probe',
    client_type       => 'confidential',
    include_claims_in_id_token => JSON::MaybeXS::true,
    property_mappings => [qw( uuid-openid uuid-email uuid-profile )],
    redirect_uris     => [ { matching_mode => 'strict', url => 'https://a.example.org/cb', redirect_uri_type => 'authorization' } ],
    attributes        => { dept => 'x', site => 'y' }
  };
  is_deeply( $diff->changes( $current, { name => 'probe', client_type => 'confidential' } ), {}, 'nothing to do' );
  is_deeply( $diff->changes( $current, { client_type => 'public' } ), { client_type => 'public' }, 'one top-level key' );
  is_deeply(
    $diff->changes( $current, { attributes => { dept => 'z' } } ),
    { attributes => { dept => 'z', site => 'y' } },
    'a nested hash comes back merged, the untouched key kept'
  );
  is_deeply( $diff->changes( $current, { attributes => { site => 'y' } } ), {}, 'a nested key that already matches' );
  is_deeply( $diff->changes( $current, { description => 'new' } ), { description => 'new' }, 'a key the current state lacks' );
  is_deeply( $diff->changes( {}, { a => { b => 1 } } ), { a => { b => 1 } }, 'nested hash where there was none' );
  is_deeply( $diff->changes( { a => 'scalar' }, { a => { b => 1 } } ), { a => { b => 1 } }, 'a hash where there was a scalar' );
  is_deeply( $diff->changes( undef, { a => 1 } ), { a => 1 }, 'undef current' );

  # authentik sorts property_mappings its own way
  is_deeply( $diff->changes( $current, { property_mappings => [qw( uuid-email uuid-profile uuid-openid )] } ), {}, 'a reordered list is no change' );
  is_deeply(
    $diff->changes( $current, { property_mappings => [qw( uuid-openid uuid-email )] } ),
    { property_mappings => [qw( uuid-openid uuid-email )] },
    'a shorter list is a change'
  );

  # authentik adds redirect_uri_type to every redirect URI it stores
  is_deeply( $diff->changes( $current, { redirect_uris => [ { matching_mode => 'strict', url => 'https://a.example.org/cb' } ] } ),
    {}, 'a redirect URI without the default authentik adds is no change' );
  is_deeply(
    $diff->changes( $current, { redirect_uris => [ { matching_mode => 'strict', url => 'https://b.example.org/cb' } ] } ),
    { redirect_uris => [ { matching_mode => 'strict', url => 'https://b.example.org/cb' } ] },
    'another URL is a change, and the wanted value is written as it was given'
  );

  # the wanted value is written as it was given, even when the comparison
  # accepted the trimmed form
  is_deeply( $diff->changes( { name => 'two lines' }, { name => "two lines\n" } ), {}, 'a trimmed text field is no change' );
  is_deeply( $diff->changes( { name => 'two lines' }, { name => "three lines\n" } ), { name => "three lines\n" },
    'a different one is, and keeps what was asked for' );

  is( $current->{attributes}{dept}, 'x', 'the current state is not modified' );
};

subtest 'merge' => sub {
  my $merged = $diff->merge( { a => 1, h => { x => 1, y => 2 }, l => [1] }, { b => 2, h => { y => 3, z => 4 }, l => [2] } );
  is_deeply( $merged, { a => 1, b => 2, h => { x => 1, y => 3, z => 4 }, l => [2] }, 'deep for hashes, replacing everything else' );
  is_deeply( $diff->merge( undef, { a => 1 } ), { a => 1 }, 'undef current' );
};

subtest 'a non-boolean does not shift the comparison' => sub {
  # _bool is taken twice in one list, so a bare return would slide the second
  # value into the first slot
  my @pair = ( $diff->_bool('neither'), $diff->_bool( \1 ) );
  is( scalar @pair, 2, 'two values come back, even when the first is nothing' );
  is( $pair[0], undef, 'the first is undef' );
  is( $pair[1], 1, 'and the second is itself' );
  is( scalar( () = $diff->_bool( {} ) ), 1, 'a reference yields one value too' );
};

subtest 'with_defaults' => sub {
  is_deeply( $diff->list_defaults->{redirect_uris}, { redirect_uri_type => 'authorization' }, 'the one default authentik adds' );
  is_deeply(
    $diff->with_defaults( redirect_uris => [ { url => 'u' } ] ),
    [ { url => 'u', redirect_uri_type => 'authorization' } ],
    'filled in'
  );
  is_deeply( $diff->with_defaults( redirect_uris => [ { url => 'u', redirect_uri_type => 'other' } ] ),
    [ { url => 'u', redirect_uri_type => 'other' } ], 'an explicit value wins' );
  is_deeply( $diff->with_defaults( other => [ { url => 'u' } ] ), [ { url => 'u' } ], 'no defaults for other fields' );
  is( $diff->with_defaults( redirect_uris => 'not a list' ), 'not a list', 'left alone when it is no list' );
};

done_testing;
