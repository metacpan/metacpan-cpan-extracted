#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

# Live test against a real authentik. Off unless AUTHENTIK_LIVE_TEST=1,
# AUTHENTIK_URL and AUTHENTIK_TOKEN are set. Everything it makes carries a
# random prefix and is deleted at the end, so it can run beside other work on
# the same instance and twice in a row. A throwaway authentik:
# t/authentik/docker-compose.yml.

BEGIN {
  plan skip_all => 'set AUTHENTIK_LIVE_TEST=1, AUTHENTIK_URL and AUTHENTIK_TOKEN to run the authentik live test'
    unless $ENV{AUTHENTIK_LIVE_TEST} && $ENV{AUTHENTIK_URL} && $ENV{AUTHENTIK_TOKEN};
}

use AuthentikExecutor;
use WWW::Authentik;

my $prefix = 'wwwak-live-'.join '', map { ( 'a' .. 'z' )[ rand 26 ] } 1 .. 8;
my $password = 'Live-Password-'.join '', map { ( 'a' .. 'z', 0 .. 9 )[ rand 36 ] } 1 .. 12;

my $ak  = WWW::Authentik->new(
  base_url    => $ENV{AUTHENTIK_URL},
  application => $prefix,
  token       => $ENV{AUTHENTIK_TOKEN}
);
my $api = $ak->api;

sub error_of (&) { my ( $code ) = @_; eval { $code->(); 1 } ? undef : $@ }

sub twice {
  my ( $name, $code ) = @_;
  my $first  = $code->();
  my $second = $code->();
  is( $first->{changed}, 'created', $name.': created' );
  is( $second->{changed}, '', $name.': the second run changes nothing' );
  return $first;
}

# in reverse order of creation, and never loud about it
END {
  return unless $api;
  eval { $api->delete_application($prefix) };
  my $bindings = eval { $api->list_bindings } || [];
  for my $binding ( @$bindings ) {
    my $stage = eval { $api->find_stage( $prefix.'-password' ) };
    eval { $api->delete_binding( $binding->{pk} ) } if $stage && $binding->{stage} eq $stage->{pk};
  }
  for my $type (qw( password authenticator/validate )) {
    my $stage = eval { $api->find_stage( $prefix.( $type eq 'password' ? '-password' : '-validate' ) ) };
    eval { $api->delete_stage( $type, $stage->{pk} ) } if $stage;
  }
  eval { $api->delete_flow( $prefix.'-flow' ) };
  my $provider = eval { $api->find_oauth2_provider($prefix) };
  eval { $api->delete_oauth2_provider( $provider->{pk} ) } if $provider;
  my $mapping = eval { $api->find_scope_mapping( $prefix.'-mapping' ) };
  eval { $api->delete_scope_mapping( $mapping->{pk} ) } if $mapping;
  eval { $api->delete_token( $prefix.'-token' ) };
  for my $username ( $prefix, 'ak-'.$prefix.'-client_credentials' ) {
    # the second one is the service account authentik makes for the client
    # credentials grant; deleting the provider does not take it with it
    my $user = eval { $api->find_user($username) };
    eval { $api->delete_user( $user->{pk} ) } if $user;
  }
  my $group = eval { $api->find_group( $prefix.'-group' ) };
  eval { $api->delete_group( $group->{pk} ) } if $group;
}

subtest 'the instance' => sub {
  my $version = $api->version;
  diag 'authentik '.$version->{version_current};
  ok( $version->{version_current}, 'version' );
  ok( $api->me->{user}{username}, 'the token belongs to '.$api->me->{user}{username} );
  ok( $api->settings->{default_token_duration}, 'settings' );
};

my ( $provider, $user );

