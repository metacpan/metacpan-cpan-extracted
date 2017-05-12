package WebService::Zendesk;
# ABSTRACT: API interface to Zendesk
use Moose;
use MooseX::Params::Validate;
use MooseX::WithCache;
use File::Spec::Functions; # catfile
use MIME::Base64;
use File::Path qw/make_path/;
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Headers;
use JSON::MaybeXS;
use YAML;
use URI::Encode qw/uri_encode/;
use Encode;

our $VERSION = 0.023;

=head1 NAME

WebService::Zendesk

=head1 DESCRIPTION

Manage Zendesk connection, get tickets etc.  This is a work-in-progress - we have only written
the access methods we have used so far, but as you can see, it is a good template to extend
for all remaining API endpoints.  I'm totally open for any pull requests! :)

This module uses MooseX::Log::Log4perl for logging - be sure to initialize!

=head1 ATTRIBUTES

=cut

with "MooseX::Log::Log4perl";

=over 4

=item cache

Optional.

Provided by MooseX::WithCache - optionally pass a cache object to cache and avoid unnecessary requests

=cut

has 'cache' => (
    is          => 'ro',
    required    => 0,
    trigger     => \&_setup_cache,
    );

sub _setup_cache {
    my( $self, $cache ) = @_;
    my $backend = ref( $cache );

    with 'MooseX::WithCache' => {
        backend => $backend,
    };
}

=item zendesk_token

Required.

=cut
has 'zendesk_token' => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    );

=item zendesk_username

Required.

=cut
has 'zendesk_username' => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
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

=item zendesk_api_url

Required.

