package WWW::Authentik;

# ABSTRACT: Perl client for the authentik identity provider (OIDC + REST API v3)

use Moo;
use LWP::UserAgent;
use Types::Standard qw( InstanceOf Str );
use URI::Escape qw( uri_escape_utf8 );
use WWW::Authentik::API;
use WWW::Authentik::Diff;
use WWW::Authentik::Error;
use WWW::Authentik::Error::API;
use WWW::Authentik::Error::Network;
use WWW::Authentik::Error::Validation;
use WWW::Authentik::OIDC;
use namespace::autoclean;

our $VERSION = '0.001';


has base_url => (
  is       => 'ro',
  isa      => Str,
  required => 1
);


has application => (
  is        => 'ro',
  isa       => Str,
  predicate => 'has_application'
);


has token => (
  is        => 'ro',
  isa       => Str,
  predicate => 'has_token'
);


has client_id => (
  is        => 'ro',
  isa       => Str,
  predicate => 'has_client_id'
);


has ua => (
  is  => 'lazy',
  isa => InstanceOf['LWP::UserAgent']
);

sub _build_ua { $_[0]->default_ua }

sub default_ua {
  my ( $self ) = @_;
  my $ua = LWP::UserAgent->new(
    timeout      => 30,
    agent        => 'WWW-Authentik/'.$VERSION,
    # no redirects: authentik answers 302 wherever it wants a browser, and
    # none of those may carry the API token anywhere
    max_redirect => 0,
    # authentik 2026.8.3 hangs on every second request that announces the TE
    # connection token, which LWP does by default; see below
    send_te      => 0,
    ssl_opts     => { verify_hostname => 1 }
  );
  # An LWP from before 6.33 does not know send_te: it only carps, and only
  # under -w, and the caller would meet the hang in production instead. Say
  # it here, once, loudly.
  WWW::Authentik::Error::Validation->throw( message => 'this LWP::UserAgent ('
    .( $LWP::UserAgent::VERSION // 'unknown version' ).') does not take send_te, so it would announce the TE '
    .'connection token and authentik would leave every second request unanswered. libwww-perl 6.33 or newer '
    .'is needed.' )
    unless defined $ua->{send_te} && !$ua->{send_te};
  return $ua;
}


has oidc => (
  is       => 'lazy',
  init_arg => undef
);

sub _build_oidc {
  my ( $self ) = @_;
  WWW::Authentik::Error::Validation->throw( message => __PACKAGE__.'->oidc needs an application slug' )
    unless $self->has_application && length $self->application;
  return WWW::Authentik::OIDC->new(
    application_url => $self->application_url,
    ua              => $self->ua,
    $self->has_client_id ? ( client_id => $self->client_id ) : ()
  );
}


has api => (
  is       => 'lazy',
  init_arg => undef
);

sub _build_api {
  my ( $self ) = @_;
  WWW::Authentik::Error::Validation->throw( message => __PACKAGE__.'->api needs an API token' )
    unless $self->has_token && length $self->token;
  return WWW::Authentik::API->new( base_url => $self->base_url, token => $self->token, ua => $self->ua );
}


around BUILDARGS => sub {
  my ( $orig, $class, @args ) = @_;
  my $args = $class->$orig(@args);
  $args->{base_url} =~ s{/+\z}{} if defined $args->{base_url};
  return $args;
};

sub BUILD {
  my ( $self ) = @_;
  WWW::Authentik::Error::Validation->throw( message => __PACKAGE__.' needs a base_url' ) unless length $self->base_url;
  return;
}

sub api_url { $_[0]->base_url.'/api/v3' }


sub application_url {
  my ( $self ) = @_;
  WWW::Authentik::Error::Validation->throw( message => __PACKAGE__.'->application_url needs an application slug' )
    unless $self->has_application && length $self->application;
  return $self->base_url.'/application/o/'.uri_escape_utf8( $self->application );
}


sub issuer { $_[0]->application_url.'/' }


sub for_application {
  my ( $self, $slug ) = @_;
  return ref($self)->new(
    base_url    => $self->base_url,
    application => $slug,
    ua          => $self->ua,
    $self->has_token ? ( token => $self->token ) : ()
    # deliberately not the client_id: it belongs to this application's provider
  );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Authentik - Perl client for the authentik identity provider (OIDC + REST API v3)

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use WWW::Authentik;

    my $ak = WWW::Authentik->new(
      base_url    => 'https://id.example.org',
      application => 'my-app',                   # the application slug, for OIDC
      client_id   => $client_id,                 # its provider's client id, checked as the audience
      token       => $ENV{AUTHENTIK_TOKEN},      # an API token, for the REST API
    );

    # OpenID Connect against the application
    my $claims = $ak->oidc->verify_token( $jwt, type => 'access' );

    # REST API v3, repeatable
    $ak->api->ensure_user( username => 'alice', name => 'Alice', password => $pw );
    my $r = $ak->api->ensure_application( slug => 'my-app', name => 'My App', provider_name => 'my-app' );
    print $r->{changed};   # 'created', 'updated' or ''

    # another application, same instance and token
    my $other = $ak->for_application('second-app');

=head1 DESCRIPTION

A client for authentik in two parts: L<WWW::Authentik::OIDC> for what an
application does with its OpenID Connect endpoints, and
L<WWW::Authentik::API> for bringing an authentik into a wanted state from
Perl, repeatably.

authentik has no realm. The API is instance-wide under C<< <base_url>/api/v3/ >>
and needs an API token; OpenID Connect is addressed per application, with
discovery, keys and the end-session endpoint under
C<< <base_url>/application/o/<slug>/ >> and the token, userinfo, introspection,
revocation and device endpoints shared by the whole instance. So L</token> and
L</application> are both optional: without a slug there is no L</oidc>,
without a token there is no L</api>, and either may be left out.

An authentik API token is long-lived and is used as it is. There is no login
to manage and nothing to renew; authentik answers a token it does not accept
with 403, not 401.

=head2 Coming from WWW::Keycloak

The two distributions have the same shape, but two return values differ, and
deliberately. C<create_*> and C<update_*> return the representation, not an
id, because authentik answers a create with the whole object and sends no
C<Location> header. And C<ensure_*> returns
C<< { object => \%rep, changed => ... } >>, not C<< { id => ..., changed => ... } >>,
because authentik has no single kind of identifier: an application is
addressed by its slug, a provider by an integer, a group by a UUID, a token by
its identifier. The caller almost always needs the next key out of the object
anyway.

Developed and tested against authentik 2026.8.3.

=head2 base_url

Required. Where authentik is, without C</api/v3> and without
C</application/o/>. Trailing slashes are removed.

=head2 application

The slug of the application L</oidc> talks to. Without it L</oidc> throws a
validation error.

=head2 token

An authentik API token, sent as a bearer token with every call of L</api>.
Without it L</api> throws a validation error. It is used as it is and never
renewed.

=head2 client_id

The client id of L</application>'s provider. L<WWW::Authentik::OIDC/verify_token>
checks it as the audience, which is what keeps a token of another application
of the same authentik from passing. Worth setting.

=head2 ua

The L<LWP::UserAgent> every part shares. L</default_ua> builds it.

=head2 default_ua

    my $ua = WWW::Authentik->default_ua;

The user agent this client wants, for a caller who needs to build their own
and keep the two settings that matter:

=over 4

=item C<< max_redirect => 0 >>

authentik redirects at the authorize endpoint and between the stages of a
flow. Those answers are read, not followed, and no redirect may carry the API
token anywhere.

=item C<< send_te => 0 >>

B<An injected user agent without this will hang.> LWP announces
C<TE: deflate,gzip;q=0.3> and C<Connection: TE, close> by default, and
authentik 2026.8.3 answers every second request carrying the C<TE> connection
token not at all: the call sits until the timeout, the next one is fine, the
one after that hangs again. Observed against 2026.8.3 with plain sockets as
well, so it is authentik's front end, not LWP. C<< send_te => 0 >> tells
L<Net::HTTP> to leave the header out, and libwww-perl has taken the option
since 6.33. On anything older this method throws rather than hand back a
user agent that works every other time.

=back

=head2 oidc

The L<WWW::Authentik::OIDC> of L</application>.

=head2 api

The L<WWW::Authentik::API> of this instance.

=head2 api_url

    print $ak->api_url;   # https://id.example.org/api/v3

=head2 application_url

    print $ak->application_url;   # https://id.example.org/application/o/my-app

Where this application's OpenID Connect endpoints live, without the trailing
slash. The slug is URI encoded.

=head2 issuer

    print $ak->issuer;   # https://id.example.org/application/o/my-app/

The issuer in its address form, which is what authentik puts into a token
while the provider is set to C<issuer_mode: per_provider> (its default). The
authoritative value is L<WWW::Authentik::OIDC/issuer>, read out of the
discovery document; with C<issuer_mode: global> the two differ.

=head2 for_application

    my $other = $ak->for_application('second-app');

The same client for another application, sharing the user agent and the API
token.

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