subtest 'objects, twice' => sub {
  twice( group => sub { $api->ensure_group( name => $prefix.'-group', attributes => { probe => 'yes' } ) } );

  $user = twice( user => sub {
    $api->ensure_user(
      username    => $prefix,
      name        => 'Live Test User',
      email       => $prefix.'@example.org',
      password    => $password,
      attributes  => { probe => 'yes' },
      group_names => [ $prefix.'-group' ]
    );
  } )->{object};
  is( scalar @{ $user->{groups} }, 1, 'the group name was resolved' );

  twice( mapping => sub {
    $api->ensure_scope_mapping( name => $prefix.'-mapping', scope_name => $prefix,
      expression => 'return {"probe": True}' );
  } );

  $provider = twice( provider => sub {
    $api->ensure_oauth2_provider(
      name                    => $prefix,
      authorization_flow_slug => 'default-provider-authorization-implicit-consent',
      invalidation_flow_slug  => 'default-provider-invalidation-flow',
      client_type             => 'confidential',
      grant_types             => [qw( authorization_code refresh_token client_credentials
                                      urn:ietf:params:oauth:grant-type:device_code )],
      # written without redirect_uri_type, which authentik fills in
      redirect_uris           => [ { matching_mode => 'strict', url => 'https://app.example.org/cb' } ],
      scopes                  => [qw( openid email profile offline_access )],
      signing_key_name        => 'authentik Self-signed Certificate',
      sub_mode                => 'hashed_user_id'
    );
  } )->{object};
  is( scalar @{ $provider->{property_mappings} }, 4, 'the scopes became property mappings' );
  is( $provider->{redirect_uris}[0]{redirect_uri_type}, 'authorization', 'and authentik filled the type in' );

  twice( application => sub {
    $api->ensure_application( slug => $prefix, name => 'Live Test '.$prefix, provider_name => $prefix );
  } );

  twice( flow => sub {
    $api->ensure_flow( slug => $prefix.'-flow', name => 'Live '.$prefix, title => 'Live',
      designation => 'authentication' );
  } );
  twice( stage => sub {
    $api->ensure_stage( password => name => $prefix.'-password',
      backends => ['authentik.core.auth.InbuiltBackend'] );
  } );
  twice( binding => sub {
    $api->ensure_binding( flow => $prefix.'-flow', stage => $prefix.'-password', order => 20 );
  } );
  twice( token => sub {
    $api->ensure_token( identifier => $prefix.'-token', intent => 'api', expiring => \0,
      user_name => $api->me->{user}{username} );
  } );

  # one changed key is one write, and nothing else moves. The trailing
  # newline is the point: authentik trims every text field it stores, so a
  # wanted value carrying one must still settle instead of reporting a change
  # for ever.
  my $changed = $api->ensure_application( slug => $prefix, meta_description => "changed\n" );
  is( $changed->{changed}, 'updated', 'a changed key' );
  is( $changed->{object}{meta_description}, 'changed', 'authentik stored it trimmed' );
  is( $api->find_application($prefix)->{name}, 'Live Test '.$prefix, 'and the rest is untouched' );
  is( $api->ensure_application( slug => $prefix, meta_description => "changed\n" )->{changed}, '',
    'and settles, although what was asked for can never be stored' );

  my $without = error_of {
    $api->ensure_oauth2_provider( name => $prefix.'-second',
      authorization_flow_slug => 'default-provider-authorization-implicit-consent',
      invalidation_flow_slug  => 'default-provider-invalidation-flow', redirect_uris => [] );
  };
  isa_ok( $without, 'WWW::Authentik::Error::Validation', 'creating a provider without grant_types' );

  my $duplicate = error_of { $api->create_group( { name => $prefix.'-group' } ) };
  is( $duplicate->http_status, 400, 'a duplicate really is 400 on the real thing' );
  ok( scalar keys %{ $duplicate->field_errors }, 'with a field error' );
};

my %client;

