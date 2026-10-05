#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use FakeAuthentik;
use WWW::Authentik;

sub error_of (&) { my ( $code ) = @_; eval { $code->(); 1 } ? undef : $@ }

my $fake = FakeAuthentik->new;
my $api  = WWW::Authentik->new( base_url => $fake->base, token => $fake->token, ua => $fake )->api;

my $flow        = $api->find_flow('default-authentication-flow');
my $certificate = $api->find_certificate('authentik Self-signed Certificate');
my $group       = $api->create_group( { name => 'staff' } );
my $openid      = $api->find_scope_mappings_by_scope('openid')->[0];
my $email       = $api->find_scope_mappings_by_scope('email')->[0];

# a provider whose name looks like a primary key, and another one that really
# has that key
my $named_123 = $fake->add( providers => { name => '123', authorization_flow => 'f', invalidation_flow => 'f', redirect_uris => [] } );
my $pk_123    = $fake->add( providers => { pk => 123, name => 'real-provider', authorization_flow => 'f', invalidation_flow => 'f', redirect_uris => [] } );
isnt( $named_123->{pk}, 123, 'the provider called "123" has another primary key' );

subtest 'the two identifier shapes are named, not hidden' => sub {
  # the async twin asks for these instead of writing the patterns again
  my $uuid = WWW::Authentik::API->uuid_pattern;
  my $int  = WWW::Authentik::API->integer_pattern;
  like( '11111111-2222-4333-8444-555555555555', $uuid, 'a UUID' );
  unlike( 'default-authentication-flow', $uuid, 'and a slug is not one' );
  like( '123', $int, 'a run of digits' );
  unlike( '12a', $int, 'and not a name that starts with one' );
  is( $api->resolvable_fields->{provider}{raw}, $int, 'the table uses them' );
  is( $api->resolvable_fields->{authorization_flow}{raw}, $uuid, 'both of them' );
};

subtest 'an integer field' => sub {
  is( $api->resolve( { provider => '123' } )->{provider}, '123', 'an integer is the primary key, never a name' );
  is( $api->resolve( { provider => 123 } )->{provider}, 123, 'as a number too' );
  is( $api->resolve( { provider_name => '123' } )->{provider}, $named_123->{pk},
    'the forced form looks the name up even when it looks like a key' );
  is( $api->resolve( { provider => 'real-provider' } )->{provider}, 123, 'anything that is not an integer is a name' );

  my $both = error_of { $api->resolve( { provider => 1, provider_name => 'real-provider' } ) };
  isa_ok( $both, 'WWW::Authentik::Error::Validation', 'both forms at once' );
  like( "$both", qr/provider or provider_name/, 'and says which two' );

  my $gone = error_of { $api->resolve( { provider_name => 'nobody' } ) };
  isa_ok( $gone, 'WWW::Authentik::Error::Validation', 'a name nothing matches' );
  like( "$gone", qr/no oauth2 provider named "nobody"/, 'naming the field and the value' );

  my $user = $api->create_user( { username => 'alice', name => 'Alice' } );
  is( $api->resolve( { user => $user->{pk} } )->{user}, $user->{pk}, 'the user field takes a key' );
  is( $api->resolve( { user_name => 'alice' } )->{user}, $user->{pk}, 'and a username when forced' );
};

subtest 'a UUID field' => sub {
  is( $api->resolve( { authorization_flow => $flow->{pk} } )->{authorization_flow}, $flow->{pk}, 'a UUID is the key' );
  is( $api->resolve( { authorization_flow => 'default-authentication-flow' } )->{authorization_flow}, $flow->{pk},
    'anything else is a slug' );

  # a slug may have the shape of a UUID; then only the forced form reaches it
  my $odd = $api->create_flow( { name => 'Odd', slug => '11111111-2222-4333-8444-555555555555',
    title => 'Odd', designation => 'authentication' } );
  is( $api->resolve( { invalidation_flow => '11111111-2222-4333-8444-555555555555' } )->{invalidation_flow},
    '11111111-2222-4333-8444-555555555555', 'a UUID shape is taken as the key' );
  is( $api->resolve( { invalidation_flow_slug => '11111111-2222-4333-8444-555555555555' } )->{invalidation_flow},
    $odd->{pk}, 'the forced form looks the slug up anyway' );
  isnt( $odd->{pk}, '11111111-2222-4333-8444-555555555555', 'and the two really differ' );

  is( $api->resolve( { signing_key_name => 'authentik Self-signed Certificate' } )->{signing_key},
    $certificate->{pk}, 'a certificate by name' );
  like( error_of { $api->resolve( { configure_flow_slug => 'nope' } ) }, qr/no flow named "nope"/, 'an unknown flow' );
  $api->delete_flow( $odd->{slug} );
};