=cut
has 'zendesk_api_url' => (
    is		=> 'ro',
    isa		=> 'Str',
    required	=> 1,
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

has '_zendesk_credentials' => (
    is		=> 'ro',
    isa		=> 'Str',
    required	=> 1,
    lazy	=> 1,
    builder	=> '_build_zendesk_credentials',
    );
    
has 'default_headers' => (
    is		=> 'ro',
    isa		=> 'HTTP::Headers',
    required	=> 1,
    lazy	=> 1,
    builder	=> '_build_default_headers',
    );

sub _build_user_agent {
    my $self = shift;
    $self->log->debug( "Building zendesk useragent" );
    my $ua = LWP::UserAgent->new(
	keep_alive	=> 1
    );
   # $ua->default_headers( $self->default_headers );
    return $ua;
}

sub _build_default_headers {
    my $self = shift;
    my $h = HTTP::Headers->new();
    $h->header( 'Content-Type'	=> "application/json" );
    $h->header( 'Accept'	=> "application/json" );
    $h->header( 'Authorization' => "Basic " . $self->_zendesk_credentials );
    return $h;
}

sub _build_zendesk_credentials {
    my $self = shift;
    return encode_base64( $self->zendesk_username . "/token:" . $self->zendesk_token );
}

=back

=head1 METHODS

=over 4

=item init

Create the user agent and credentials.  As these are built lazily, initialising manually can avoid
errors thrown when building them later being silently swallowed in try/catch blocks.

=cut

sub init {
    my $self = shift;
    my $ua = $self->user_agent;
    my $credentials = $self->_zendesk_credentials;
}

=item get_incremental_tickets

Access the L<Incremental Ticket Export|https://developer.zendesk.com/rest_api/docs/core/incremental_export#incremental-ticket-export> interface

!! Broken !!

=cut
sub get_incremental_tickets {
    my ( $self, %params ) = validated_hash(
        \@_,
        size        => { isa    => 'Int', optional => 1 },
    );
    my $path = '/incremental/ticket_events.json';
    my @results = $self->_paged_get_request_from_api(
        field   => '???', # <--- TODO
        method  => 'get',
	path    => $path,
        size    => $params{size},
        );

    $self->log->debug( "Got " . scalar( @results ) . " results from query" );
    return @results;

}

=item search

Access the L<Search|https://developer.zendesk.com/rest_api/docs/core/search> interface

Parameters

=over 4

=item query

Required.  Query string

=item sort_by

Optional. Default: "updated_at"

=item sort_order

Optional. Default: "desc"

=item size

Optional.  Integer indicating the number of entries to return.  The number returned may be slightly larger (paginating will stop when this number is exceeded).

=back

Returns array of results.

=cut
sub search {
    my ( $self, %params ) = validated_hash(
        \@_,
        query	    => { isa    => 'Str' },
        sort_by     => { isa    => 'Str', optional => 1, default => 'updated_at' },
        sort_order  => { isa    => 'Str', optional => 1, default => 'desc' },
        size        => { isa    => 'Int', optional => 1 },
    );
    $self->log->debug( "Searching: $params{query}" );
    my $path = '/search.json?query=' . uri_encode( $params{query} ) . "&sort_by=$params{sort_by}&sort_order=$params{sort_order}";

    my %request_params = (
        field   => 'results',
        method  => 'get',
	path    => $path,
    );
    $request_params{size} = $params{size} if( $params{size} );
    my @results = $self->_paged_get_request_from_api( %request_params );
    # TODO - cache results if tickets, users or organizations

    $self->log->debug( "Got " . scalar( @results ) . " results from query" );
    return @results;
}

=item get_comments_from_ticket

Access the L<List Comments|https://developer.zendesk.com/rest_api/docs/core/ticket_comments#list-comments> interface

Parameters

=over 4

=item ticket_id

Required.  The ticket id to query on.

=back

Returns an array of comments

=cut
sub get_comments_from_ticket {
    my ( $self, %params ) = validated_hash(
        \@_,
        ticket_id	=> { isa    => 'Int' },
    );

    my $path = '/tickets/' . $params{ticket_id} . '/comments.json';
    my @comments = $self->_paged_get_request_from_api(
            method  => 'get',
	    path    => $path,
            field   => 'comments',
	);
    $self->log->debug( "Got " . scalar( @comments ) . " comments" );
    return @comments;
}

=item download_attachment

Download an attachment.

Parameters

=over 4

=item attachment

Required.  An attachment HashRef as returned as part of a comment.

=item dir

Directory to download to

=item force

Force overwrite if item already exists

=back

Returns path to the downloaded file

=cut

sub download_attachment {
    my ( $self, %params ) = validated_hash(
        \@_,
        attachment	=> { isa	=> 'HashRef' },
	dir	        => { isa	=> 'Str' },
	force		=> { isa	=> 'Bool', optional => 1 },
    );
    
    my $target = catfile( $params{dir}, $params{attachment}{file_name} ); 
    $self->log->debug( "Downloading attachment ($params{attachment}{size} bytes)\n" .
        "    URL: $params{attachment}{content_url}\n    target: $target" );

    # Deal with target already exists
    # TODO Check if the local size matches the size which we should be downloading
    if( -f $target ){
	if( $params{force} ){
	    $self->log->info( "Target already exist, but downloading again because force enabled: $target" );
	}else{
	    $self->log->info( "Target already exist, not overwriting: $target" );
	    return $target;
	}
    }
    
    # Empty headers so we don't get a http 406 error
    my $headers = $self->default_headers->clone();
    $headers->header( 'Content-Type'  => '' );
    $headers->header( 'Accept'        => '' );
    $self->_request_from_api(
        method      => 'GET',
        uri         => $params{attachment}{content_url},
        headers     => $headers,
        fields  => { ':content_file' => $target },
        );
    return $target;
}

=item get_attachment

Get attachment objects

Parameters

=over 4

=item id

required. The id of the attachment

=back

Returns attachment object

=cut

sub get_attachment {
    my ( $self, %params ) = validated_hash(
        \@_,
        id	=> { isa	=> 'Int' },
    );
    $self->log->debug( "Getting attachment: $params{id}" );
    my $path = '/attachments/' . $params{id} . '.json';
    my( $attachment ) = $self->_paged_get_request_from_api(
            method  => 'get',
	    path    => $path,
            field   => 'attachment',
	);
    return $attachment;
}


=item add_response_to_ticket

Shortcut to L<Updating Tickets|https://developer.zendesk.com/rest_api/docs/core/tickets#updating-tickets> specifically for adding a response.

=over 4

=item ticket_id

Required.  Ticket to add response to

=item public

Optional.  Default: 0 (not public).  Set to "1" for public response

=item response

Required.  The text to be addded to the ticket as response.

=back

Returns response HashRef

=cut
sub add_response_to_ticket {
    my ( $self, %params ) = validated_hash(
        \@_,
        ticket_id	=> { isa    => 'Int' },
	public		=> { isa    => 'Bool', optional => 1, default => 0 },
	response	=> { isa    => 'Str' },
    );

    my $body = {
	"ticket" => {
	    "comment" => {
		"public"    => $params{public},
		"body"	    => $params{response},
	    }
	}
    };
    return $self->update_ticket(
        body        => $body,
        ticket_id   => $params{ticket_id},
        );

}

=item update_ticket

Access L<Updating Tickets|https://developer.zendesk.com/rest_api/docs/core/tickets#updating-tickets> interface.

=over 4

=item ticket_id

Required.  Ticket to add response to

=item body

Required.  HashRef of valid parameters - see link above for details.

=back

Returns response HashRef

=cut
sub update_ticket {
    my ( $self, %params ) = validated_hash(
        \@_,
        ticket_id	=> { isa    => 'Int' },
	body		=> { isa    => 'HashRef' },
	no_cache        => { isa    => 'Bool', optional => 1 }
    );

    my $encoded_body = encode_json( $params{body} );
    $self->log->trace( "Submitting:\n" . $encoded_body ) if $self->log->is_trace;

    my $response = $self->_request_from_api(
        method          => 'PUT',
        path            => '/tickets/' . $params{ticket_id} . '.json',
        body            => $encoded_body,
        );
    $self->cache_set( 'ticket-' . $params{ticket_id}, $response->{ticket} ) unless( $params{no_cache} );
    return $response;
}

=item get_ticket

Access L<Getting Tickets|https://developer.zendesk.com/rest_api/docs/core/tickets#getting-tickets> interface.

=over 4

=item ticket_id

Required.  Ticket to get

=item no_cache

Disable cache get/set for this operation

=back

Returns ticket HashRef

=cut
sub get_ticket {
    my ( $self, %params ) = validated_hash(
        \@_,
        ticket_id	=> { isa    => 'Int' },
        no_cache        => { isa    => 'Bool', optional => 1 }
    );
    
    # Try and get the info from the cache
    my $ticket;
    $ticket = $self->cache_get( 'ticket-' . $params{ticket_id} ) unless( $params{no_cache} );
    if( not $ticket ){
	$self->log->debug( "Ticket info not cached, requesting fresh: $params{ticket_id}" );
	my $info = $self->_request_from_api(
            method      => 'GET',
            path        => '/tickets/' . $params{ticket_id} . '.json',
            );
	
	if( not $info or not $info->{ticket} ){
	    $self->log->logdie( "Could not get ticket info for ticket: $params{ticket_id}" );
	}
        $ticket = $info->{ticket};
	# Add it to the cache so next time no web request...
	$self->cache_set( 'ticket-' . $params{ticket_id}, $ticket ) unless( $params{no_cache} );
    }
    return $ticket;
}

=item get_many_tickets

Access L<Show Many Organizations|https://developer.zendesk.com/rest_api/docs/core/organizations#show-many-organizations> interface.

=over 4

=item ticket_ids

Required.  ArrayRef of ticket ids to get

=item no_cache

Disable cache get/set for this operation

=back

Returns an array of ticket HashRefs

=cut
sub get_many_tickets {
    my ( $self, %params ) = validated_hash(
        \@_,
        ticket_ids    => { isa    => 'ArrayRef' },
        no_cache      => { isa    => 'Bool', optional => 1 }
    );

    # First see if we already have any of the ticket in our cache - less to get
    my @tickets;
    my @get_tickets;
    foreach my $ticket_id ( @{ $params{ticket_ids} } ){
        my $ticket;
        $ticket = $self->cache_get( 'ticket-' . $ticket_id ) unless( $params{no_cache} );
        if( $ticket ){
            $self->log->debug( "Found ticket in cache: $ticket_id" );
            push( @tickets, $ticket );
        }else{
            push( @get_tickets, $ticket_id );
        }
    }

    # If there are any tickets remaining, get these with a bulk request
    if( scalar( @get_tickets ) > 0 ){
	$self->log->debug( "Tickets not in cache, requesting fresh: " . join( ',', @get_tickets ) );

	#limit each request to 100 tickets per api spec
	my @split_tickets;
	push @split_tickets, [ splice @get_tickets, 0, 100 ] while @get_tickets;

	foreach my $cur_tickets ( @split_tickets ) {
	    my @result= $self->_paged_get_request_from_api(
		field   => 'tickets',
		method  => 'get',
		path    => '/tickets/show_many.json?ids=' . join( ',', @{ $cur_tickets } ),
		);
	    foreach( @result ){
		$self->log->debug( "Writing ticket to cache: $_->{id}" );
		$self->cache_set( 'ticket-' . $_->{id}, $_ ) unless( $params{no_cache} );
		push( @tickets, $_ );
	    }
	}
    }
    return @tickets;
}

=item get_organization

Get a single organization by accessing L<Getting Organizations|https://developer.zendesk.com/rest_api/docs/core/organizations#list-organizations>
interface with a single organization_id.  The get_many_organizations interface detailed below is more efficient for getting many organizations
at once.

=over 4

=item organization_id

Required.  Organization id to get

=item no_cache

Disable cache get/set for this operation

=back

Returns organization HashRef

=cut
sub get_organization {
    my ( $self, %params ) = validated_hash(
        \@_,
        organization_id	=> { isa    => 'Int' },
        no_cache        => { isa    => 'Bool', optional => 1 }
    );

    my $organization;
    $organization = $self->cache_get( 'organization-' . $params{organization_id} ) unless( $params{no_cache} );
    if( not $organization ){
	$self->log->debug( "Organization info not in cache, requesting fresh: $params{organization_id}" );
	my $info = $self->_request_from_api(
            method      => 'GET',
            path        => '/organizations/' . $params{organization_id} . '.json',
            );
	if( not $info or not $info->{organization} ){
	    $self->log->logdie( "Could not get organization info for organization: $params{organization_id}" );
	}
        $organization = $info->{organization};

	# Add it to the cache so next time no web request...
	$self->cache_set( 'organization-' . $params{organization_id}, $organization ) unless( $params{no_cache} );
    }
    return $organization;
}

=item get_many_organizations

=over 4

=item organization_ids

Required.  ArrayRef of organization ids to get

=item no_cache

Disable cache get/set for this operation

=back

Returns an array of organization HashRefs

=cut
#get data about multiple organizations.
sub get_many_organizations {
    my ( $self, %params ) = validated_hash(
        \@_,
        organization_ids    => { isa    => 'ArrayRef' },
        no_cache            => { isa    => 'Bool', optional => 1 }
    );

    # First see if we already have any of the organizations in our cache - less to get
    my @organizations;
    my @get_organization_ids;
    foreach my $org_id ( @{ $params{organization_ids} } ){
        my $organization;
        $organization = $self->cache_get( 'organization-' . $org_id ) unless( $params{no_cache} );
        if( $organization ){
            $self->log->debug( "Found organization in cache: $org_id" );
            push( @organizations, $organization );
        }else{
            push( @get_organization_ids, $org_id );
        }
    }

    # If there are any organizations remaining, get these with a single request
    if( scalar( @get_organization_ids ) > 0 ){
	$self->log->debug( "Organizations not in cache, requesting fresh: " . join( ',', @get_organization_ids ) );
	my @result= $self->_paged_get_request_from_api(
	    field   => 'organizations',
            method  => 'get',
	    path    => '/organizations/show_many.json?ids=' . join( ',', @get_organization_ids ),
	    );

	#if an org is not found it is dropped from the results so we need to check for this and show an warning
	if ( $#result != $#get_organization_ids ) {
	    foreach my $org_id ( @get_organization_ids ){
		my $org_found = grep { $_->{id} == $org_id } @result;
		unless ( $org_found ) {
		    $self->log->warn( "The following organization id was not found in Zendesk: $org_id");
		}
	    }
	}
        foreach( @result ){
            $self->log->debug( "Writing organization to cache: $_->{id}" );
            $self->cache_set( 'organization-' . $_->{id}, $_ ) unless( $params{no_cache} );
            push( @organizations, $_ );
        }
    }
    return @organizations;
}


=item update_organization

Use the L<Update Organization|https://developer.zendesk.com/rest_api/docs/core/organizations#update-organization> interface.

=over 4

=item organization_id

Required.  Organization id to update

=item details

Required.  HashRef of the details to be updated.

=item no_cache

Disable cache set for this operation

=back

returns the 
=cut
sub update_organization {
    my ( $self, %params ) = validated_hash(
        \@_,
	organization_id	=> { isa    => 'Int' },
	details	        => { isa    => 'HashRef' },
        no_cache        => { isa    => 'Bool', optional => 1 }
    );

    my $body = {
	"organization" =>
	    $params{details}
    };

    my $encoded_body = encode_json( $body );
    $self->log->trace( "Submitting:\n" . $encoded_body ) if $self->log->is_trace;
    my $response = $self->_request_from_api(
        method      => 'PUT',
        path        => '/organizations/' . $params{organization_id} . '.json',
        body        => $encoded_body,
        );
    if( not $response or not $response->{organization}{id} == $params{organization_id} ){
	$self->log->logdie( "Could not update organization: $params{organization_id}" );
    }

    $self->cache_set( 'organization-' . $params{organization_id}, $response->{organization} ) unless( $params{no_cache} );

    return $response->{organization};
}

=item list_organization_users

Use the L<List Users|https://developer.zendesk.com/rest_api/docs/core/users#list-users> interface.

=over 4

=item organization_id

Required.  Organization id to get users from

=item no_cache

Disable cache set/get for this operation

=back

Returns array of users

=cut
sub list_organization_users {
    my ( $self, %params ) = validated_hash(
        \@_,
        organization_id	=> { isa    => 'Int' },
        no_cache        => { isa    => 'Bool', optional => 1 }
	);

    # for caching we store an array of user ids for each organization and attempt to get these from the cache
    my $user_ids_arrayref = $self->cache_get( 'organization-users-ids-' . $params{organization_id} ) unless( $params{no_cache} );
    my @users;

    if( $user_ids_arrayref ){
        $self->log->debug( sprintf "Users from cache for organization_id: %u", scalar(  @{ $user_ids_arrayref } ), $params{organization_id} );
	#get the data for each user in the ticket array
	my @user_data = $self->get_many_users (
	    user_ids => $user_ids_arrayref,
	    no_cache => $params{no_cache},
	    );
	push (@users, @user_data);

    }else{
        $self->log->debug( "Requesting users fresh for organization: $params{organization_id}" );
        @users = $self->_paged_get_request_from_api(
            field   => 'users',
            method  => 'get',
            path    => '/organizations/' . $params{organization_id} . '/users.json',
        );

	$user_ids_arrayref = [ map{ $_->{id} } @users ];

	$self->cache_set( 'organization-users-ids-' . $params{organization_id}, $user_ids_arrayref ) unless( $params{no_cache} );
        foreach( @users ){
	    $self->log->debug( "Writing ticket to cache: $_->{id}" );
	    $self->cache_set( 'user-' . $_->{id}, $_ ) unless( $params{no_cache} );
        }
    }
    $self->log->debug( sprintf "Got %u users for organization: %u", scalar( @users ), $params{organization_id} );

    return @users;
}


=item get_many_users

Access L<Show Many Users|https://developer.zendesk.com/rest_api/docs/core/users#show-many-users> interface.

=over 4

=item user_ids

Required.  ArrayRef of user ids to get

=item no_cache

Disable cache get/set for this operation

=back

Returns an array of user HashRefs

=cut

sub get_many_users {
    my ( $self, %params ) = validated_hash(
        \@_,
        user_ids    => { isa    => 'ArrayRef' },
        no_cache      => { isa    => 'Bool', optional => 1 }
    );

    # First see if we already have any of the user in our cache - less to get
    my @users;
    my @get_users;
    foreach my $user_id ( @{ $params{user_ids} } ){
        my $user;
        $user = $self->cache_get( 'user-' . $user_id ) unless( $params{no_cache} );
        if( $user ){
            $self->log->debug( "Found user in cache: $user_id" );
            push( @users, $user );
        }else{
            push( @get_users, $user_id );
        }
    }

    # If there are any users remaining, get these with a bulk request
    if( scalar( @get_users ) > 0 ){
	$self->log->debug( "Users not in cache, requesting fresh: " . join( ',', @get_users ) );

	#limit each request to 100 users per api spec
	my @split_users;
	push @split_users, [ splice @get_users, 0, 100 ] while @get_users;

	foreach my $cur_users (@split_users) {
	    my @result= $self->_paged_get_request_from_api(
		field   => 'users',
		method  => 'get',
		path    => '/users/show_many.json?ids=' . join( ',', @{ $cur_users } ),
		);
	    foreach( @result ){
		$self->log->debug( "Writing user to cache: $_->{id}" );
		$self->cache_set( 'user-' . $_->{id}, $_ ) unless( $params{no_cache} );
		push( @users, $_ );
	    }
	}
    }
    return @users;
}


=item update_user

Use the L<Update User|https://developer.zendesk.com/rest_api/docs/core/users#update-user> interface.

=over 4

=item user_id

Required.  User id to update

=item details

Required.  HashRef of the details to be updated.

=item no_cache

Disable cache set for this operation

=back

returns the
=cut
sub update_user {
    my ( $self, %params ) = validated_hash(
        \@_,
        user_id         => { isa    => 'Int' },
        details         => { isa    => 'HashRef' },
        no_cache        => { isa    => 'Bool', optional => 1 }
    );

    my $body = {
        "user" => $params{details}
    };

    my $encoded_body = encode_json( $body );
    $self->log->trace( "Submitting:\n" . $encoded_body ) if $self->log->is_trace;
    my $response = $self->_request_from_api(
        method      => 'PUT',
        path        => '/users/' . $params{user_id} . '.json',
        body        => $encoded_body,
        );

    if( not $response or not $response->{user}{id} == $params{user_id} ){
        $self->log->logdie( "Could not update user: $params{user_id}" );
    }

    $self->cache_set( 'user-' . $params{user_id}, $response->{user} ) unless( $params{no_cache} );

    return $response->{user};
}

=item list_user_assigned_tickets

Use the L<List assigned tickets|https://developer.zendesk.com/rest_api/docs/core/tickets#listing-tickets> interface.

=over 4

=item user_id

Required.  User id to get assigned tickets from

=item no_cache

Disable cache set/get for this operation

=back

Returns array of tickets

=cut
sub list_user_assigned_tickets {
    my ( $self, %params ) = validated_hash(
        \@_,
        user_id	    => { isa    => 'Int' },
        no_cache    => { isa    => 'Bool', optional => 1 }
	);

    #for caching we store an array of ticket ids under the user, then look at the ticket cache
    my $ticket_ids_arrayref = $self->cache_get( 'user-assigned-tickets-ids-' . $params{user_id} ) unless( $params{no_cache} );
    my @tickets;
    if( $ticket_ids_arrayref ){
        $self->log->debug( sprintf "Tickets from cache for user: %u", scalar( @{ $ticket_ids_arrayref } ), $params{user_id} );
	#get the data for each ticket in the ticket array
	@tickets = $self->get_many_tickets (
	    ticket_ids => $ticket_ids_arrayref,
	    no_cache => $params{no_cache},
	    );
    }else{
        $self->log->debug( "Requesting tickets fresh for user: $params{user_id}" );
        @tickets = $self->_paged_get_request_from_api(
            field   => 'tickets',
            method  => 'get',
            path    => '/users/' . $params{user_id} . '/tickets/assigned.json',
	    );
	$ticket_ids_arrayref = [ map{ $_->{id} } @tickets ];

	$self->cache_set( 'user-assigned-tickets-ids-' . $params{user_id}, $ticket_ids_arrayref ) unless( $params{no_cache} );

        foreach( @tickets ){
	    $self->log->debug( "Writing ticket to cache: $_->{id}" );
	    $self->cache_set( 'ticket-' . $_->{id}, $_ ) unless( $params{no_cache} );
        }
    }
    $self->log->debug( sprintf "Got %u assigned tickets for user: %u", scalar( @tickets ), $params{user_id} );

    return @tickets;
}


=item clear_cache_object_id

Clears an object from the cache.

=over 4

=item user_id

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

sub _paged_get_request_from_api {
    my ( $self, %params ) = validated_hash(
        \@_,
        method	=> { isa => 'Str' },
	path	=> { isa => 'Str' },
        field   => { isa => 'Str' },
        size    => { isa => 'Int', optional => 1 },
        body    => { isa => 'Str', optional => 1 },
    );
    my @results;
    my $page = 1;
    my $response = undef;
    do{
        $response = $self->_request_from_api(
            method      => 'GET',
            path        => $params{path} . ( $params{path} =~ m/\?/ ? '&' : '?' ) . 'page=' . $page,
            );

        $self->log->trace( "Response:\n" . Dump( $response ) ) if $self->log->is_trace();
        if( ref( $response->{$params{field}} ) eq 'ARRAY' ){
	    push( @results, @{ $response->{$params{field} } } );
        }else{
            push( @results, $response->{$params{field}} );
        }
	$page++;
      }while( $response->{next_page} and ( not $params{size} or scalar( @results ) < $params{size} ) );

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
        fields  => { isa => 'HashRef', optional => 1 },
        
    );
    my $url;
    if( $params{uri} ){
        $url = $params{uri};
    }elsif( $params{path} ){
        $url =  $self->zendesk_api_url . $params{path};
    }else{
        $self->log->logdie( "Cannot request without either a path or uri" );
    }

    my $request = HTTP::Request->new(
        $params{method},
        $url,
        $params{headers} || $self->default_headers,
        );
    $request->content( $params{body} ) if( $params{body} );

    $self->log->debug( "Requesting from Zendesk: " . $request->uri );
    $self->log->trace( "Request:\n" . Dump( $request ) ) if $self->log->is_trace;

    my $response;
    my $retry = 1;
    my $try_count = 0;
    do{
        my $retry_delay = $self->default_backoff;
        $try_count++;
        # Fields are a special use-case for GET requests:
        # https://metacpan.org/pod/LWP::UserAgent#ua-get-url-field_name-value
        if( $params{fields} ){
            if( $request->method ne 'GET' ){
                $self->log->logdie( 'Cannot use fields unless the request method is GET' );
            }
            my %fields = %{ $params{fields} };
            my $headers = $request->headers();
            foreach( keys( %{ $headers } ) ){
                $fields{$_} = $headers->{$_};
            }
            $self->log->trace( "Fields:\n" . Dump( \%fields ) );
            $response = $self->user_agent->get(
                $request->uri(),
                %fields,
            );
        }else{
            $response = $self->user_agent->request( $request );
        }
        if( $response->is_success ){
            $retry = 0;
        }else{
            if( grep{ $_ == $response->code } @{ $self->retry_on_status } ){
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

    $self->log->trace( "Last zendesk response:\n", Dump( $response ) ) if $self->log->is_trace;
    if( not $response->is_success ){
	$self->log->logdie( "Zendesk Error: http status:".  $response->code .' '.  $response->message . ' Content: ' . $response->content);
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

