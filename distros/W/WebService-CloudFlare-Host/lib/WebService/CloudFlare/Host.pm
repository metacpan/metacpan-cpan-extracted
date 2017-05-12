package WebService::CloudFlare::Host;
use Moose;
use Try::Tiny;
use Data::Dumper;
use LWP;

our $VERSION = "000100"; # 0.1.0
$VERSION = eval $VERSION;

has 'host_key' => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
);

has 'base_api'  => (
    is          => 'ro',
    isa         => 'Str',
    default     => 'https://api.cloudflare.com/host-gw.html',
);

has 'user_agent' => (
    is          => 'ro',
    isa         => 'Str',
    default     => 'WebService::CloudFlare::Host/1.0',
);

has 'http_timeout' => (
    is          => 'ro',
    isa         => 'Int',
    default     => 60,
);

has 'ua'        => (
    is          => 'ro',
    isa         => 'LWP::UserAgent',
    lazy_build  => 1,
);

sub call {
    my ( $self, $class, %args ) = @_;

    # Load the request class.
    try {
        Class::MOP::load_class("WebService::CloudFlare::Host::Request::$class");
    } catch {
        $self->_throw_exception( $_, "Loading request class: $class", 
            "Class::MOP::load_class", 
            "WebService::CloudFlare::Host::Request::$class"
        );
    };

    # Create the request object.
    my $req = try {
        "WebService::CloudFlare::Host::Request::$class"->new( %args )
    } catch {
        $self->_throw_exception( $_, 'Creating API Request',
            "WebService::CloudFlare::Host::Request::$class", Dumper \%args
        );
    };

    # Make the actual HTTP request.
    my $http_res = try {
        $self->_do_call( $req );
    } catch {
        $self->_throw_exception( $_, 'Making HTTP Call To Server API',
            'WebService::CloudFlare::Host::do_call', Dumper $req
        );
    };

    # Create a response object to send back to the user.
    my $res = try {
        $self->_create_response( $class, $http_res );
    } catch {
        $self->_throw_exception( $_, 'Creating API Response From HTTP Data',
            'WebService::CloudFlare::Host::create_response', Dumper $http_res,
        );
    };
    return $res;
}

sub _throw_exception {
    my ( $self, $message, $layer, $function, $args ) = @_;

    # We installed ::Exception with the package, it's here.
    Class::MOP::load_class('WebService::CloudFlare::Host::Exception');

    # Let's get to the bottom of the exception...
    my $exception;
    while ( $message->isa( 'WebService::CloudFlare::Host::Exception' ) ) {
        $exception = $message;
        $message = $message->message;
    }
    die $exception if $exception;


    die WebService::CloudFlare::Host::Exception->new( 
        message  => $message,
        layer    => $layer,
        function => $function,
        args     => $args,
    );
}

sub _do_call {
    my ( $self, $request ) = @_;
    
    my %arguments = $request->as_post_params;
    $arguments{host_key} = $self->host_key;

    return $self->ua->post($self->base_api, \%arguments);
}

sub _create_response {
    my ( $self, $class, $http ) = @_;
    
    try {
        Class::MOP::load_class("WebService::CloudFlare::Host::Response::$class");
    } catch {
        $self->_throw_exception( $_, "Loading request class: $class", 
            "Class::MOP::load_class", 
            "WebService::CloudFlare::Host::Reponse::$class"
        );
    };

    return "WebService::CloudFlare::Host::Response::$class"->new( $http );

}

sub _build_ua {
    my ( $self ) = @_;
    return LWP::UserAgent->new(
        timeout => $self->http_timeout,
        user_agent => $self->user_agent
    );
}

1;

=head1 NAME

WebService::CloudFlare::Host - A client API For Hosting Partners 

=head1 VERSION

000100 (0.1.0)

=head1 SYNOPSIS

    my $CloudFlare = WebService::CloudFlare::Host->new(
        host_key => 'cloudflare hostkey',
        timeout  => 30,
    );

    my $response = eval { $CloudFlare->call('UserCreate',
        email => 'richard.castle@hyperionbooks.com',
        pass  => 'ttekceBetaK',
    ) };

    if ( $@ ) {
        die "Error: in " . $@->function . ": " . $@->message;
    }


    printf("Got API Keys: User Key: %s, User API Key: %s",
        $response->user_key, $response->api_key
    );

