package WebService::Pingboard;
# ABSTRACT: Interface to Pingboard API
use Moose;
use MooseX::Params::Validate;
use MooseX::WithCache;
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Headers;
use JSON;
use Class::Date qw/gmdate/;
use POSIX; #strftime
use YAML qw/Dump LoadFile DumpFile/;
use Encode;
use URI::Encode qw/uri_encode/;

our $VERSION = 0.009;

=head1 NAME

WebService::Pingboard

=head1 DESCRIPTION

Interaction with Pingboard

This module uses MooseX::Log::Log4perl for logging - be sure to initialize!

=cut


=head1 ATTRIBUTES

=over 4

=item cache

Optional.

Provided by MooseX::WithX - optionally pass a Cache::FileCache object to cache and avoid unnecessary requests

=cut

with "MooseX::Log::Log4perl";

# Unfortunately it is necessary to define the cache type to be expected here with 'backend'
# TODO a way to be more generic with cache backend would be better
with 'MooseX::WithCache' => {
    backend => 'Cache::FileCache',
};

=item refresh_token

=cut
has 'refresh_token' => (
    is          => 'ro',
    isa         => 'Str',
    required    => 0,
    writer      => '_set_refresh_token',
    );

=item password

=cut
has 'password' => (
    is          => 'ro',
    isa         => 'Str',
    required    => 0,
    writer      => '_set_password',
    );

=item username

=cut
has 'username' => (
    is          => 'ro',
    isa         => 'Str',
    required    => 0,
    writer      => '_set_username',
    );

=item client_id

=cut
has 'client_id' => (
        is          => 'ro',
        isa         => 'Str',
        required    => 0,
        writer      => '_set_client_id',
        );

=item client_secret

=cut
has 'client_secret' => (
        is          => 'ro',
        isa         => 'Str',
        required    => 0,
        writer      => '_set_client_secret',
        );

=item credentials_file

=cut
has 'credentials_file' => (
    is          => 'ro',
    isa         => 'Str',
    required    => 0,
    );

=item timeout

Timeout when communicating with Pingboard in seconds.  Optional.  Default: 10
Will only be in effect if you allow the useragent to be built in this module.

=cut
has 'timeout' => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    default     => 10,
    );

=item default_backoff

Optional.  Default: 10
Time in seconds to back off before retrying request.
If a 429 response is given and the Retry-Time header is provided by the api this will be overridden.

=cut
has 'default_backoff' => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    default     => 10,
    );

=item default_page_size

Optional. Default: 100

=cut
has 'default_page_size' => (
    is          => 'rw',
    isa         => 'Int',
    required    => 1,
    default     => 100,
    );

=item retry_on_status

Optional. Default: [ 429, 500, 502, 503, 504 ]
Which http response codes should we retry on?

=cut
has 'retry_on_status' => (
    is          => 'ro',
    isa         => 'ArrayRef',
    required    => 1,
    default     => sub{ [ 429, 500, 502, 503, 504 ] },
    );

=item max_tries

Optional.  Default: undef

Limit maximum number of times a query should be attempted before failing.  If undefined then unlimited retries

=cut
has 'max_tries' => (
    is          => 'ro',
    isa         => 'Int',
    );

=item api_url

Default: https://app.pingboard.com/api/v2/

=cut
has 'api_url' => (
    is		=> 'ro',
    isa		=> 'Str',
    required	=> 1,
    default     => 'https://app.pingboard.com/api/v2',
    );

=item user_agent

Optional.  A new LWP::UserAgent will be created for you if you don't already have one you'd like to reuse.

=cut

has 'user_agent' => (
    is		=> 'ro',
    isa		=> 'LWP::UserAgent',
    required	=> 1,
    lazy	=> 1,
    builder	=> '_build_user_agent',

    );

=item loglevel

Optionally override the global loglevel for this module

=cut

has 'loglevel' => (
    is		=> 'rw',
    isa		=> 'Str',
    trigger     => \&_set_loglevel,
    );

