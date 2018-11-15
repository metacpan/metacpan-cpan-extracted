use strictures;

package WebService::GoogleAPI::Client::UserAgent;
$WebService::GoogleAPI::Client::UserAgent::VERSION = '0.21';

# ABSTRACT: User Agent wrapper for working with Google APIs

use Moo;

extends 'Mojo::UserAgent';

#extends 'Mojo::UserAgent::Mockable';
use WebService::GoogleAPI::Client::Credentials;
use WebService::GoogleAPI::Client::AuthStorage;
use Mojo::UserAgent;
use Data::Dump qw/pp/;    # for dev debug

use Carp qw/croak carp cluck/;

has 'do_autorefresh'                => ( is => 'rw', default => 1 );    # if 1 storage must be configured
has 'auto_update_tokens_in_storage' => ( is => 'rw', default => 1 );
has 'debug'                         => ( is => 'rw', default => 0 );
has 'credentials' =>
  ( is => 'rw', default => sub { WebService::GoogleAPI::Client::Credentials->instance }, handles => [qw/access_token auth_storage get_scopes_as_array user /], lazy => 1 );

## NB - could cache using https://metacpan.org/pod/Mojo::UserAgent::Cached TODO: Review source of this for ideas


## NB - used by both Client and Discovery

# Keep access_token in headers always actual

sub BUILD
{
  my ( $self ) = @_;
  ## performance tip as per https://developers.google.com/calendar/performance and similar links
  ## NB - to work with Google APIs also assumes that Accept-Encoding: gzip is set in HTTP headers
  $self->transactor->name( __PACKAGE__ . ' (gzip enabled)' );
  ## MAX SIZE ETC _ WHAT OTHER CONFIGURABLE PARAMS ARE AVAILABLE
}



## TODO: this should probably nbe handled ->on('start' => sub {}) as per https://metacpan.org/pod/Mojolicious::Guides::Cookbook#Decorating-follow-up-requests

sub header_with_bearer_auth_token
{
  my ( $self, $headers ) = @_;

  $headers = {} unless defined $headers;

  $headers->{ 'Accept-Encoding' } = 'gzip';

  # cluck "header_with_bearer_auth_token: ".$self->access_token;
  if ( $self->access_token )
  {
    $headers->{ 'Authorization' } = 'Bearer ' . $self->access_token;
  }
  else
  {
    cluck 'No access_token, can\'t build Auth header';
  }
  return $headers;
}


sub build_http_transaction
{
  my ( $self, $params ) = @_;
  ## hack to allow method option as alias for httpMethod

  $params->{ httpMethod } = $params->{ method } if defined $params->{ method };
  $params->{ httpMethod } = '' unless defined $params->{ httpMethod };

  my $http_method   = uc( $params->{ httpMethod } ) || 'GET';                                                           # uppercase ?
  my $optional_data = $params->{ options }          || '';
  my $path          = $params->{ path }             || cluck( 'path parameter required for build_http_transaction' );
  my $no_auth       = $params->{ no_auth }          || 0;                                                               ## default to including auth header - ie not setting no_auth
  my $headers       = $params->{ headers }          || {};

  cluck 'Attention! You are using POST, but no payload specified' if ( ( $http_method eq 'POST' ) && !defined $optional_data );
  cluck "build_http_transaction:: $http_method $path " if ( $self->debug > 11 );
  cluck "$http_method Not a SUPPORTED HTTP method parameter specified to build_http_transaction" . pp $params unless $http_method =~ /^GET|PATH|PUT|POST|PATCH|DELETE$/ixm;

  ## NB - headers not passed if no_auth
  $headers = $self->header_with_bearer_auth_token( $headers ) unless $no_auth;
  if ( $http_method =~ /^POST|PATH|PUT|PATCH$/ixg )
  {
    ## ternary conditional on whether optional_data is set
    ## return $optional_data eq '' ? $self->build_tx( $http_method => $path => $headers ) : $self->build_tx( $http_method => $path => $headers => json => $optional_data );
    if ( $optional_data eq '' )
    {
      return $self->build_tx( $http_method => $path => $headers );
    }
    else
    {
      if ( ref( $optional_data ) eq 'HASH' )
      {
        return $self->build_tx( $http_method => $path => $headers => json => $optional_data );
      }
      elsif ( ref( $optional_data ) eq '' )    ## am assuming is a post with options containing a binary payload
      {
        return $self->build_tx( $http_method => $path => $headers => $optional_data );
      }

    }
  }
  else                                         ## DELETE or GET
  {
    return $self->build_tx( $http_method => $path => $headers => form => $optional_data ) if ( $http_method eq 'GET' );
    return $self->build_tx( $http_method => $path => $headers ) if ( $http_method eq 'DELETE' );
  }

  #return undef; ## assert: should never get here
}




