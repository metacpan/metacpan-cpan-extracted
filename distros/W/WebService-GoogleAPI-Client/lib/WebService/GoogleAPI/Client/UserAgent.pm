use strictures;

package WebService::GoogleAPI::Client::UserAgent;

our $VERSION = '0.26';    # VERSION

# ABSTRACT: User Agent wrapper for working with Google APIs

use Moo;

extends 'Mojo::UserAgent';

#extends 'Mojo::UserAgent::Mockable';
use WebService::GoogleAPI::Client::AuthStorage::GapiJSON;
use Mojo::UserAgent;
use Data::Dump qw/pp/;    # for dev debug

use Carp qw/croak carp cluck/;

has 'do_autorefresh' => (is => 'rw', default => 1);
has 'debug'          => (is => 'rw', default => 0);
has 'auth_storage'   => (
  is      => 'rw',
  default => sub {
    WebService::GoogleAPI::Client::AuthStorage::GapiJSON->new;
  },
  handles => [qw/get_access_token scopes user/],
  trigger => 1,
  isa     => sub {
    my $role = 'WebService::GoogleAPI::Client::AuthStorage';
    die "auth_storage must implement the $role role to work!"
      unless $_[0]->does($role);
  },
  lazy => 1
);

sub _trigger_auth_storage {
  my ($self) = @_;

  # give the auth_storage a ua
  # TODO - this seems like code smell to me. Should these storage things be
  # roles that get applied to this ua?
  $self->auth_storage->ua($self);
}

## NB - could cache using https://metacpan.org/pod/Mojo::UserAgent::Cached
#  TODO: Review source of this for ideas


## NB - used by both Client and Discovery

# Keep access_token in headers always actual

## performance tip as per https://developers.google.com/calendar/performance and similar links
## NB - to work with Google APIs also assumes that Accept-Encoding: gzip is set in HTTP headers
sub BUILD {
  my ($self) = @_;
  $self->transactor->name(__PACKAGE__ . ' (gzip enabled)');
  ## MAX SIZE ETC _ WHAT OTHER CONFIGURABLE PARAMS ARE AVAILABLE
}



sub header_with_bearer_auth_token {
  my ($self, $headers) = @_;

  $headers = {} unless defined $headers;

  $headers->{'Accept-Encoding'} = 'gzip';

  if (my $token = $self->get_access_token) {
    $headers->{Authorization} = "Bearer $token";
  } else {

    # TODO - why is this not fatal?
    carp
"Can't build Auth header, couldn't get an access token. Is your AuthStorage set up correctly?";
  }
  return $headers;
}


sub build_http_transaction {
  my ($self, $params) = @_;
  ## hack to allow method option as alias for httpMethod

  $params->{httpMethod} = $params->{method} if defined $params->{method};
  $params->{httpMethod} = '' unless defined $params->{httpMethod};

  my $http_method   = uc($params->{httpMethod}) || 'GET';    # uppercase ?
  my $optional_data = $params->{options}        || '';
  my $path          = $params->{path}
    || cluck('path parameter required for build_http_transaction');
  my $no_auth = $params->{no_auth}
    || 0;    ## default to including auth header - ie not setting no_auth
  my $headers = $params->{headers} || {};

  cluck 'Attention! You are using POST, but no payload specified'
    if (($http_method eq 'POST') && !defined $optional_data);
  cluck "build_http_transaction:: $http_method $path " if ($self->debug > 11);
  cluck
"$http_method Not a SUPPORTED HTTP method parameter specified to build_http_transaction"
    . pp $params
    unless $http_method =~ /^GET|PATH|PUT|POST|PATCH|DELETE$/ixm;

  ## NB - headers not passed if no_auth
  $headers = $self->header_with_bearer_auth_token($headers) unless $no_auth;
  if ($http_method =~ /^POST|PATH|PUT|PATCH$/ixg) {
    ## ternary conditional on whether optional_data is set
    ## return $optional_data eq '' ? $self->build_tx( $http_method => $path => $headers ) : $self->build_tx( $http_method => $path => $headers => json => $optional_data );
    if ($optional_data eq '') {
      return $self->build_tx($http_method => $path => $headers);
    } else {
      if (ref($optional_data) eq 'HASH') {
        return $self->build_tx(
          $http_method => $path => $headers => json => $optional_data);
      } elsif (
        ref($optional_data) eq
        '')    ## am assuming is a post with options containing a binary payload
      {
        return $self->build_tx(
          $http_method => $path => $headers => $optional_data);
      }

    }
  } else {    ## DELETE or GET
    return $self->build_tx(
      $http_method => $path => $headers => form => $optional_data)
      if ($http_method eq 'GET');
    return $self->build_tx($http_method => $path => $headers)
      if ($http_method eq 'DELETE');
  }

  #return undef; ## assert: should never get here
}