=head1 DESCRIPTION

WebService::CloudFlare::Host is a client side API library
to make using CloudFlare simple for hosting providers.

It gives a simple interface for making API calls, getting
response objects, and implementing additional API calls.

All API calls have a Request and Response object that define
the accepted information for that call.

=head1 METHODS

The only method used is C<call($api_call, %arguments)>.

When making an API call, the first argument defines the API request
to load.  This is loaded from Request::.  Additional arguments are
passed as-is to the Request Object.

Once the object has been made, an HTTP call to the CloudFlare API
is made.  The JSON returned is used to construct a Response object
loaded from Response:: with the same name as the Request object.

C<call> dies on error, giving a WebService::CloudFlare::Host::Exception
object and should be run in an eval or with Try::Tiny.

=head1 STANDARD OBJECT METHODS

=head2 Standard Request Object

The host key is dynamically inserted into the Requests.

=head2 Standard Response Object 

The following methods are avilable on standard Response objects.

=over 4

=item result

The result sent from the API: 'success' or 'error'.

=item message

If the result is 'error', a message will be set with a user-readable explaination
of the error; otherwise, this method will not exist.

=item code

If the result is 'error', a code will be set.  This error can be found at
L<http://www.cloudflare.com/docs/host-api.html>.

=back

=head1 API CALLS


=head2 UserCreate

The UserCreate API call creates a user for the CloudFlare
service, as if they had signed up through CloudFlare's website.

my $response = eval { $CloudFlare->call('UserCreate',
    email => 'Casey.Klein@partydown.com',
    pass  => 'omgPassword',
    unique_id => '506172747920446f776e203c33205521',
)};

=head3 Request

The request uses the following parameters:

=over 4

=item email 

The email address that the end-user can use to sign into
the CloudFlare service.

=item pass

The password the user can use to sign into the CloudFlare service.
This should not be recorded on the Hosting Provider's side.

=item user

A username for the user.  This is used in saluations and emails from
CloudFlare.  It has no bearing in the rest of the API.

=item unique_id

