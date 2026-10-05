package WWW::Authentik::OIDC;

# ABSTRACT: OpenID Connect against one authentik application

use Moo;
with 'WWW::Authentik::Role::HTTP';
use Crypt::JWT qw( decode_jwt );
use Types::Standard qw( ArrayRef CodeRef InstanceOf Int Str );
use URI;
use WWW::Authentik::Error::Validation;
use namespace::autoclean;

our $VERSION = '0.001';


has application_url => (
  is       => 'ro',
  isa      => Str,
  required => 1
);


has ua => (
  is       => 'ro',
  isa      => InstanceOf['LWP::UserAgent'],
  required => 1
);


has client_id => (
  is        => 'ro',
  isa       => Str,
  predicate => 'has_client_id'
);


has algorithms => (
  is      => 'ro',
  isa     => ArrayRef[Str],
  default => sub { [qw( RS256 RS384 RS512 PS256 PS384 PS512 ES256 ES384 ES512 )] }
);


has jwks_min_age => (
  is      => 'ro',
  isa     => Int,
  default => 60
);


has now => (
  is      => 'ro',
  isa     => CodeRef,
  default => sub { sub { time } }
);


has discovery => (
  is       => 'lazy',
  init_arg => undef
);

sub _build_discovery {
  my ( $self ) = @_;
  my $data = $self->send_request( GET => $self->application_url.'/.well-known/openid-configuration' )->{data};
  WWW::Authentik::Error::Validation->throw( message => 'discovery for '.$self->application_url.' returned no JSON object' )
    unless ref $data eq 'HASH';
  return $data;
}


has _jwks         => ( is => 'rw', init_arg => undef );
has _jwks_fetched => ( is => 'rw', init_arg => undef );

sub endpoint {
  my ( $self, $name ) = @_;
  my $url = $self->discovery->{$name};
  WWW::Authentik::Error::Validation->throw( message => 'the discovery document of '.$self->application_url.' has no '.$name )
    unless defined $url;
  return $url;
}


sub issuer                 { $_[0]->endpoint('issuer') }
sub authorization_endpoint { $_[0]->endpoint('authorization_endpoint') }
sub token_endpoint         { $_[0]->endpoint('token_endpoint') }
sub userinfo_endpoint      { $_[0]->endpoint('userinfo_endpoint') }
sub introspection_endpoint { $_[0]->endpoint('introspection_endpoint') }
sub revocation_endpoint    { $_[0]->endpoint('revocation_endpoint') }
sub end_session_endpoint   { $_[0]->endpoint('end_session_endpoint') }
sub device_endpoint        { $_[0]->endpoint('device_authorization_endpoint') }
sub jwks_uri               { $_[0]->endpoint('jwks_uri') }


sub jwks {
  my ( $self, %opt ) = @_;
  if ( $opt{force_refresh} || !$self->_jwks ) {
    $self->_jwks( $self->send_request( GET => $self->jwks_uri )->{data} );
    $self->_jwks_fetched( $self->now->() );
  }
  return $self->_jwks;
}


sub issuer_names_the_application {
  my ( $self ) = @_;
  return $self->issuer eq $self->application_url.'/' ? 1 : 0;
}