sub validated_api_query
{
  my ( $self, $params ) = @_;
  ## NB validated means that assumes checking against discovery specs has already been done.

  if ( ref( $params ) eq '' )    ## assume is a GET for the URI at $params
  {
    cluck( "transcribing $params to a hashref for validated_api_query" ) if $self->debug;
    my $val = $params;
    $params = { path => $val, method => 'get', options => {}, };
  }

  my $tx = $self->build_http_transaction( $params );

  cluck( "$params->{method} $params->{path}" ) if $self->debug;
  my $res = $self->start( $tx )->res;

  ## TODO: HANDLE TIMEOUTS AND OTHER ERRORS IF THEY WEREN'T HANDLED BY build_http_transaction

  ## TODO:
#  return Mojo::Message::Response->new unless ref( $res ) eq 'Mojo::Message::Response';

  if ( ( $res->code == 401 ) && $self->do_autorefresh )
  {
    if ( $res->code == 401 )    ## redundant - was there something else in mind ?
    {
      croak "No user specified, so cant find refresh token and update access_token" unless $self->user;
      cluck "401 response - access_token was expired. Attemptimg to update it automatically ..." if ( $self->debug > 11 );

      # cluck "Seems like access_token was expired. Attemptimg update it automatically ..." if $self->debug;

      my $cred      = $self->auth_storage->get_credentials_for_refresh( $self->user );    # get client_id, client_secret and refresh_token
      my $new_token = $self->refresh_access_token( $cred )->{ access_token };             # here also {id_token} etc
      cluck "validated_api_query() Got a new token: " . $new_token if ( $self->debug > 11 );
      $self->access_token( $new_token );

      if ( $self->auto_update_tokens_in_storage )
      {
        $self->auth_storage->set_access_token_to_storage( $self->user, $self->access_token );
      }

      #$tx  = $self->build_http_transaction( $params );

      $res = $self->start( $self->build_http_transaction( $params ) )->res;               # Mojo::Message::Response
    }
  }
  elsif ( $res->code == 403 )
  {
    cluck( 'Unexpected permission denied 403 error ' );
    return $res;
  }
  return $res if $res->code == 200;
  return $res if $res->code == 204;                                                       ## NO CONTENT - INDICATES OK FOR DELETE ETC
  return $res if $res->code == 400;                                                       ## general failure
  cluck( "unhandled validated_api_query response code " . $res->code );
  return $res;
}


sub refresh_access_token
{
  my ( $self, $credentials ) = @_;

  if (
    ( !defined $credentials->{ client_id } )    ## could this be caught somewhere earlier than here?
    || ( !defined $credentials->{ client_secret } )    ##  unless credentials include an access token only ?
    || ( !defined $credentials->{ refresh_token } )
    )
  {
    croak 'If you credentials are missing the refresh_token - consider removing the auth at '
      . 'https://myaccount.google.com/permissions as The oauth2 server will only ever mint one refresh '
      . 'token at a time, and if you request another access token via the flow it will operate as if '
      . 'you only asked for an access token.'
      if !defined $credentials->{ refresh_token };

    croak "Not enough credentials to refresh access_token. Check that you provided client_id, client_secret and refresh_token";
  }

  cluck "refresh_access_token:: Attempt to refresh access_token " if ( $self->debug > 11 );
  $credentials->{ grant_type } = 'refresh_token';
  return $self->post( 'https://www.googleapis.com/oauth2/v4/token' => form => $credentials )->res->json || croak( 'refresh_access_token failed' );    # tokens
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::GoogleAPI::Client::UserAgent - User Agent wrapper for working with Google APIs

=head1 VERSION

version 0.21

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

$self->access_token must be valid

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

=head2 C<refresh_access_token>

Get new access token for user from Google API server

  $self->refresh_access_token({
		client_id     => '',
		client_secret => '',
		refresh_token => ''
	})

 Q: under what conditions could we not have a refresh token? - what scopes are required? ensure that included in defaults if they are req'd

=head1 AUTHOR

Peter Scott <localshop@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017-2018 by Peter Scott and others.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