subtest 'OIDC' => sub {
  %client = ( client_id => $provider->{client_id}, client_secret => $provider->{client_secret} );
  my $oidc = $ak->oidc;

  is( $oidc->issuer, $ENV{AUTHENTIK_URL}.'/application/o/'.$prefix.'/', 'the issuer out of the discovery document' );
  ok( scalar @{ $oidc->jwks->{keys} }, 'jwks' );
  like( $oidc->token_endpoint, qr{/application/o/token/\z}, 'the token endpoint is instance wide' );

  my $tokens = $oidc->client_credentials_token( %client, scope => 'openid email profile' );
  ok( $tokens->{access_token}, 'client credentials' );
  my $access = $oidc->verify_token( $tokens->{access_token}, audience => $client{client_id}, type => 'access' );
  is( $access->{azp}, $client{client_id}, 'the access token verifies' );
  ok( $oidc->verify_token( $tokens->{id_token}, type => 'id' ), 'and the ID token' );
  like( error_of { $oidc->verify_token( $tokens->{id_token}, type => 'access' ) }, qr/no scope claim/,
    'an ID token is not an access token' );
  isa_ok( error_of { $oidc->verify_token( $tokens->{access_token}, audience => 'somebody-else' ) },
    'WWW::Authentik::Error::Validation', 'a wrong audience' );

  # every provider of one authentik signs with the same key, so with
  # issuer_mode: global the audience is all that separates two applications
  ok( $oidc->issuer_names_the_application, 'per_provider: the issuer names the application' );
  $api->update_oauth2_provider( $provider->{pk}, { issuer_mode => 'global' } );
  my $global = WWW::Authentik->new( base_url => $ENV{AUTHENTIK_URL}, application => $prefix )->oidc;
  is( $global->issuer, $ENV{AUTHENTIK_URL}.'/', 'global: the issuer is the bare instance' );
  ok( !$global->issuer_names_the_application, 'and does not name the application' );
  my $wide = $global->client_credentials_token( %client, scope => 'openid' );
  my $refused = error_of { $global->verify_token( $wide->{access_token} ) };
  isa_ok( $refused, 'WWW::Authentik::Error::Validation', 'verifying without an audience' );
  like( "$refused", qr/does not name the application/, 'and says why' );
  ok( $global->verify_token( $wide->{access_token}, audience => $client{client_id} ), 'an audience makes it work' );
  ok( $global->verify_token( $wide->{access_token}, any_audience => 1 ), 'and any_audience says you meant it' );
  my $pinned = WWW::Authentik->new( base_url => $ENV{AUTHENTIK_URL}, application => $prefix,
    client_id => $client{client_id} )->oidc;
  ok( $pinned->verify_token( $wide->{access_token} ), 'client_id on the client does it by itself' );
  $api->update_oauth2_provider( $provider->{pk}, { issuer_mode => 'per_provider' } );

  ok( $oidc->userinfo( $tokens->{access_token} )->{sub}, 'userinfo' );
  ok( $oidc->introspect( $tokens->{access_token}, %client )->{active}, 'introspect says active' );
  ok( $oidc->revoke( $tokens->{access_token}, %client ), 'revoke' );
  ok( !$oidc->introspect( $tokens->{access_token}, %client )->{active}, 'and it is gone' );
  is( error_of { $oidc->userinfo( $tokens->{access_token} ) }->oauth_error, 'invalid_token', 'userinfo refuses it' );

  # the device authorization endpoint is throttled on its own, 20/hour per
  # client IP by default, and then answers 429 slow_down before any device
  # flow begins. A handful of runs within an hour is enough, so say what it
  # is instead of failing on a bare OAuth code.
  my $start;
  my $failed = error_of { $start = $oidc->device_authorization( %client, scope => 'openid' ) };
  my $status = ref $failed ? eval { $failed->http_status } : undef;
  BAIL_OUT( 'the device authorization endpoint is throttled: authentik allows 20 requests an hour '
    .'per client IP, raise AUTHENTIK_THROTTLE__PROVIDERS__OAUTH2__DEVICE on the instance' )
    if $status && $status == 429;
  die $failed if $failed;
  like( $start->{verification_uri_complete}, qr/\Q$start->{user_code}\E/, 'device_authorization' );
  my $pending = error_of { $oidc->device_token( device_code => $start->{device_code}, %client ) };
  is( $pending->oauth_error, 'authorization_pending', 'the first poll is pending' );
};

