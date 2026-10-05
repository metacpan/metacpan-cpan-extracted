#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use LWP::UserAgent;
use FakeAuthentik;
use WWW::Authentik;

sub error_of (&) { my ( $code ) = @_; eval { $code->(); 1 } ? undef : $@ }

subtest 'base_url' => sub {
  my $missing = error_of { WWW::Authentik->new };
  ok( $missing, 'base_url is required' );
  isa_ok( error_of { WWW::Authentik->new( base_url => '' ) }, 'WWW::Authentik::Error::Validation', 'an empty base_url' );
  is( WWW::Authentik->new( base_url => 'https://id.example.org/' )->base_url, 'https://id.example.org', 'a trailing slash is removed' );
  is( WWW::Authentik->new( base_url => 'https://id.example.org///' )->base_url, 'https://id.example.org', 'several of them too' );
};

subtest 'addresses' => sub {
  my $ak = WWW::Authentik->new( base_url => 'https://id.example.org', application => 'my-app', token => 't' );
  is( $ak->api_url, 'https://id.example.org/api/v3', 'api_url' );
  is( $ak->application_url, 'https://id.example.org/application/o/my-app', 'application_url' );
  is( $ak->issuer, 'https://id.example.org/application/o/my-app/', 'issuer' );
  is( WWW::Authentik->new( base_url => 'https://id.example.org', application => 'a b' )->application_url,
      'https://id.example.org/application/o/a%20b', 'the slug is URI encoded' );
};

subtest 'sub clients' => sub {
  my $without = WWW::Authentik->new( base_url => 'https://id.example.org' );
  my $no_slug = error_of { $without->oidc };
  isa_ok( $no_slug, 'WWW::Authentik::Error::Validation', 'oidc without an application' );
  like( "$no_slug", qr/application slug/, 'and says so' );
  my $no_token = error_of { $without->api };
  isa_ok( $no_token, 'WWW::Authentik::Error::Validation', 'api without a token' );
  like( "$no_token", qr/API token/, 'and says so' );

  my $ak = WWW::Authentik->new( base_url => 'https://id.example.org', application => 'my-app', token => 'secret-token' );
  isa_ok( $ak->oidc, 'WWW::Authentik::OIDC' );
  isa_ok( $ak->api, 'WWW::Authentik::API' );
  is( $ak->oidc, $ak->oidc, 'the same OIDC object every time' );
  is( $ak->oidc->ua, $ak->api->ua, 'both share the user agent' );
  is( $ak->api->token, 'secret-token', 'the token reaches the API client' );
  my $forged = WWW::Authentik->new( base_url => 'https://id.example.org', application => 'my-app', token => 't', oidc => 'forged', api => 'forged' );
  isa_ok( $forged->oidc, 'WWW::Authentik::OIDC', 'oidc cannot be set from outside, it' );
  isa_ok( $forged->api, 'WWW::Authentik::API', 'and neither can api, it' );
};

subtest 'the user agent' => sub {
  my $default = WWW::Authentik->new( base_url => 'https://id.example.org' )->ua;
  isa_ok( $default, 'LWP::UserAgent' );
  is( $default->max_redirect, 0, 'the default user agent follows no redirects' );
  # authentik 2026.8.3 hangs on every second request that announces TE
  is( $default->{send_te}, 0, 'and does not announce the TE connection token' );
  like( $default->agent, qr{\AWWW-Authentik/}, 'and says who it is' );
  is( WWW::Authentik->default_ua->{send_te}, 0, 'default_ua builds the same thing for a caller' );

  my $fake = FakeAuthentik->new;
  my $ak   = WWW::Authentik->new( base_url => $fake->base, application => 'a', token => 't', ua => $fake );
  is( $ak->ua, $fake, 'an injected user agent is used' );
  is( $ak->api->ua, $fake, 'by the API client' );
  is( $ak->oidc->ua, $fake, 'and by the OIDC client' );
};

subtest 'for_application' => sub {
  my $fake = FakeAuthentik->new;
  my $ak   = WWW::Authentik->new( base_url => $fake->base, application => 'one', token => 't', ua => $fake );
  my $other = $ak->for_application('two');
  isa_ok( $other, 'WWW::Authentik' );
  is( $other->application, 'two', 'another application' );
  is( $other->base_url, $ak->base_url, 'same instance' );
  is( $other->ua, $ak->ua, 'same user agent object' );
  is( $other->token, 't', 'same token' );
  isnt( $other->oidc, $ak->oidc, 'but its own OIDC client' );

  my $anonymous = WWW::Authentik->new( base_url => 'https://id.example.org' )->for_application('two');
  ok( !$anonymous->has_token, 'without a token it stays without one' );
};

done_testing;