subtest 'lists' => sub {
  is_deeply( $api->resolve( { groups => [ $group->{pk} ] } )->{groups}, [ $group->{pk} ], 'a list of keys' );
  is_deeply( $api->resolve( { groups => ['staff'] } )->{groups}, [ $group->{pk} ], 'a list of names' );
  is_deeply( $api->resolve( { groups => [ $group->{pk}, 'staff' ] } )->{groups}, [ $group->{pk}, $group->{pk} ],
    'and a mixture' );
  is_deeply( $api->resolve( { group_names => ['staff'] } )->{groups}, [ $group->{pk} ], 'the forced form' );
  is_deeply( $api->resolve( { groups => [] } )->{groups}, [], 'an empty list stays empty' );
  like( error_of { $api->resolve( { group_names => ['nope'] } ) }, qr/no group named "nope"/, 'an unknown group' );
};

subtest 'scopes' => sub {
  is_deeply( $api->resolve( { scopes => [qw( openid email )] } )->{property_mappings},
    [ $openid->{pk}, $email->{pk} ], 'scopes become property_mappings, in order' );
  ok( !exists $api->resolve( { scopes => ['openid'] } )->{scopes}, 'and scopes is gone' );
  my $clash = error_of { $api->resolve( { scopes => ['openid'], property_mappings => [ $openid->{pk} ] } ) };
  isa_ok( $clash, 'WWW::Authentik::Error::Validation', 'scopes together with property_mappings' );
  like( "$clash", qr/scopes or property_mappings/, 'and says which two' );
  like( error_of { $api->resolve( { scopes => ['no-such-scope'] } ) }, qr/no scope mapping for the scope/, 'an unknown scope' );
};

subtest 'a mistake is not taken for a wish' => sub {
  # an undef where a name belongs is a bug in the caller, and for scopes a
  # costly one: taken as an empty list it would strip every mapping
  my $scopes = error_of { $api->resolve( { scopes => undef } ) };
  isa_ok( $scopes, 'WWW::Authentik::Error::Validation', 'scopes => undef' );
  like( "$scopes", qr/take every mapping away/, 'and says what it would have done' );
  is_deeply( $api->resolve( { scopes => [] } )->{property_mappings}, [], 'an empty list still means empty' );
  isa_ok( error_of { $api->resolve( { scopes => 'openid' } ) }, 'WWW::Authentik::Error::Validation', 'scopes as a string' );

  my $forced = error_of { $api->resolve( { provider_name => undef } ) };
  isa_ok( $forced, 'WWW::Authentik::Error::Validation', 'provider_name => undef' );
  like( "$forced", qr/provider_name is undef/, 'and names the key' );
  is_deeply( $api->resolve( { provider => undef } ), { provider => undef }, 'while provider => undef still passes through' );

  my $ref = error_of { $api->resolve( { user => {} } ) };
  isa_ok( $ref, 'WWW::Authentik::Error::Validation', 'a reference where a name belongs' );
  like( "$ref", qr/got a hash reference/, 'and says what it got' );
  unlike( "$ref", qr/HASH\(0x/, 'without an address in the message' );
};

subtest 'a finder needs something to find' => sub {
  # an undef key used to fetch the whole table and compare every row to undef
  for my $finder (qw( find_user find_group find_oauth2_provider find_scope_mapping
                      find_certificate find_stage find_application find_flow find_token )) {
    isa_ok( error_of { $api->$finder(undef) }, 'WWW::Authentik::Error::Validation', $finder.'(undef)' );
    isa_ok( error_of { $api->$finder('') }, 'WWW::Authentik::Error::Validation', $finder.q{('')} );
  }
};

subtest 'everything else is left alone' => sub {
  my $rep = $api->resolve( { name => 'x', client_type => 'public', redirect_uris => [ { url => 'u' } ], provider => 7 } );
  is( $rep->{name}, 'x', 'a plain field' );
  is( $rep->{client_type}, 'public', 'another one' );
  is_deeply( $rep->{redirect_uris}, [ { url => 'u' } ], 'a list that is not resolvable' );
  is( $rep->{provider}, 7, 'and the resolvable one' );
  is_deeply( $api->resolve( { provider => undef } ), { provider => undef }, 'undef is passed through' );

  my $before = { name => 'x', groups => ['staff'] };
  $api->resolve($before);
  is_deeply( $before, { name => 'x', groups => ['staff'] }, 'the hash that was passed in is not changed' );
};

done_testing;
