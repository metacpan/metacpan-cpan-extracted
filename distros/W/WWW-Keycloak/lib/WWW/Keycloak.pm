package WWW::Keycloak;

# ABSTRACT: Perl client for Keycloak identity management (OIDC + Admin REST API)

use Moo;
use LWP::UserAgent;
use Types::Standard qw( InstanceOf Str );
use URI::Escape qw( uri_escape_utf8 );
use WWW::Keycloak::Admin;
use WWW::Keycloak::Auth;
use WWW::Keycloak::Error;
use WWW::Keycloak::Error::API;
use WWW::Keycloak::Error::Network;
use WWW::Keycloak::Error::Validation;
use WWW::Keycloak::OIDC;
use namespace::autoclean;

our $VERSION = '0.001';


has base_url => (
  is       => 'ro',
  isa      => Str,
  required => 1
);


has realm => (
  is       => 'ro',
  isa      => Str,
  required => 1
);


has username      => ( is => 'ro', isa => Str, predicate => 'has_username' );
has password      => ( is => 'ro', isa => Str );
has client_id     => ( is => 'ro', isa => Str, predicate => 'has_client_id' );
has client_secret => ( is => 'ro', isa => Str );
has token         => ( is => 'ro', isa => Str, predicate => 'has_token' );


has auth_realm => (
  is  => 'lazy',
  isa => Str
);

sub _build_auth_realm { $_[0]->has_username ? 'master' : $_[0]->realm }


has ua => (
  is  => 'lazy',
  isa => InstanceOf['LWP::UserAgent']
);

sub _build_ua {
  # no redirects: nothing here needs one, and none may carry the admin token elsewhere
  return LWP::UserAgent->new( timeout => 30, agent => 'WWW-Keycloak/'.$VERSION, max_redirect => 0, ssl_opts => { verify_hostname => 1 } );
}


has auth => (
  is  => 'lazy',
  isa => InstanceOf['WWW::Keycloak::Auth'] | Types::Standard::Undef
);

sub _build_auth {
  my ( $self ) = @_;
  return WWW::Keycloak::Auth->new( ua => $self->ua, token => $self->token ) if $self->has_token;
  return unless $self->has_username || $self->has_client_id;
  return WWW::Keycloak::Auth->new(
    ua             => $self->ua,
    token_endpoint => $self->base_url.'/realms/'.uri_escape_utf8( $self->auth_realm ).'/protocol/openid-connect/token',
    map { $_ => $self->$_ } grep { defined $self->$_ } qw( username password client_id client_secret )
  );
}


has oidc => (
  is       => 'lazy',
  init_arg => undef
);

sub _build_oidc {
  my ( $self ) = @_;
  return WWW::Keycloak::OIDC->new( issuer => $self->issuer, ua => $self->ua );
}


has admin => (
  is       => 'lazy',
  init_arg => undef
);

sub _build_admin {
  my ( $self ) = @_;
  return WWW::Keycloak::Admin->new(
    base_url => $self->base_url,
    realm    => $self->realm,
    ua       => $self->ua,
    $self->auth ? ( auth => $self->auth ) : ()
  );
}


around BUILDARGS => sub {
  my ( $orig, $class, @args ) = @_;
  my $args = $class->$orig(@args);
  $args->{base_url} =~ s{/+\z}{} if defined $args->{base_url};
  return $args;
};

sub BUILD {
  my ( $self ) = @_;
  for (qw( base_url realm )) {
    WWW::Keycloak::Error::Validation->throw( message => __PACKAGE__.' needs a '.$_ ) unless length $self->$_;
  }
  return;
}

sub issuer { $_[0]->base_url.'/realms/'.uri_escape_utf8( $_[0]->realm ) }


sub for_realm {
  my ( $self, $realm ) = @_;
  return ref($self)->new(
    base_url   => $self->base_url,
    realm      => $realm,
    ua         => $self->ua,
    auth_realm => $self->auth_realm,
    $self->auth ? ( auth => $self->auth ) : ()
  );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Keycloak - Perl client for Keycloak identity management (OIDC + Admin REST API)

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use WWW::Keycloak;

    my $kc = WWW::Keycloak->new(
      base_url => 'https://id.example.org',
      realm    => 'main',
      username => 'admin',            # or client_id + client_secret, or token
      password => $ENV{KEYCLOAK_ADMIN_PASSWORD},
    );

    # OpenID Connect
    my $claims = $kc->oidc->verify_token( $jwt, audience => 'my-api' );

    # Admin REST API, repeatable
    $kc->admin->ensure_client( clientId => 'my-cli', publicClient => \1 );
    $kc->admin->ensure_user( username => 'alice', enabled => \1 );

    # another realm, same login
    my $dev = $kc->for_realm('dev');

=head1 DESCRIPTION

A client for Keycloak in two parts: L<WWW::Keycloak::OIDC> for what an
application does with a realm, and L<WWW::Keycloak::Admin> for bringing a
realm into a wanted state from Perl, repeatably.

The realm is part of every address in Keycloak, so it is a required attribute
here and not an argument of each method. L</for_realm> gives the same client
for another realm.

The admin login is managed for you: L<WWW::Keycloak::Auth> fetches a token,
renews it before it runs out and once more when Keycloak refuses it.

=head2 base_url

Required. Where Keycloak is, without C</realms/...>. A trailing slash is
removed.

=head2 realm

Required. The realm to work with.

=head2 username

=head2 password

Admin login with a password, through the C<admin-cli> client of
L</auth_realm>.

=head2 client_id

=head2 client_secret

Admin login as a service-account client.

=head2 token

A ready admin token, used as it is.

=head2 auth_realm

The realm the admin logs in to. Default C<master> for a password login, the
own realm for a service account.

=head2 ua

The L<LWP::UserAgent> every part shares. The default follows no redirects.

=head2 auth

The L<WWW::Keycloak::Auth>, or undef when no admin login was given.

=head2 oidc

The L<WWW::Keycloak::OIDC> of this realm.

=head2 admin

The L<WWW::Keycloak::Admin> of this realm.

=head2 issuer

    print $kc->issuer;   # https://id.example.org/realms/main

=head2 for_realm

    my $dev = $kc->for_realm('dev');

The same client for another realm, sharing the user agent and the admin
login.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-keycloak/issues>.

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