A unique id that may be used for UserLookup calls (as opposed to the 
user's email address).

=item clobber

When set to 1, a user's unique_id can be replaced with a new unique_id.

=back 

=head3 Response

printf("Created account for %s, with Unique ID => %s, "
    . "User Key => %s, and API Key => %s",
    $response->unique_id, $response->user_key, $response->api_key
    );

The response sets the following methods:

=over 4

=item api_key

This API key allows a hosting provider to act as the user.  All user
API requests can be completed with this key.

=item email

This is the registered email account for the CloudFlare user.

=item user_key

This user_key is used to make Hosting API calls, specifically
the ZoneSet, ZoneDelete, and ZoneLookup API calls. 

=item unique_id

This can be used instead of the email address to do UserLookup calls.

=item username

The username.

=back

=head2 UserAuth

The UserAuth API call gives the hosting provider access to
the User's account.  The call returns a user_key as well as
the api_key and authenticates the Hosting Provider to perform
actions as the user.

=head3 Request

my $response = eval { $CloudFlare->call('UserAuth',
    email => 'Casey.Klein@partydown.com',
    pass  => 'omgPassword',
) };

The request uses the following parameters:

=over 4

=item email

The email address that the user used to register the account
with CloudFlare.

=item pass

The password the user uses to login to CloudFlare.  This should
not be stored on a hosting provider's side.

=item unique_id

A unique_id that may be used to perform UserLookup API calls.

=item clobber

If true, the unique_id can be clobbered.

=back 

=head3 Response

The response sets the following methods:

=over 4

=item api_key

This API key allows a hosting provider to act as the user.  All user
API requests can be completed with this key.

=item email

This is the registered email account for the CloudFlare user.

=item user_key

This user_key is used to make Hosting API calls, specifically
the ZoneSet, ZoneDelete, and ZoneLookup API calls. 

=item unique_id

This can be used instead of the email address to do UserLookup calls.

=back

=head2 UserLookup

The UserLookup API call gives a hosting provider the ablity
to find information on a user account that it has access to through
either the unique_id or the email address that was used in UserAuth
or UserCreate API calls.

=head3 Request

my $response = eval { $CloudFlare->call('UserLookup',
    email => 'Casey.Klein@partydown.com',
) };

The request uses the following parameters:

=over 4

=item email

The email address that was used in UserCreate or UserAuth
API call.  This is required if C<unique_id> is not set.

=item unique_id

The unique_id that was last set in UserCreate or UserAuth
API call.  This is required if C<email> is not set.

=back 

=head3 Response

The response sets the following methods:

=over 4

=item api_key

This API key allows a hosting provider to act as the user.  All user
API requests can be completed with this key.

=item email

This is the registered email account for the CloudFlare user.

=item user_key

This user_key is used to make Hosting API calls, specifically
the ZoneSet, ZoneDelete, and ZoneLookup API calls. 

=item unique_id

This can be used instead of the email address to do UserLookup calls.

=item user_authed

True if the hosting provider has access to this user.

=item user_exists

True if the user exists in the CloudFlare system.

=item zones

A list of zones that the user has associated with his or her account.

=back

=head2 ZoneSet

This associates a zone with the CloudFlare service for the
user whose user_key is used.

=head3 Request

my $response = eval { $CloudFlare->call('ZoneSet',
    user_key    => 'e7af5f120e3240e7bfba063b5f62c922',
    resolve_to  => '173.230.133.102',
    zone_name   => 'partydown.com',
    subdomains  => 'www',
) };

The request uses the following parameters:

=over 4

=item user_key

The user_key provided by UserCreate, UserLookup, or UserAuth.

The zone will be associated with the user whose user_key is used.

=item resolve_to

The IP address or a CNAME that resolves to the origin server that
hosts the content for the given website.

=item zone_name

The name of the domain.

=item subdomains

A comma-seperated list of the subdomains from the zone for which
CloudFlare should act as a reverse proxy.

=back 

=head3 Response

The response sets the following methods:

=over 4

=item zone_name

The name of the domain.

=item resolving

The origin server that has been recorded.  The same as the one
submitted in the Request.

=item forwarded

A hashref whose keys are the domain, and whose value is the CNAME that
should be used in the DNS system to have the requests be processed by
CloudFlare.

=item hosted

A hashref whose keys are the the domain name(s) that are hosted, and
whose value is the resolving address.

=back

=head2 ZoneDelete

This will remove a zone from being hosted by the user whose
user_key is used, provided they are the ones hosting the zone.

=head3 Request

my $response = eval { $CloudFlare->call('ZoneDelete',
    user_key    => 'e7af5f120e3240e7bfba063b5f62c922',
    zone_name   => 'partydown.com',
) };

The request uses the following parameters:

=over 4

=item user_key

The user_key of the user whose zone is being removed from CloudFlare.

=item zone_name

The name of the zone to be removed.

=back 

=head3 Response

The response sets the following methods:

=over 4

=item zone_name

The name of the zone from the Request.

=item zone_deleted

True if the zone was deleted.

=back

=head2 ZoneLookup

Find information on a zone hosted by a given user_key.

=head3 Request

my $response = eval { $CloudFlare->call('ZoneLookup',
    user_key    => 'e7af5f120e3240e7bfba063b5f62c922',
    zone_name   => 'partydown.com',
) };

The request uses the following parameters:

=over 4

=item user_key

The user_key of the user whose zone is being removed from CloudFlare.

=item zone_name

The name of the zone to be removed.

=back 

=head3 Response

The response sets the following methods:

=over 4

=item zone_name

=item resolving

The origin server that has been recorded.  The same as the one
submitted in the Request.

=item forwarded

A hashref whose keys are the domain, and whose value is the CNAME that
should be used in the DNS system to have the requests be processed by
CloudFlare.

=item hosted

A hashref whose keys are the the domain name(s) that are hosted, and
whose value is the resolving address.

=item zone_exists

True if the zone exists in the CloudFlare service.

=item zone_hosted

True if the zone is hosted by this user_key.

=back

=head1 CREATING API CALLS

TBD

=head2 Request Classes

=head2 Response Classes

=head1 AUTHOR

SymKat I<E<lt>symkat@symkat.comE<gt>>

=head1 COPYRIGHT AND LICENSE

This is free software licensed under a I<BSD-Style> License.  Please see the 
LICENSE file included in this package for more detailed information.

=head1 AVAILABILITY

The latest version of this software is available through GitHub at
https://github.com/symkat/webservice-cloudflare-host/

=cut