has '_access_token' => (
    is          => 'ro',
    isa         => 'Str',
    required    => 0,
    writer      => '_set_access_token',
    );

has '_headers' => (
    is          => 'ro',
    isa         => 'HTTP::Headers',
    writer      => '_set_headers',
    );

has '_access_token_expires' => (
    is          => 'ro',
    isa         => 'Int',
    required    => 0,
    writer      => '_set_access_token_expires',
    );

sub _set_loglevel {
    my( $self, $level ) = @_;
    $self->log->warn( "Setting new loglevel: $level" );
    $self->log->level( $level );
}

sub _build_user_agent {
    my $self = shift;
    $self->log->debug( "Building useragent" );
    my $ua = LWP::UserAgent->new(
	keep_alive	=> 1,
        timeout         => $self->timeout,
    );
    return $ua;
}

=back

=head1 METHODS

=over 4

=item valid_access_token

Will return a valid access token.

=cut

sub valid_access_token {
    my ( $self, %params ) = validated_hash(
        \@_,
        username                => { isa    => 'Str', optional => 1 },
        password                => { isa    => 'Str', optional => 1 },
        client_id               => { isa    => 'Str', optional => 1 },
        client_secret           => { isa    => 'Str', optional => 1 },
        refresh_token           => { isa    => 'Str', optional => 1 },
        access_token            => { isa    => 'Str', optional => 1 },
        access_token_expires    => { isa    => 'Str', optional => 1 },
	);

    # If we still have a valid access token, use this
    if( $self->access_token_is_valid ){
        return $self->_access_token;
    }

    # We do not have valid credentials in the object already, so let's gather from all sources and try again
    $params{username}       ||= $self->username;
    $params{password}       ||= $self->password;
    $params{client_id}      ||= $self->client_id;
    $params{client_secret}  ||= $self->client_secret;
    $params{refresh_token}  ||= $self->refresh_token;
    $params{access_token}   ||= $self->_access_token;
    $params{access_token_expires}   ||= $self->_access_token_expires;
    if( not $params{username} and $self->credentials_file ){
        my $credentials = LoadFile ( $self->credentials_file );
        foreach( qw/username password client_id client_secret refresh_token access_token access_token_expires/ ){
            $params{$_} ||= $credentials->{$_} if( $credentials->{$_} );
        }
    }
    $self->_set_access_token_expires( gmdate(  $params{access_token_expires} )->epoch ) if( $params{access_token_expires} );
    $self->_set_access_token( $params{access_token} ) if( $params{access_token} );

    # Test again if we now have a valid access token
    if( $self->access_token_is_valid ){
        return $self->_access_token;
    }

    # Ok... we really don't have an access token... let's try and get one
    my $h = HTTP::Headers->new();
    $h->header( 'Content-Type'	=> "application/json" );
    $h->header( 'Accept'	=> "application/json" );

    my $data;
    #Only password flow allows refresh tokens
    if( $params{username} and $params{refresh_token} ){
        $self->log->debug( "Requesting fresh access_token with refresh_token: $params{refresh_token}" );
        $data = $self->_request_from_api(
            method      => 'POST',
            headers     => $h,
            uri         => 'https://app.pingboard.com/oauth/token',
            options     => sprintf( 'username=%s&refresh_token=%s&grant_type=refresh_token', $params{username}, $params{refresh_token} ),
            );
    }elsif( $params{username} and $params{password} ){
        $self->log->debug( "Requesting fresh access_token with username and password for: $params{username}" );
        $data = $self->_request_from_api(
            method      => 'POST',
            headers     => $h,
            uri         => 'https://app.pingboard.com/oauth/token',
            options     => sprintf( 'username=%s&password=%s&grant_type=password', $params{username}, uri_encode( $params{password} ) ),
            );
    }elsif( $params{client_id} and $params{client_secret} ){
        $self->log->debug( "Requesting fresh access_token with client_id and client_secret for: $params{client_id}" );
        $data = $self->_request_from_api(
            method      => 'POST',
            headers     => $h,
            uri         => 'https://app.pingboard.com/oauth/token',
            options     => sprintf( 'client_id=%s&client_secret=%s&grant_type=client_credentials', $params{client_id}, $params{client_secret} ),
            );
    }else{
        die( "Cannot create valid access_token without a refresh_token or client_id and client_secret or username and password" );
    }

    $self->log->trace( "Response from getting access_token:\n" . Dump( $data ) ) if $self->log->is_trace();
    my $expire_time = time() + $data->{expires_in};
    $self->log->debug( "Got new access_token: $data->{access_token} which expires at " . localtime( $expire_time ) );
    if( $data->{refresh_token} ){
        $self->log->debug( "Got new refresh_token: $data->{refresh_token}" );
        $self->_set_refresh_token( $data->{refresh_token} );
    }
    if ($params{username}) {
        $self->_set_username( $params{username} );
    }
    $self->_set_access_token( $data->{access_token} );
    $self->_set_access_token_expires( $expire_time );

    if( $self->credentials_file ){
        $self->log->debug( "Writing valid credentials back to file: " . $self->credentials_file );
        my $credentials = {
            username                => $self->username,
            access_token            => $self->_access_token,
            refresh_token           => $self->refresh_token,
            access_token_expires    => strftime( '%Y-%m-%dT%H:%M:%SZ', gmtime( $self->_access_token_expires ) ),
        };
        $credentials->{password} = $self->password if $self->password;

        DumpFile( $self->credentials_file, $credentials );
    }
    return $data->{access_token};
}