# NOTE validated means that we assume checking against discovery specs has already been done.
sub validated_api_query {
  my ($self, $params) = @_;

  ## assume is a GET for the URI at $params
  if (ref($params) eq '') {
    cluck("transcribing $params to a hashref for validated_api_query")
      if $self->debug;
    my $val = $params;
    $params = { path => $val, method => 'get', options => {}, };
  }

  my $tx = $self->build_http_transaction($params);

  cluck("$params->{method} $params->{path}") if $self->debug;

  #TODO- figure out how we can alter this to use promises
  #      at this point, i think we'd have to make a different method entirely to
  #      do this promise-wise
  my $res = $self->start($tx)->res;
  $res->{_token} = $self->get_access_token;

  if (($res->code == 401) && $self->do_autorefresh) {
    cluck
      "Your access token was expired. Attemptimg to update it automatically..."
      if ($self->debug > 11);

    $self->auth_storage->refresh_access_token($self);

    return $self->validated_api_query($params);
  } elsif ($res->code == 403) {
    cluck('Unexpected permission denied 403 error');
    return $res;
  } elsif ($res->code == 429) {
    cluck('HTTP 429 - you hit a rate limit. Try again later');
    return $res;
  }
  return $res if $res->code == 200;
  return $res if $res->code == 204;  ## NO CONTENT - INDICATES OK FOR DELETE ETC
  return $res if $res->code == 400;  ## general failure
  cluck("unhandled validated_api_query response code " . $res->code);
  return $res;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::GoogleAPI::Client::UserAgent - User Agent wrapper for working with Google APIs

=head1 VERSION

version 0.26

=head2 C<header_with_bearer_auth_token>

  returns a hashref describing gzip encoding and auth bearer token

=head2 C<build_http_transaction>

  Example of usage:

      $gapi->build_http_transaction({
        method => 'post',  ## case insensitive [ GET|PATH|PUT|POST|PATCH|DELETE ] 
        path => 'https://www.googleapis.com/calendar/users/me/calendarList', ## NB - no interpolation
        options => { key => value } ## form variables for POST etc otherwise - GET params treated properly
      })

=head2 C<validated_api_query>

Google API HTTP 'method' request to API End Point at 'path' with optional parameters described by 'options'

By 'validated' I mean that no checks are performed against discovery data structures and no interpolation is performed.
The pre-processing functionality for the library is expected to be completed by the 'Client' class before passing
the cleaner, sanitised and validated request to the agent here for submitting.

NB - handles auth headers injection and token refresh if required and possible

Required params: method, route

$self->get_access_token must return a valid token

Examples of usage:

  $self->validated_api_query({
      method => 'get',
      path => 'https://www.googleapis.com/calendar/users/me/calendarList',
    });

  $self->validated_api_query({
      method => 'post',
      path => 'https://www.googleapis.com/calendar/v3/calendars/'.$calendar_id.'/events',
      options => { key => value }
  }

See Also: Client->api_query that augments the parameters with some Google API Specific fucntionality before calling here.

Returns L<Mojo::Message::Response> object

=head1 AUTHORS

=over 4

=item *

Veesh Goldman <veesh@cpan.org>

=item *

Peter Scott <localshop@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017-2021 by Peter Scott and others.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