subtest 'a login and the second factor' => sub {
  my %authorize = ( client_id => $client{client_id}, redirect_uri => 'https://app.example.org/cb',
    scope => 'openid email profile offline_access', state => 'live', nonce => 'live' );
  my $oidc = $ak->oidc;

  my $browser = AuthentikExecutor->new( base_url => $ENV{AUTHENTIK_URL} );
  ok( $browser->login( username => $prefix, password => $password ), 'a login with the password alone' );
  is( $browser->whoami->{username}, $prefix, 'and there is a session' );

  my $code   = $browser->authorization_code(%authorize);
  my $tokens = $oidc->exchange_authorization_code( %client, code => $code, redirect_uri => $authorize{redirect_uri} );
  my $claims = $oidc->verify_token( $tokens->{id_token}, audience => $client{client_id} );
  is_deeply( $claims->{amr}, ['pwd'], 'amr says password only' );
  ok( $claims->{auth_time}, 'auth_time is there' );
  is( $claims->{acr}, 'goauthentik.io/providers/oauth2/default', 'acr is the one constant value' );

  my $refreshed = $oidc->refresh_token( $tokens->{refresh_token}, %client );
  my $after = $oidc->verify_token( $refreshed->{id_token} );
  is_deeply( $after->{amr}, ['pwd'], 'amr survives a refresh' );
  is( $after->{auth_time}, $claims->{auth_time}, 'and so does auth_time' );
  is( error_of { $oidc->refresh_token( $tokens->{refresh_token}, %client ) }->oauth_error, 'invalid_grant',
    'the refresh token was rotated' );

  my $secret = $browser->enroll_totp;
  ok( $secret, 'TOTP enrolled through the setup flow' );
  ok( scalar @{ $api->list_authenticators( $user->{pk} ) }, 'and the device shows up in the API' );

  my $second = AuthentikExecutor->new( base_url => $ENV{AUTHENTIK_URL} );
  ok( $second->login( username => $prefix, password => $password, totp_secret => $secret ),
    'a login with the password and the code' );
  my $mfa = $oidc->verify_token(
    $oidc->exchange_authorization_code( %client, redirect_uri => $authorize{redirect_uri},
      code => $second->authorization_code(%authorize) )->{id_token}
  );
  is_deeply( $mfa->{amr}, [qw( pwd mfa )], 'amr now says the second factor was used' );
  is( $mfa->{acr}, $claims->{acr}, 'acr still does not tell the two apart' );

  my $denied = AuthentikExecutor->new( base_url => $ENV{AUTHENTIK_URL} );
  my $failed = error_of { $denied->login( username => $prefix, password => 'the-wrong-password' ) };
  ok( $failed, 'a wrong password does not get in' );
};

subtest 'check_access' => sub {
  my $mine = $api->check_access($prefix);
  ok( exists $mine->{passing}, 'check_access answers for the token owner' );
  ok( exists $api->check_access( $prefix, for_user => $user->{pk} )->{passing}, 'and for a named user' );

  # a stale id cannot pass for an answer
  my $stale = error_of { $api->check_access( $prefix, for_user => 999_999 ) };
  isa_ok( $stale, 'WWW::Authentik::Error::API', 'a user that does not exist' );
  is( $stale->http_status, 400, 'is a field error' );
  is_deeply( $stale->field_errors, { for_user => ['User not found'] },
    'whose value authentik sends as a bare string, not a list' );

  # except for primary key 1, which is authentik's internal AnonymousUser:
  # check_access takes it although the user endpoints deny it exists
  ok( exists $api->check_access( $prefix, for_user => 1 )->{passing}, 'primary key 1 is accepted' );
  ok( error_of { $api->get_user(1) }->is_not_found, 'while get_user says there is no user 1' );
};

subtest 'clean up' => sub {
  ok( $api->delete_application($prefix), 'application deleted' );
  is( $api->find_application($prefix), undef, 'and gone' );
  ok( $api->delete_oauth2_provider( $provider->{pk} ), 'provider deleted' );
  is( $api->find_oauth2_provider($prefix), undef, 'and gone' );
  ok( $api->delete_user( $user->{pk} ), 'user deleted' );
  is( $api->find_user($prefix), undef, 'and gone' );

  # authentik leaves the service account of the client credentials grant
  # behind when the provider goes; the END block takes it as well
  my $service_account = $api->find_user( 'ak-'.$prefix.'-client_credentials' );
  ok( $service_account, 'the client credentials service account outlives its provider' );
  ok( $api->delete_user( $service_account->{pk} ), 'and has to be deleted on its own' );
};

done_testing;