=item access_token_is_valid

Returns true if a valid access token exists (with at least 5 seconds validity remaining).

=cut

sub access_token_is_valid {
    my $self = shift;
    return 1 if( $self->_access_token and $self->_access_token_expires and $self->_access_token_expires > ( time() + 5 ) );
    return 0;
}

=item headers

Returns a HTTP::Headers object with the Authorization header set with a valid access token

=cut
sub headers {
    my $self = shift;
    if( not $self->access_token_is_valid or not $self->_headers ){
        my $h = HTTP::Headers->new();
        $h->header( 'Content-Type'	=> "application/json" );
        $h->header( 'Accept'	=> "application/json" );
        $h->header( 'Authorization' => "Bearer " . $self->valid_access_token );
        $self->_set_headers( $h );
    }
    return $self->_headers;
}

=back

=head1 API METHODS

This is a module in development - only a subset of all of the API endpoints have been implemented yet.
The full documentation is available here: http://docs.pingboard.apiary.io/#

=head2 Generic parameters

Any of the methods below which return paged content accept the parameters:

=over 4

=over 4

=item limit

Optional. Maximum number of entries to fetch.

=item page_size

Optional.  Page size to use when fetching.

=item options

Optional.  Additional url options to add

=back

=back




=over 4

=item get_users

Retrieve a list of users

Details: http://docs.pingboard.apiary.io/#reference/users/users-collection/get-users

=cut

sub get_users {
    my ( $self, %params ) = validated_hash(
        \@_,
        id	    => { isa    => 'Int', optional => 1 },
        limit       => { isa    => 'Int', optional => 1 },
        page_size   => { isa    => 'Int', optional => 1 },
        email       => { isa    => 'Str', optional => 1 },
        first_name  => { isa    => 'Str', optional => 1 },
        last_name   => { isa    => 'Str', optional => 1 },
        start_date  => { isa    => 'Str', optional => 1 },
        job_title   => { isa    => 'Str', optional => 1 },
        options     => { isa    => 'Str', optional => 1 },
	);
    $params{field}  = 'users';
    $params{path}   = '/users' . ( $params{id} ? '/' . $params{id} : '' );
    foreach( qw/id email first_name last_name start_date job_title/ ){
        if( $params{$_} ){
            $params{options} .= ( $params{options} ? '&' : '' ) . $_ . '=' . $params{$_};
            delete( $params{$_} );
        }
    }

    return $self->_paged_request_from_api( %params );
}

