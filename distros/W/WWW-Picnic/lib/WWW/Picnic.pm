package WWW::Picnic;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Library to access Picnic Supermarket API
$WWW::Picnic::VERSION = '0.001';
use Moo;

use Carp qw( croak );
use JSON::MaybeXS;
use HTTP::Request;
use LWP::UserAgent;
use Digest::MD5 qw( md5_hex );

has user => (
  is => 'ro',
  required => 1,
);

has pass => (
  is => 'ro',
  required => 1,
);

has client_id => ( # ???
  is => 'ro',
  default => sub { 1 },
);

has api_version => (
  isa => sub { $_[0] >= 15 },
  is => 'ro',
  default => sub { 15 },
);

has country => (
  is => 'ro',
  default => sub { 'de' },
);

sub api_endpoint {
  my ( $self ) = @_;
  return sprintf('https://storefront-prod.%s.picnicinternational.com/api/%s', $self->country, "".$self->api_version."");
}

has http_agent => (
  is => 'ro',
  lazy => 1,
  default => sub {
    my $self = shift;
    my $ua = LWP::UserAgent->new;
    $ua->agent($self->http_agent_name);
    return $ua;
  },
);

has http_agent_name => (
  is => 'ro',
  lazy => 1,
  default => sub { 'okhttp/3.9.0' },
);

has json => (
  is => 'ro',
  lazy => 1,
  default => sub { return JSON::MaybeXS->new },
);

has _auth_cache => (
  is => 'ro',
  default => sub {{}},
);

sub picnic_auth {
  my ( $self ) = @_;
  unless (defined $self->_auth_cache->{auth}) {
    my $url = URI->new(join('/',$self->api_endpoint,'user','login'));
    my $request = HTTP::Request->new( POST => $url );
    $request->header('Accept' => 'application/json');
    $request->header('Content-Type' => 'application/json; charset=UTF-8');
    $request->content($self->json->encode({
      key => $self->user,
      secret => md5_hex($self->pass),
      client_id => $self->client_id,
    }));
    my $response = $self->http_agent->request($request);
    if ($response->is_success) {
      my $auth = $response->header('X-Picnic-Auth');
      croak __PACKAGE__.": login success, but no auth token!" unless $auth;
      my $data = $self->json->decode($response->content);
      croak __PACKAGE__.": login success, but user id!" unless $data and $data->{user_id};
      $self->_auth_cache->{auth} = $auth;
      $self->_auth_cache->{time} = time;
      $self->_auth_cache->{user_id} = $data->{user_id};
    } else {
      croak __PACKAGE__.": login failed! ".$response->status_line;
    }
  }
  return $self->_auth_cache->{auth};
}

sub request {
  my ( $self, @original_args ) = @_;
  my ( $method, $path, $data, %params ) = @original_args;
  $data = [] if $method eq 'PUT' and !$data;
  my $url = URI->new(join('/',$self->api_endpoint,$path));
  if (%params) {
    $url->query_form(%params);
  }
  my $request = HTTP::Request->new( $method => $url );
  $request->header('Accept' => 'application/json');
  $request->header('X-Picnic-Auth' => $self->picnic_auth );
  if (defined $data) {
    $request->header('Content-Type' => 'application/json');
    $request->content($self->json->encode($data));
  }
  my $response = $self->http_agent->request($request);
  unless ($response->is_success) {
    croak __PACKAGE__.": request to ".$url->as_string." failed! ".$response->status_line;
  }
  return $self->json->decode($response->content);
}

sub get_user {
  my ( $self ) = @_;
  return $self->request( GET => 'user' );
}

sub get_cart {
  my ( $self ) = @_;
  return $self->request( GET => 'cart' );
}

sub clear_cart {
  my ( $self ) = @_;
  return $self->request( POST => 'cart/clear' );
}

sub get_delivery_slots {
  my ( $self ) = @_;
  return $self->request( GET => 'cart/delivery_slots' );
}

sub search {
  my ( $self, $term ) = @_;
  return $self->request( GET => 'search', undef, search_term => $term );
}

1;

__END__

=pod

=head1 NAME

WWW::Picnic - Library to access Picnic Supermarket API

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use WWW::Picnic;

  my $picnic = WWW::Picnic->new(
    user => 'user@universe.org',
    pass => 'alohahey',
    country => 'DE',
  );

=head1 DESCRIPTION

B<WORK IN PROGRESS>

=head1 ATTRIBUTES

=head2 user

Your login email at Picnic

=head2 user

Your password at Picnic

=head2 country

2-letter country code of your account

=head1 METHODS

=head2 get_user

=head2 get_cart

=head2 clear_cart

=head2 get_delivery_slots

=head2 search

=encoding utf8

=head1 TODO

The module gets classes for the results, so if you use this now, please be
aware that the results will change.

=head1 SUPPORT

IRC

  Join irc.perl.org and msg Getty

Repository

  https://github.com/Getty/perl-picnic
  Pull request and additional contributors are welcome

Issue Tracker

  https://github.com/Getty/perl-picnic/issues

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
