use strictures;

package WebService::GoogleAPI::Client::AuthStorage;

# ABSTRACT: Role for classes which store your auth credentials

our $VERSION = '0.27';    # VERSION

use Moo::Role;
use Carp;
use WebService::GoogleAPI::Client::AccessToken;


has user => is => 'rw';


# this is managed by the BUILD in ::Client::UserAgent,
# and by the BUILD in ::Client
has ua => is => 'rw', weak_ref => 1;




requires qw/
    scopes
    refresh_access_token
    get_access_token
    /;

around get_access_token => sub {
  my ($orig, $self) = @_;
  my $user   = $self->user;
  my $scopes = $self->scopes;

  my $token = $self->$orig;
  my $class = 'WebService::GoogleAPI::Client::AccessToken';
  return $token if ref $token eq $class;
  return WebService::GoogleAPI::Client::AccessToken->new(
    user   => $user,
    token  => $token,
    scopes => $scopes
  );
};


sub refresh_user_token {
  my ($self, $params) = @_;
  my $tx = $self->ua->post(
    'https://www.googleapis.com/oauth2/v4/token' => form => { %$params, grant_type => 'refresh_token' });
  my $new_token = $tx->res->json('/access_token');
  unless ($new_token) {
    croak "Failed to refresh access token: ", join ' - ', map $tx->res->json("/$_"), qw/error error_description/
        if $tx->res->json;
    # if the error doesn't come from google
    croak "Unknown error refreshing access token";
  }

  return $new_token;
}



sub refresh_service_account_token {
  my ($self, $jwt) = @_;
  my $tx        = $self->ua->post('https://www.googleapis.com/oauth2/v4/token' => form => $jwt->as_form_data);
  my $new_token = $tx->res->json('/access_token');
  unless ($new_token) {
    croak "Failed to get access token: ", join ' - ', map $tx->res->json("/$_"), qw/error error_description/
        if $tx->res->json;
    # if the error doesn't come from google
    croak "Unknown error getting access token";
  }
  return $new_token;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::GoogleAPI::Client::AuthStorage - Role for classes which store your auth credentials

=head1 VERSION

version 0.27

=head1 SYNOPSIS

  package My::Cool::AuthStorage::Class;
  use Moo;
  with 'WebService::GoogleAPI::Client::AuthStorage';

  ... # implement the necessary functions

  package main;
  use WebService::GoogleAPI::Client;
  use My::Cool::AuthStorage::Class;
  my $gapi = WebService::GoogleAPI::Client->new(
     auth_storage => My::Cool::AuthStorage::Class->new
  );
  ... # and now your class manages the access_tokens

WebService::GoogleAPI::Client::AuthStorage is a Moo::Role for auth storage backends.
This dist comes with two consumers, L<WebService::GoogleAPI::Client::AuthStorage::GapiJSON>
and L<WebService::GoogleAPI::Client::AuthStorage::ServiceAccount>. See those for more info
on how you can use them with L<WebService::GoogleAPI::Client>.

This is a role which defines the interface that L<WebService::GoogleAPI::Client>
will use when making requests.

=head1 ATTRIBUTES

=head2 user

The user that an access token should be returned for. Is read/write. May be
falsy, depending on the backend.

=head2 ua

An weak reference to the WebService::GoogleAPI::Client::UserAgent that this is
attached to, so that access tokens can be refreshed. The UserAgent object manages this.

=head1 METHODS

=head2 refresh_user_token

Makes the call to Google's OAuth API to refresh a token for a user.
Requires one parameter, a hashref with the keys:

=over 4

=item client_id Your OAuth Client ID

=item client_secret Your OAuth Client Secret

=item refresh_token The refresh token for the user

=back

Will return the token from the API, for the backend to store (wherever it pleases).

Will die with the error message from Google if the refresh fails.

=head2 refresh_service_account_token

Makes the call to Google's OAuth API to refresh a token for a service account.
Requires one parameter, a L<Mojo::JWT::Google> object already set with the user
and scopes requested.

Will return the token from the API, for the backend to store (wherever it pleases).

Will die with the error message from Google if the refresh fails.

=head1 REQUIRES

It requires the consuming class to implement functions with the following names:

=over 4

=item scopes

A list of scopes that you expect the access token to be valid for. This could be
read/write, but it's not necessary. Some backends may have different credentials
for different sets of scopes (though as an author, you probably want to just
have the whole set you need upfront).

=item refresh_access_token

A method which will refresh the access token if it has been determined to have
expired.  Take a look at the two consumers which come with this dist for
examples of how to renew user credentials and service account credentials.

=item get_access_token

A method which will return the access token for the current user and scopes.
This method is wrapped to augment whatever has been returned with user and
scopes data for introspection by making a
WebService::GoogleAPI::Client::AccessToken instance. If you choose to return such an instance yourself, then it will be left alone.

=back

=head1 AUTHOR

Veesh Goldman <veesh@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017-2023 by Veesh Goldman and Others.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