=item get_groups

Get list of user groups

Details: http://docs.pingboard.apiary.io/#reference/groups/groups-collection/get-groups

=cut

sub get_groups {
    my ( $self, %params ) = validated_hash(
        \@_,
        id	    => { isa    => 'Int', optional => 1 },
        limit       => { isa    => 'Int', optional => 1 },
        page_size   => { isa    => 'Int', optional => 1 },
        options     => { isa    => 'Str', optional => 1 },
	);
    $params{field}  = 'groups';
    $params{path}   = '/groups' . ( $params{id} ? '/' . $params{id} : '' );
    delete( $params{id} );
    return $self->_paged_request_from_api( %params );
}

=item get_custom_fields

Get list of custom fields

Details: http://docs.pingboard.apiary.io/#reference/custom-fields/custom-fields-collection/get-custom-fields

=cut

sub get_custom_fields {
    my ( $self, %params ) = validated_hash(
        \@_,
        id	    => { isa    => 'Str', optional => 1 },
        limit       => { isa    => 'Int', optional => 1 },
        page_size   => { isa    => 'Int', optional => 1 },
        options     => { isa    => 'Str', optional => 1 },
	);
    $params{field}  = 'custom_fields';
    $params{path}   = '/custom_fields' . ( $params{id} ? '/' . $params{id} : '' );
    delete( $params{id} );
    return $self->_paged_request_from_api( %params );
}

=item get_linked_accounts

Get linked accounts

Details: http://docs.pingboard.apiary.io/#reference/linked-accounts/linked-account/get-linked-account

=cut

sub get_linked_accounts {
    my ( $self, %params ) = validated_hash(
        \@_,
        id	=> { isa    => 'Int'},
        options => { isa    => 'Str', optional => 1 },
	);
    $params{field}  = 'linked_accounts';
    $params{path}   = '/linked_accounts/' . $params{id};
    delete( $params{id} );
    return $self->_paged_request_from_api( %params );
}

=item get_linked_account_providers

Get linked account providers

Details: http://docs.pingboard.apiary.io/#reference/linked-account-providers/linked-account-providers-collection/get-linked-account-providers

=cut

sub get_linked_account_providers {
    my ( $self, %params ) = validated_hash(
        \@_,
        id	    => { isa    => 'Int', optional => 1 },
        limit       => { isa    => 'Int', optional => 1 },
        page_size   => { isa    => 'Int', optional => 1 },
        options     => { isa    => 'Str', optional => 1 },
	);
    $params{field}  = 'linked_account_providers';
    $params{path}   = '/linked_account_providers' . ( $params{id} ? '/' . $params{id} : '' );
    delete( $params{id} );
    return $self->_paged_request_from_api( %params );
}

=item get_status_types

Get status types

Details: http://docs.pingboard.apiary.io/#reference/status-types/status-types-collection/get-status-types

=cut

sub get_status_types {
    my ( $self, %params ) = validated_hash(
        \@_,
        limit       => { isa    => 'Int', optional => 1 },
        page_size   => { isa    => 'Int', optional => 1 },
        options     => { isa    => 'Str', optional => 1 },
	);
    $params{field}  = 'status_types';
    $params{path}   = '/status_types';
    return $self->_paged_request_from_api( %params );
}

=item get_statuses

Get statuses

Details: http://docs.pingboard.apiary.io/#reference/statuses/status/update-status

=cut

sub get_statuses {
    my ( $self, %params ) = validated_hash(
        \@_,
        id	    => { isa    => 'Int', optional => 1 },
        include     => { isa    => 'Int', optional => 1 },
        user_id     => { isa    => 'Int', optional => 1 },
        starts_at   => { isa    => 'Str', optional => 1 },
        ends_at     => { isa    => 'Str', optional => 1 },
        limit       => { isa    => 'Int', optional => 1 },
        page_size   => { isa    => 'Int', optional => 1 },
        options     => { isa    => 'Str', optional => 1 },
	);
    $self->log->debug( "Getting statuses" );
    $params{field}  = 'statuses';
    $params{path}   = '/statuses' . ( $params{id} ? '/' . $params{id} : '' );
    delete( $params{id} );
    my @options;
    foreach( qw/include user_id starts_at ends_at/ ){
        push( @options, $_ . '=' . $params{$_} ) if $params{$_};
        delete( $params{$_} );
    }
    if( scalar( @options ) > 0 ){
        $params{options} .= ( $params{options} ? '&' : '' ) . join( '&', @options );
    }
    return $self->_paged_request_from_api( %params );
}

