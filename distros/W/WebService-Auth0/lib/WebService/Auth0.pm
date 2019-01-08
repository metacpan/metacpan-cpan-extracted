package WebService::Auth0;

use Moo;
use Module::Runtime qw(use_module);

our $VERSION = '0.002';

has ua_handler_class => (
  is=>'ro',
  required=>1,
  default=>'WebService::Auth0::UA::LWP');

has ua_handler_options => (
  is=>'ro',
  required=>1,
  default=>sub { [] });

has ua => (
  is=>'ro',
  init_arg=>undef,
  lazy=>1,
  required=>1,
  default=>sub {
    use_module($_[0]->ua_handler_class)->new(
      @{$_[0]->ua_handler_options});
  });

has domain => (
  is=>'ro',
  required=>1 );

has client_id => (is=>'ro', predicate=>'has_client_id');
has client_secret => (is=>'ro', predicate=>'has_client_secret');

sub auth {
  my $self = shift;
  my %args = $_[0] ? ((ref($_[0])||'') eq 'HASH' ? %{$_[0]} : @_) : ();

  %args = (
    ua => $self->ua,
    domain => $self->domain,
    client_id => $self->client_id,
    %args,
  );

  $args{client_secret} = $self->client_secret
    if $self->has_client_secret;

  return use_module('WebService::Auth0::Authentication')
    ->new(%args);
}

sub management {
  my $self = shift;
  my %args = $_[0] ? ((ref($_[0])||'') eq 'HASH' ? %{$_[0]} : @_) : ();

  %args = (
    ua => $self->ua,
    domain => $self->domain,
    %args,
  );

  $args{client_secret} = $self->client_secret
    if $self->has_client_secret;

  return use_module('WebService::Auth0::Management')
    ->new(%args);
}

1;

=head1 NAME

WebService::Auth0 - Access the Auth0 API

=head1 SYNOPSIS

    use WebService::Auth0;
    my $auth0 = WebService::Auth0->new(
      domain => 'my-domain',
      client_id => 'my-client_id',
      client_secret => 'my-client_secrete');

    $auth0->...

=head1 DESCRIPTION

B<NOTE> WARNING!  This is an early release with hardly any tests.  If you use
this you should be willing / able to help me hack on it as needed.  I currently
reserve the right to make breaking changes as needed.

Prototype for a web service client for L<https://auth0.com>.  This is probably
going to change a lot as I learn how it actually works.  I wrote this
primarily as I was doing L<Catalyst::Authentication::Credential::Auth0>
since it seemed silly to stick web service client stuff directly into
the Catalyst authorization credential class.

=head1 ATTRIBUTES

This class defines the following attributes

=head2 domain

=head2 client_id

=head2 client_secret

Credentials supplied to you from L<https://auth0.com>. 

=head2 ua_handler_class

Defaults to L<WebService::Auth0::UA::LWP>, a blocking user agent based on L<LWP>.

=head2 ua_handler_options

An arrayref of options tht you pass to your L</ua_handler_class>.

=head1 METHODS

This class defines the following methods:

=head2 auth

Factory class that returns an instance of L<WebService::Auth0::Authentication>
using the current settings.

=head2 management

Factory class that returns an instance of L<WebService::Auth0::Management>
using the current settings.

=head1 SEE ALSO
 
L<https://auth0.com>.

=head1 AUTHOR
 
    John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 COPYRIGHT & LICENSE
 
Copyright 2017, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