sub verify_token {
  my ( $self, $token, %opt ) = @_;
  WWW::Authentik::Error::Validation->throw( message => 'verify_token needs a token' )
    unless defined $token && length $token;
  WWW::Authentik::Error::Validation->throw( message => "verify_token: type must be 'access' or 'id'" )
    if defined $opt{type} && $opt{type} ne 'access' && $opt{type} ne 'id';
  my $audience = exists $opt{audience} ? $opt{audience}
    : $self->has_client_id            ? $self->client_id
    :                                   undef;
  # Every provider of one authentik signs with the same key, so the issuer is
  # all that separates two applications - and with issuer_mode: global it is
  # the bare instance URL, the same for all of them. Then only the audience
  # tells them apart, and verifying without one would accept any token the
  # instance ever issued.
  WWW::Authentik::Error::Validation->throw( message => 'verify_token cannot tell this application apart: '
    .'the provider issues tokens as "'.$self->issuer.'", which does not name the application, so a token '
    .'of any other application of this authentik would pass. Give an audience, set client_id on the client, '
    .'or say any_audience => 1 if you really mean to accept them all.' )
    if !defined $audience && !$opt{any_audience} && !$self->issuer_names_the_application;
  my %check = (
    token          => $token,
    verify_iss     => $self->issuer,
    verify_exp     => 1,
    accepted_alg   => $self->algorithms,
    decode_payload => 1,
    defined $audience ? ( verify_aud => $audience ) : ()
  );
  my $claims = eval { decode_jwt( %check, kid_keys => $self->jwks ) };
  my $error  = $@;
  # a key authentik rotated in since the keys were fetched: fetch them again,
  # but only for that reason and not more often than jwks_min_age allows
  if ( !$claims && $error =~ /kid_keys lookup failed/ && $self->now->() - ( $self->_jwks_fetched // 0 ) >= $self->jwks_min_age ) {
    $claims = eval { decode_jwt( %check, kid_keys => $self->jwks( force_refresh => 1 ) ) };
    $error  = $@;
  }
  $self->_reject( $error =~ s/ at \S+ line \d+.*//sr ) unless $claims;
  if ( defined $opt{type} ) {
    my $looks_like_access = exists $claims->{scope} ? 1 : 0;
    $self->_reject('not an access token: it carries no scope claim')
      if $opt{type} eq 'access' && !$looks_like_access;
    $self->_reject('not an ID token: it carries a scope claim')
      if $opt{type} eq 'id' && $looks_like_access;
  }
  return $claims;
}

sub _reject {
  my ( $self, $why ) = @_;
  WWW::Authentik::Error::Validation->throw( message => 'token rejected: '.$why );
}


sub userinfo {
  my ( $self, $access_token ) = @_;
  WWW::Authentik::Error::Validation->throw( message => 'userinfo needs an access token' )
    unless defined $access_token && length $access_token;
  return $self->send_request( GET => $self->userinfo_endpoint, bearer => $access_token )->{data};
}


sub introspect {
  my ( $self, $token, %client ) = @_;
  return $self->_token_call( $self->introspection_endpoint,
    { token => $token, defined $client{token_type_hint} ? ( token_type_hint => $client{token_type_hint} ) : () }, %client );
}


sub revoke {
  my ( $self, $token, %client ) = @_;
  $self->_token_call( $self->revocation_endpoint,
    { token => $token, defined $client{token_type_hint} ? ( token_type_hint => $client{token_type_hint} ) : () }, %client );
  return 1;
}


sub client_credentials_token {
  my ( $self, %arg ) = @_;
  return $self->_grant( client_credentials => [qw( scope username password )], %arg );
}


sub refresh_token {
  my ( $self, $refresh, %arg ) = @_;
  return $self->_grant( refresh_token => [qw( refresh_token scope )], %arg, refresh_token => $refresh );
}


sub exchange_authorization_code {
  my ( $self, %arg ) = @_;
  return $self->_grant( authorization_code => [qw( code redirect_uri code_verifier )], %arg );
}


sub device_authorization {
  my ( $self, %arg ) = @_;
  return $self->_token_call( $self->device_endpoint,
    { defined $arg{scope} ? ( scope => $arg{scope} ) : () }, %arg );
}


sub device_token {
  my ( $self, %arg ) = @_;
  return $self->_grant( 'urn:ietf:params:oauth:grant-type:device_code' => ['device_code'], %arg );
}


sub authorization_url {
  my ( $self, %arg ) = @_;
  WWW::Authentik::Error::Validation->throw( message => 'authorization_url needs a client_id' ) unless defined $arg{client_id};
  WWW::Authentik::Error::Validation->throw( message => 'authorization_url needs a redirect_uri' ) unless defined $arg{redirect_uri};
  my $uri = URI->new( $self->authorization_endpoint );
  $uri->query_form(
    response_type => $arg{response_type} // 'code',
    map { $_ => $arg{$_} } grep { defined $arg{$_} }
      qw( client_id redirect_uri scope state nonce prompt max_age acr_values
          code_challenge code_challenge_method response_mode )
  );
  return $uri->as_string;
}


sub _grant {
  my ( $self, $type, $fields, %arg ) = @_;
  return $self->_token_call( $self->token_endpoint,
    { grant_type => $type, map { $_ => $arg{$_} } grep { defined $arg{$_} } @$fields }, %arg );
}

sub _token_call {
  my ( $self, $url, $form, %arg ) = @_;
  WWW::Authentik::Error::Validation->throw( message => 'a client_id is needed' ) unless defined $arg{client_id};
  my %form = (
    %$form,
    client_id => $arg{client_id},
    defined $arg{client_secret} ? ( client_secret => $arg{client_secret} ) : ()
  );
  return $self->send_request( POST => $url, form => \%form )->{data} // {};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Authentik::OIDC - OpenID Connect against one authentik application

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $oidc = WWW::Authentik->new( base_url => $url, application => 'my-app' )->oidc;

    my $claims = $oidc->verify_token( $jwt, type => 'access' );
    my $tokens = $oidc->client_credentials_token( client_id => $id, client_secret => $secret, scope => 'openid' );

    # give the client id once and every verify_token checks the audience
    my $safe = WWW::Authentik->new( base_url => $url, application => 'my-app', client_id => $id )->oidc;

=head1 DESCRIPTION

The OpenID Connect side of one application: discovery, the signing keys,
token verification, and the token endpoint in the grant types authentik
offers.

Endpoints come from the application's discovery document, fetched once and
kept. Only discovery, the keys and the end-session endpoint live under the
application slug; the token, userinfo, introspection, revocation and device
endpoints are shared by the whole instance, and the discovery document names
them.

An error from the token endpoint is a L<WWW::Authentik::Error::API> whose
C<oauth_error> carries the OAuth code, so a device-flow poll can tell
C<authorization_pending> from a real failure.

There is no direct grant for a normal user: authentik's C<grant_type=password>
is the same door as C<client_credentials> with a username, and it only opens
for a service account with an app-password token. A login as a person goes
through the flow executor, which is not part of this distribution.

=head2 application_url

Required. C<< <base_url>/application/o/<slug> >>, without a trailing slash.

=head2 ua

Required. The L<LWP::UserAgent> to use.

=head2 client_id

The client id of this application's provider. When it is set, L</verify_token>
checks it as the audience unless the caller names another one. Setting it is
the simple way to be safe on an instance whose providers issue tokens under a
shared issuer; see L</verify_token>.

=head2 algorithms

Signature algorithms L</verify_token> accepts. Never C<none>, never HMAC.
authentik signs with C<RS256>.

=head2 jwks_min_age

Seconds that have to pass before L</verify_token> fetches the keys again for
a token signed with an unknown key. Default 60, so that a stream of forged
tokens does not become a stream of requests to authentik.

=head2 now

Coderef returning the current epoch. For tests.

=head2 discovery

The discovery document, fetched on first use and kept.

=head2 endpoint

    my $url = $oidc->endpoint('device_authorization_endpoint');

A URL from the discovery document. Throws when it is missing.

=head2 issuer

    print $oidc->issuer;   # https://id.example.org/application/o/my-app/

What authentik puts into C<iss> and what L</verify_token> checks against. With
the provider set to C<issuer_mode: global> this is the bare instance URL, not
the application address.

=head2 authorization_endpoint

=head2 token_endpoint

=head2 userinfo_endpoint

=head2 introspection_endpoint

=head2 revocation_endpoint

=head2 end_session_endpoint

=head2 device_endpoint

=head2 jwks_uri

The endpoints out of the discovery document.

=head2 jwks

    my $keys = $oidc->jwks;
    my $keys = $oidc->jwks( force_refresh => 1 );

The application's public signing keys, kept after the first fetch.

=head2 issuer_names_the_application

True when the issuer out of the discovery document is this application's own
address, which is what C<issuer_mode: per_provider> gives. False under
C<issuer_mode: global>, where every provider of the instance issues tokens
under the bare instance URL.

=head2 verify_token

    my $claims = $oidc->verify_token( $jwt );
    my $claims = $oidc->verify_token( $jwt, audience => $client_id, type => 'access' );

Checks signature, issuer and expiry, and the audience. Returns the claims, or
throws a L<WWW::Authentik::Error::Validation> saying why the token was
rejected. When the signing key is unknown the keys are fetched again, at most
once per L</jwks_min_age>.

B<The audience is what separates two applications of one authentik.> Every
provider of an instance signs with the same key, so the issuer is the only
other thing that could tell them apart — and with C<issuer_mode: global> the
issuer is the bare instance URL, the same for all of them. Verifying without
an audience on such an instance would accept any token it ever issued, so
this method refuses to do it: give C<audience>, set L</client_id> on the
client so it is used by itself, or pass C<< any_audience => 1 >> to say that
accepting every application of this authentik is what you meant. Under the
default C<issuer_mode: per_provider> the issuer already names the
application, and an audience is then optional.

C<type> is a B<heuristic>, and a weak one. authentik signs ID tokens and
access tokens the same way and puts no C<typ> into the JOSE header: both are
C<RS256> JWTs with C<"typ": "JWT">. The only reliable difference observed is
that an access token carries a C<scope> claim and an ID token does not. So
C<< type => 'access' >> rejects a token without C<scope>, C<< type => 'id' >>
rejects one with it, and neither is a cryptographic distinction. Without
C<type> the kind of token is not checked at all. Where it matters that a
token was meant for a particular API, check C<audience>.

=head2 userinfo

    my $info = $oidc->userinfo($access_token);

The claims authentik gives out for this token. A token it does not accept is
a L<WWW::Authentik::Error::API> with status 401 and C<oauth_error>
C<invalid_token>, read out of the C<WWW-Authenticate> header, because the
body is empty.

=head2 introspect

    my $state = $oidc->introspect( $token, client_id => $id, client_secret => $secret );

Needs a confidential client. An access token and a refresh token both come
back with C<< active => true >> and their claims; anything else, including a
token the client is not allowed to see, is C<< { active => false } >> with
status 200.

=head2 revoke

    $oidc->revoke( $access_token, client_id => $id, client_secret => $secret );

Ends a token. authentik answers 200 for a token it does not know as well, so
a true return means the call went through, not that something was revoked. A
wrong client secret is a 401 C<invalid_client>.

=head2 client_credentials_token

    my $tokens = $oidc->client_credentials_token( client_id => $id, client_secret => $secret, scope => 'openid' );
    my $tokens = $oidc->client_credentials_token( client_id => $id, username => 'svc', password => $app_password );

The client credentials grant. With a client secret the token belongs to the
service account authentik creates for the provider
(C<< ak-<provider>-client_credentials >>). With C<username> and C<password>
it belongs to that service account, where the password is the app-password
token C<< WWW::Authentik::API->create_service_account >> handed out.

=head2 refresh_token

    my $tokens = $oidc->refresh_token( $refresh, client_id => $id, client_secret => $secret );

authentik rotates refresh tokens: the answer carries a new one and the old
one is dead. Asking for fewer scopes than were granted is an
C<invalid_scope>. The claims, including C<amr> and C<auth_time>, carry over
unchanged.

=head2 exchange_authorization_code

    my $tokens = $oidc->exchange_authorization_code( code => $code, redirect_uri => $uri,
      client_id => $id, client_secret => $secret );

A code can be exchanged once; the second try is an C<invalid_grant>.

=head2 device_authorization

    my $start = $oidc->device_authorization( client_id => $id, scope => 'openid' );

Starts a device flow: C<device_code>, C<user_code>, C<verification_uri>,
C<verification_uri_complete>, C<expires_in> and C<interval>. The brand needs
a C<flow_device_code> for a person to be able to approve it.

=head2 device_token

    my $tokens = eval { $oidc->device_token( device_code => $start->{device_code},
      client_id => $id, client_secret => $secret ) };
    # $@->oauth_error eq 'authorization_pending' while nobody has approved

One poll of the device flow; the loop is the caller's. authentik answers
C<authorization_pending> however fast the polling is and never
C<slow_down>, and an expired or already used code is an C<invalid_grant>.

=head2 authorization_url

    my $url = $oidc->authorization_url( client_id => $id, redirect_uri => $uri,
      scope => 'openid email', state => $state, nonce => $nonce );

The address a browser is sent to. This distribution does not follow it:
without a session authentik answers 302 into its own flow interface, and
driving that is a browser's job, or the flow executor's.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-authentik/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