=item update_status

Update a Status resource.

Details: http://docs.pingboard.apiary.io/#reference/statuses/status/get-status

=over 4

=item status

HashRef object of the status - only fields being changed must be defined

=back

=cut

sub update_status {
    my ( $self, %params ) = validated_hash(
        \@_,
        id	    => { isa    => 'Int' },
        status      => { isa    => 'HashRef' },
        options     => { isa    => 'Str', optional => 1 },
	);
    $self->log->debug( "Updating status: $params{id}" );
    $params{body}   = encode_json( { "statuses" => $params{status} } );
    $params{field}  = 'statuses';
    delete( $params{status} );
    $params{method} = 'PUT';
    $params{path}   = '/statuses/' . $params{id};
    delete( $params{id} );
    return $self->_paged_request_from_api( %params );
}

=item delete_status

delete a Status resource.

Details: http://docs.pingboard.apiary.io/#reference/statuses/status/delete-status

=cut

sub delete_status {
    my ( $self, %params ) = validated_hash(
        \@_,
        id	    => { isa    => 'Int' },
        options     => { isa    => 'Str', optional => 1 },
	);
    $self->log->debug( "Deleting status: $params{id}" );
    $params{method} = 'DELETE';
    $params{path}   = '/statuses/' . $params{id};
    delete( $params{id} );
    my $response = $self->_request_from_api( %params );
    return;
}

=item create_status

Create a new Status resource.

Details: http://docs.pingboard.apiary.io/#reference/statuses/statuses-collection/create-status

=over 4

=item status

HashRef of the new status

=back

=cut

sub create_status {
    my ( $self, %params ) = validated_hash(
        \@_,
        options     => { isa    => 'Str', optional => 1 },
        status      => { isa    => 'HashRef' }
	);
    $self->log->debug( "Creating new status for user: " . $params{status}{user_id} );

    $self->log->trace( "Creating new status: \n" . Dump( $params{status} ) ) if $self->log->is_trace;
    $params{body}   = encode_json( { "statuses" => $params{status} } );
    $params{field}  = 'statuses';
    delete( $params{status} );
    $params{method} = 'POST';
    $params{path}   = '/statuses';
    return $self->_paged_request_from_api( %params );
}

=item clear_cache_object_id

Clears an object from the cache.

=over 4

=item object_id

Required.  Object id to clear from the cache.

=back

Returns whether cache_del was successful or not

=cut
sub clear_cache_object_id {
    my ( $self, %params ) = validated_hash(
        \@_,
        object_id	=> { isa    => 'Str' }
	);

    $self->log->debug( "Clearing cache id: $params{object_id}" );
    my $foo = $self->cache_del( $params{object_id} );

    return $foo;
}

sub _paged_request_from_api {
    my ( $self, %params ) = validated_hash(
        \@_,
        method	    => { isa => 'Str', optional => 1, default => 'GET' },
	path	    => { isa => 'Str' },
        field       => { isa => 'Str' },
        limit       => { isa => 'Int', optional => 1 },
        page_size   => { isa => 'Int', optional => 1 },
        options     => { isa => 'Str', optional => 1 },
        body        => { isa => 'Str', optional => 1 },
    );
    $self->log->trace( "_paged_request_from_api params:\n" . Dump( \%params ) ) if( $self->log->is_trace );

    my @results;
    my $page = 1;

    $params{page_size} ||= $self->default_page_size;
    if( $params{limit} and $params{limit} < $params{page_size} ){
        $params{page_size} = $params{limit};
    }

    my $response = undef;
    do{
        my %request_params = (
            method      => $params{method},
            path        => $params{path} . ( $params{path} =~ m/\?/ ? '&' : '?' ) . 'page=' . $page . '&page_size=' . $params{page_size},
            );
        $request_params{options} = $params{options} if( $params{options} );
        $request_params{body}    = $params{body} if( $params{body} );

        $response = $self->_request_from_api( %request_params );
	push( @results, @{ $response->{$params{field} } } );
	$page++;
      }while( $response->{meta}{$params{field}}{page} and
              $response->{meta}{$params{field}}{page} < $response->{meta}{$params{field}}{page_count} and
              ( not $params{limit} or scalar( @results ) < $params{limit} ) );
    return @results;
}


sub _request_from_api {
    my ( $self, %params ) = validated_hash(
        \@_,
        method	=> { isa => 'Str' },
	path	=> { isa => 'Str', optional => 1 },
        uri     => { isa => 'Str', optional => 1 },
        body    => { isa => 'Str', optional => 1 },
        headers => { isa => 'HTTP::Headers', optional => 1 },
        options => { isa => 'Str', optional => 1 },
    );
    my $url = $params{uri} || $self->api_url;
    $url .=  $params{path} if( $params{path} );
    $url .= ( $url =~ m/\?/ ? '&' : '?' )  . $params{options} if( $params{options} );

    my $request = HTTP::Request->new(
        $params{method},
        $url,
        $params{headers} || $self->headers,
        );
    $request->content( $params{body} ) if( $params{body} );

    $self->log->debug( "Requesting: " . $request->uri );
    $self->log->trace( "Request:\n" . Dump( $request ) ) if $self->log->is_trace;

    my $response;
    my $retry = 1;
    my $try_count = 0;
    do{
        my $retry_delay = $self->default_backoff;
        $try_count++;
        $response = $self->user_agent->request( $request );
        if( $response->is_success ){
            $retry = 0;
        }else{
            if( grep{ $_ == $response->code } @{ $self->retry_on_status } ){
                $self->log->debug( Dump( $response ) );
                if( $response->code == 429 ){
                    # if retry-after header exists and has valid data use this for backoff time
                    if( $response->header( 'Retry-After' ) and $response->header('Retry-After') =~ /^\d+$/ ) {
                        $retry_delay = $response->header('Retry-After');
                    }
                    $self->log->warn( sprintf( "Received a %u (Too Many Requests) response with 'Retry-After' header... going to backoff and retry in %u seconds!",
                            $response->code,
                            $retry_delay,
                            ) );
                }else{
                    $self->log->warn( sprintf( "Received a %u: %s ... going to backoff and retry in %u seconds!",
                            $response->code,
                            $response->decoded_content,
                            $retry_delay
                            ) );
                }
            }else{
                $retry = 0;
            }

            if( $retry == 1 ){
                if( not $self->max_tries or $self->max_tries > $try_count ){
                    $self->log->debug( sprintf( "Try %u failed... sleeping %u before next attempt", $try_count, $retry_delay ) );
                    sleep( $retry_delay );
                }else{
                    $self->log->debug( sprintf( "Try %u failed... exceeded max_tries (%u) so not going to retry", $try_count, $self->max_tries ) );
                    $retry = 0;
                }
            }
        }
    }while( $retry );

    $self->log->trace( "Last response:\n", Dump( $response ) ) if $self->log->is_trace;
    if( not $response->is_success ){
	$self->log->logdie( "API Error: http status:".  $response->code .' '.  $response->message . ' Content: ' . $response->content);
    }
    if( $response->decoded_content ){
        return decode_json( encode( 'utf8', $response->decoded_content ) );
    }
    return;
}


1;

=back

=head1 COPYRIGHT

Copyright 2015, Robin Clarke

=head1 AUTHOR

Robin Clarke <robin@robinclarke.net>

Jeremy Falling <projects@falling.se>
