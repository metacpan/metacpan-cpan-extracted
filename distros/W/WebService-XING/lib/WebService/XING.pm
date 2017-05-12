package WebService::XING;

use 5.010;

use Carp ();
use Digest::SHA ();
use JSON ();
use LWP::UserAgent;
use HTTP::Headers;  # ::Fast
use HTTP::Request;
use Mo 0.30 qw(builder chain is required);
use Net::OAuth;
use URI;
use WebService::XING::Function;
use WebService::XING::Response;

our $VERSION = '0.030';

our @CARP_NOT = qw(Mo::builder Mo::chain Mo::is Mo::required);
@Carp::Internal{qw(Mo::builder Mo::chain Mo::is Mo::required)} = (1, 1, 1, 1);

# Prototypes

sub nonce;
sub _missing_parameter ($$$);
sub _invalid_parameter ($$$);

my @FUNCTAB = (
    # User Profiles
    get_user_details =>
        [GET => '/v1/users/:id', '@fields'],
    find_by_emails =>
        [GET => '/v1/users/find_by_emails', '@!emails', '@user_fields'],

    # Jobs
    get_job_posting =>
        [GET => '/v1/jobs/:id', '@user_fields'],
    find_jobs =>
        [GET => '/v1/jobs/find', '!query', 'limit', 'location', 'offset', '@user_fields'],
    list_job_recommendations =>
        [GET => '/v1/users/:user_id/jobs/recommendations', 'limit', 'offset', '@user_fields'],

    # Messages
    list_conversations =>
        [GET => '/v1/users/:user_id/conversations', 'limit', 'offset', '@user_fields', 'with_latest_messages'],
    create_conversation =>
        [POST => '/v1/users/:user_id/conversations', '!content', '@!recipient_ids', '!subject'],
    get_conversation =>
        [GET => '/v1/users/:user_id/conversations/:id', '@user_fields', 'with_latest_messages'],
    mark_conversation_read =>
        [PUT => '/v1/users/:user_id/conversations/:id/read'],
    list_conversation_messages =>
        [GET => '/v1/users/:user_id/conversations/:conversation_id/messages', 'limit', 'offset', '@user_fields'],
    get_conversation_message =>
        [GET => '/v1/users/:user_id/conversations/:conversation_id/messages/:id', '@user_fields'],
    mark_conversation_message_read =>
        [PUT => '/v1/users/:user_id/conversations/:conversation_id/messages/:id/read'],
    mark_conversation_message_unread =>
        [DELETE => '/v1/users/:user_id/conversations/:conversation_id/messages/:id/read'],
    create_conversation_message =>
        [POST => '/v1/users/:user_id/conversations/:conversation_id/messages', '!content'],
    delete_conversation =>
        [DELETE => '/v1/users/:user_id/conversations/:id'],

    # Status Messages
    create_status_message =>
        [POST => '/v1/users/:id/status_message', '!message'],

    # Profile Messages
    get_profile_message =>
        [GET => '/v1/users/:user_id/profile_message'],
    update_profile_message =>
        [PUT => '/v1/users/:user_id/profile_message', '!message', '?public=1'],

    # Contacts
    list_contacts =>
        [GET => '/v1/users/:user_id/contacts', 'limit', 'offset', 'order_by', '@user_fields'],
    list_contact_tags =>
        [GET => '/v1/users/:user_id/contacts/:contact_id/tags'],
    list_shared_contacts =>
        [GET => '/v1/users/:user_id/contacts/shared', 'limit', 'offset', 'order_by', '@user_fields'],

    # Contact Requests
    list_incoming_contact_requests =>
        [GET => '/v1/users/:user_id/contact_requests', 'limit', 'offset', '@user_fields'],
    list_sent_contact_requests =>
        [GET => '/v1/users/:user_id/contact_requests/sent', 'limit', 'offset'],
    create_contact_request =>
        [POST => '/v1/users/:user_id/contact_requests', 'message'],
    accept_contact_request =>
        [PUT => '/v1/users/:user_id/contact_requests/:id/accept'],
    delete_contact_request =>
        [DELETE => '/v1/users/:user_id/contact_requests/:id'],

    # Contact Path
    get_contact_paths =>
        [GET => '/v1/users/:user_id/network/:other_user_id/paths', '?all_paths=0', '@user_fields'],

    # Bookmarks
    list_bookmarks =>
        [GET => '/v1/users/:user_id/bookmarks', 'limit', 'offset', '@user_fields'],
    create_bookmark =>
        [PUT => '/v1/users/:user_id/bookmarks/:id'],
    delete_bookmark =>
        [DELETE => '/v1/users/:user_id/bookmarks/:id'],

    # Network Feed
    get_network_feed =>
        [GET => '/v1/users/:user_id/network_feed', '?aggregate=1', 'since', 'until', '@user_fields'],
    get_user_feed =>
        [GET => '/v1/users/:id/feed', 'since', 'until', '@user_fields'],
    get_activity =>
        [GET => '/v1/activities/:id', '@user_fields'],
    share_activity =>
        [POST => '/v1/activities/:id/share', 'text'],
    delete_activity =>
        [DELETE => '/v1/activities/:id'],
    list_activity_comments =>
        [GET => '/v1/activities/:activity_id/comments', 'limit', 'offset', '@user_fields'],
    create_activity_comment =>
        [POST => '/v1/activities/:activity_id/comments', 'text'],
    delete_activity_comment =>
        [DELETE => '/v1/activities/:activity_id/comments/:id'],
    list_activity_likes =>
        [GET => '/v1/activities/:activity_id/likes', 'limit', 'offset', '@user_fields'],
    create_activity_like =>
        [PUT => '/v1/activities/:activity_id/like'],
    delete_activity_like =>
        [DELETE => '/v1/activities/:activity_id/like'],

    # Profile Visits
    list_profile_visits =>
        [GET => '/v1/users/:user_id/visits', 'limit', 'offset', 'since', '?strip_html=0'],
    create_profile_visit =>
        [POST => '/v1/users/:user_id/visits'],

    # Recommendations
    list_recommendations =>
        [GET => '/v1/users/:user_id/network/recommendations', 'limit', 'offset', 'similar_user_id', '@user_fields'],
    delete_recommendation =>
        [DELETE => '/v1/users/:user_id/network/recommendations/user/:id'],

    # Invitations
    create_invitations =>
        [POST => '/v1/users/invite', '@to_emails', 'message', '@user_fields'],

    # Geo Locations
    update_geo_location =>
        [PUT => '/v1/users/:user_id/geo_location', '!accuracy', '!latitude', '!longitude', 'ttl'],
    list_nearby_users  =>
        [GET => '/v1/users/:user_id/nearby_users', 'age', 'radius', '@user_fields'],
);


$Net::OAuth::PROTOCOL_VERSION = Net::OAuth::PROTOCOL_VERSION_1_0A;


### Attributes

has key => (is => 'ro', required => 1);

has secret => (is => 'ro', required => 1);

has access_token => (chain => 1);

has access_secret => (chain => 1);

has user_id => (chain => 1);

sub access_credentials {
    my $self = shift;

    return ($self->access_token, $self->access_secret, $self->user_id)
        unless @_;

    return $self->access_token($_[0])->access_secret($_[1])->user_id($_[2]);
}

has user_agent => (builder => '_build_user_agent', chain => 1);
sub _build_user_agent { __PACKAGE__ . '/' . $VERSION . ' (Perl)' }

has request_timeout => (builder => '_build_request_timeout', chain => 1);
sub _build_request_timeout { 30 }

has json => (builder => '_build_json', chain => 1);
sub _build_json { JSON->new->utf8->allow_nonref }

has warn => (builder => '_build_warn', chain => 1);
sub _build_warn { sub { Carp::carp @_ } }

has die => (builder => '_build_die', chain => 1);
sub _build_die { sub { Carp::croak @_ } }

has base_url => (builder => '_build_base', chain => 1);
sub _build_base { 'https://api.xing.com' }

has request_token_resource => (
    builder => '_build_request_token_resource',
    chain => 1,
);
sub _build_request_token_resource { '/v1/request_token' }

has authorize_resource => (
    builder => '_build_authorize_resource',
    chain => 1,
);
sub _build_authorize_resource { '/v1/authorize' }

has access_token_resource => (
    builder => '_build_access_token_resource',
    chain => 1,
);
sub _build_access_token_resource { '/v1/access_token' }

has _ua => (builder => '_build__ua');
sub _build__ua {
    my $self = shift;

    return LWP::UserAgent->new(
        agent => $self->user_agent,
        default_headers => $self->_headers,
        max_redirect => 2,
        timeout => $self->request_timeout,
    );
}

has _headers => (builder => '_build__headers');
sub _build__headers {
    HTTP::Headers->new(
        # Accept => 'application/json, text/javascript, */*; q=0.01',
        'Accept-Encoding' => 'gzip, deflate',
    )
}


### Functions

sub functions {
    state $x = 0;
    return state $functions = [ grep { $x ^= 1 } @FUNCTAB ];
}

sub function {
    state $functab = { @FUNCTAB };  # coerce array @FUNCTAB into a hash
    state $functions = {};          # store WebService::XING::Function objects
    my $name = shift;

    $name = shift if eval { $name->isa(__PACKAGE__) };  # called as a method

    my $f = $functions->{$name};

    return $f if $f;

    $f = $functab->{$name} or return undef;

    my ($method, $resource, @params) = @$f;

    return $functions->{$name} = WebService::XING::Function->new(
        name => $name,
        method => $method,
        resource => $resource,
        params_in => \@params,
    );
}

sub nonce { Digest::SHA::sha1_base64 time, $$, rand, @_ }


### Methods

sub login {
    my ($self, %args) = @_;
    my $res = $self->request(
        POST => $self->request_token_resource,
        callback => $args{callback} || 'oob',
    );

    $res->is_success or return $res;

    my $oauth_res = Net::OAuth->response('request token')
        ->from_post_body($res->content);

    my $url = URI->new($self->base_url . $self->authorize_resource);

    $url->query_form(oauth_token => $oauth_res->token);

    return WebService::XING::Response->new(
        code => $res->code,
        message => => $res->message,
        headers => $res->headers,
        content => {
            url => $url->as_string,
            token => $oauth_res->token,
            token_secret => $oauth_res->token_secret,
        }
    );
}

sub auth {
    my ($self, %args) = @_;
    my @args = map {
        $_ => $args{$_} || $self->die->(_missing_parameter($_, ref $self, 'auth'))
    } qw(token token_secret verifier);
    my $res = $self->request(POST => $self->access_token_resource, @args);

    $res->is_success or return $res;

    my $oauth_res = Net::OAuth->response('access token')
        ->from_post_body($res->content);
    my $extra_params = $oauth_res->extra_params;

    $self->access_credentials(
        $oauth_res->token, $oauth_res->token_secret, $extra_params->{user_id}
    );

    return WebService::XING::Response->new(
        code => $res->code,
        message => => $res->message,
        headers => $res->headers,
        content => {
            token => $oauth_res->token,
            token_secret => $oauth_res->token_secret,
            user_id => $extra_params->{user_id},
        }
    );
}

sub can {
    my ($self, $name) = @_;
    my $code; $code = $self->SUPER::can($name) and return $code;
    my $f = $self->function($name) or return undef;

    no strict 'refs';

    *$name = $code = $f->code;

    return $code;
}

sub AUTOLOAD {
    my $self = $_[0];   # do NOT shift!
    my ($package, $name) = our $AUTOLOAD =~ /^([\w\:]+)\:\:(\w+)$/;
    my $f = $self->function($name)
        or $self->die->(qq{Can't locate object method "$name" via package "$package"});

    no strict 'refs';

    *$AUTOLOAD = $f->code;

    return $f->code->(@_);
}

sub DESTROY { }

sub request {
    my ($self, $method, $resource, @args) = @_;
    my (@extra, $type);
    my $url = $self->base_url . $resource;
    my $reqbody = '';
    my $headers = HTTP::Headers->new;

    if ($resource eq $self->request_token_resource) {
        $type = 'request token';
        # tame the XING API server
        $headers->header(Accept => 'application/x-www-form-urlencoded');
        @extra = @args;
        @args = ();
    }
    elsif ($resource eq $self->access_token_resource) {
        $type = 'access token';
        # tame the XING API server
        $headers->header(Accept => 'application/x-www-form-urlencoded');
        @extra = @args;
        @args = ();
    }
    else {
        $type = 'protected resource';
        $headers->header(Accept => 'application/json');
        @extra = (
            token => $self->access_token,
            token_secret => $self->access_secret,
        );
    }

    if ($method ~~ ['POST', 'PUT']) {
        my $u = URI->new('http:');
        if (@args) {
            push @extra, extra_params => { @args };
            $u->query_form(@args);
            $reqbody = $u->query;
            $reqbody =~ s/(?<!%0D)%0A/%0D%0A/g;
        }
        $headers->header(
            'Content-Type' => 'application/x-www-form-urlencoded',
            'Content-Length' => length $reqbody
        );
    }
    elsif (@args) {
        my $u = URI->new($url);
        $u->query_form(@args);
        $url = $u->as_string;
    }

    my $oauth_req = Net::OAuth->request($type)->new(
        consumer_key => $self->key,
        consumer_secret => $self->secret,
        request_url => $url,
        request_method => $method,
        signature_method => 'HMAC-SHA1',
        timestamp => time,
        nonce => nonce(@extra, $url),
        @extra,
    );

    $oauth_req->sign;

    $headers->header(Authorization => $oauth_req->to_authorization_header);

    my $res = $self->_ua->request(HTTP::Request->new($method, $url, $headers, $reqbody));

    $headers = $res->headers;

    # The XING API has a nasty bug currently: Even though it always pretends
    # to reply with JSON in the body, it actually sends plain text messages
    # sometimes.

    my $resbody;

    if ($headers->content_type eq 'application/json') {
        $resbody = eval { $self->json->decode($res->decoded_content) };
    }

    return WebService::XING::Response->new(
        code => $res->code,
        message => $res->message,
        headers => $headers,
        content => $resbody // $res->decoded_content,
    );
}

### Deprecated (renamed) methods

sub get_contacts { shift->list_contacts(@_) }
sub get_shared_contacts { shift->list_shared_contacts(@_) }
sub get_incoming_contact_requests { shift->list_incoming_contact_requests(@_) }
sub get_sent_contact_requests { shift->list_sent_contact_requests(@_) }
sub get_bookmarks { shift->list_bookmarks(@_) }
sub get_activity_comments { shift->list_activity_comments(@_) }
sub get_activity_likes { shift->list_activity_likes(@_) }
sub get_profile_visits { shift->list_profile_visits(@_) }
sub get_recommendations { shift->list_recommendations(@_) }
sub block_recommendation { shift->delete_recommendation(@_) }
sub get_nearby_users { shift->list_nearby_users(@_) }

### Internal

# ($expanded_resource, @parameters) =
#   $self->_scour_args($function_object, \%args);
# Scour argument list, die on missing or unknown arguments.
sub _scour_args {
    my ($self, $f, $args) = @_;
    my $resource = $f->resource;
    my @r;

    for my $p (@{$f->params}) {
        my $key = $p->name;
        my $value = delete $args->{$key};

        if (defined $value) {
            if (ref $value eq 'ARRAY') {
                $self->die->(_invalid_parameter($key, ref $self, $f->name))
                    unless $p->is_list;
                $value = join(',', @$value);
                $self->die->(_missing_parameter($key, ref $self, $f->name))
                    if length $value == 0 and $p->is_required;
            }
            elsif ($p->is_boolean) {
                $value = $value && $value ne 'false' ? 'true' : 'false';
            }

            if ($p->is_placeholder) {
                $resource =~ s/:$key/$value/;
            }
            else {
                push @r, $key, $value;
            }
        }
        else {
            $self->die->(_missing_parameter($key, ref $self, $f->name))
                if $p->is_required;
        }
    }

    $self->die->(_invalid_parameter((keys %$args)[0], ref $self, $f->name))
        if %$args;

    return ($resource, @r);
}

sub _missing_parameter ($$$) {
    my ($p, $pack, $meth) = @_;

    sprintf 'Mandatory parameter "%s" is missing in method call "%s" in package "%s"',
            $p, $meth, $pack;
}

sub _invalid_parameter ($$$) {
    my ($p, $pack, $meth) = @_;

    sprintf 'Invalid parameter "%s" in method call "%s" in package "%s"',
            $p, $meth, $pack;
}

1;

__END__

=head1 NAME

WebService::XING - Perl Interface to the XING API

=head1 VERSION

Version 0.020

=head1 SYNOPSIS

  use WebService::XING;

  my $xing = WebService::XING->new(
    key => $CUSTOMER_KEY,
    secret => $CUSTOMER_SECRET,
    access_token => $access_token,
    access_secret => $access_secret,
    user_id => $user_id,
  );

  $res = $xing->get_user_details(id => 'me')
    or die $res;

  say "Hello, my name is ", $res->content->{users}->[0]->{display_name};

=head1 DESCRIPTION

C<WebService::XING> is a Perl client library for the XING API. It supports
the whole range of functions described under L<https://dev.xing.com/>.

=head2 Method Introspection

An application can query a list of all available API functions together
with their parameters. See the L</functions> and the L</function>
function, and the L</can> method for more information.

=head2 Alpha Software Warning

This software is still very young and should not be considered stable.
You are welcome to check it out, but be prepared: it might kill your
kittens!

Moreover at the time of writing, the XING API is in a closed beta test
phase, and still has a couple of bugs.

=head1 ATTRIBUTES

All attributes can be set in the L<constructor|/new>.

Attributes marked as "required and read-only" must be given in the
L<constructor|/new>.

All writeable attributes can be used as setters and getters of the
object instance.

All writeable attributes return the object in set mode to make them
chainable. This example does virtually the same as in the L</SYNOPSIS>
above:

  $res = WebService::XING->new(
    key => $CUSTOMER_KEY,
    secret => $CUSTOMER_SECRET
  )
    ->access_token($token)
    ->access_secret($secret)
    ->user_id($uid)
    ->get_user_details(id => 'me')
      or die $res;

  say "Hello, my name is ", $res->content->{users}->[0]->{display_name};

All attributes with a default value are "lazy": They get their value when
they are read the first time, unless they are already initialized. The
attribute default value is set by a builder method called
C<"_build_" . $attribute_name>.  This gives a sub class of
C<WebService::XING> the opportunity to override any default value by
providing a custom builder method.

=head2 key

The application key a.k.a. "consumer key". Required and read-only.

=head2 secret

The application secret a.k.a. "consumer secret". Required and read-only.

=head2 access_token

  $xing = $xing->access_token($access_token);
  $access_token = $xing->access_token;

Access token as returned at the end of the OAuth process.
Required for all methods except L</login> and L</auth>.

=head2 access_secret

  $xing = $xing->access_secret($access_secret);
  $access_secret = $xing->access_secret;

Access secret as returned at the end of the OAuth process.
Required for all methods except L</login> and L</auth>.

=head2 user_id

  $xing = $xing->user_id($user_id);
  $user_id = $xing->user_id;

The scrambled XING user id as returned (and set) by the L</auth> method.

=head2 access_credentials

  $xing = $xing->access_credentials(
    $access_token, $access_secret, $user_id
  );
  ($access_token, $access_secret, $user_id) =
    $xing->access_credentials;

Convenience attribute accessor, for getting and setting L</access_token>,
L</access_secret> and L</user_id> in one go.

Once authorization has completed, L</access_token>, L</access_secret> and
L</user_id> are the only variable attributes, that are needed to use all
API functions. An application must store these three values for later
authentication. A web application might put them in a long lasting
session.

=head2 user_agent

  $xing = $xing->user_agent('MyApp Agent/23');
  $user_agent = $xing->user_agent;

Set or get the user agent string for the request.

Default: C<WebService::XING/$VERSION (Perl)>

=head2 request_timeout

  $xing = $xing->request_timeout(10);
  $request_timeout = $xing->request_timeout;

Maximum time in seconds to wait for a response.

Default: C<30>

=head2 json

  $xing = $xing->json(My::JSON->new);
  $json = $xinf->json;

An object instance of a JSON class.

Default: C<< JSON->new->utf8->allow_nonref >>.
Uses L<JSON::XS> if available.

=head2 warn

  $xing = $xing->warn(sub { $log->write(@_) });
  $xing->warn->($warning);

A reference to a C<sub>, that handles C<warn>ings.

Default: C<sub { Carp::carp @_ }>
Used by the library to issue warnings.

=head2 die

  $xing = $xing->die(sub { MyException->throw(@_ });
  $xing->die->($famous_last_words);

A reference to a C<sub>, that handles C<die>s.
Used by the library for dying.

Default: C<sub { Carp::croak @_ }>

=head2 base_url

  $xing = $xing->base_url($test_url);
  $base_url = $xing->base_url;

Web address of the XING API server. Do not change unless you know what
you are doing.

Default: C<https://api.xing.com>

=head2 request_token_resource

  $xing = $xing->request_token_resource($request_token_resource);
  $request_token_resource = $xing->request_token_resource;

Resource where to receive a temporary OAuth request token.
Do not change without reason.

Default: F</v1/request_token>

=head2 authorize_resource

  $xing = $xing->authorize_resource($authorize_resource);
  $authorize_resource = $xing->authorize_resource;

Resource where the user has to be redirected in order to authorize
access for the consumer. Do not change without reason.

Default: F</v1/authorize>

=head2 access_token_resource

  $xing = $xing->access_token_resource($access_token_resource);
  $access_token_resource = $xing->access_token_resource;

Resource where to receive an OAuth access token. Do not change without
reason.

Default: F</v1/access_token>

=head1 FUNCTIONS

None of the functions is exported.

All functions can also be called as (either class or object) methods.

=head2 functions

  $functions = WebService::XING::functions;
  $functions = WebService::XING->functions;
  $functions = $xing->functions;

A function, that provides a reference to a list of the names of all
the API's functions. The order is the same as documented under
L<https://dev.xing.com/docs/resources>.

=head2 function

  $function = WebService::XING::function($name);
  $function = WebService::XING->function($name);
  $function = $xing->function($name);

Get a L<WebService::XING::Function> object for the given function C<$name>.
Returns C<undef> if no function with the given C<$name> is known.

=head2 nonce

  $nonce = WebService::XING::nonce;
  $nonce = WebService::XING::nonce($any, $kind, $of, @input);
  $nonce = $xing->nonce;

A function, that creates a random string. While intended primarily for
internal use, it is documented here, so you can use it if you like.
Accepts any number of arbitrary volatile arguments to increase entropy.

=head1 METHODS

All methods are called with named arguments - or in other words - with
a list of key-value-pairs.

All methods except L</new> and L</can> return a
L<WebService::XING::Response> object on success.

A method may L</die> if called inaccurately (e.g. with missing arguments).

When the method documentation mentions a C<$bool> argument, it means
boolean in the way Perl handles it: C<undef>, "" and C<0> being C<false>
and everything else C<true>.

=head2 new

  my $xing = WebService::XING->new(
    key => $CUSTOMER_KEY,
    secret => $CUSTOMER_SECRET,
    access_token => $access_token,
    access_secret => $access_secret,
  );

The object constructor requires L</key> and L</secret> to be set, and
for all methods besides L</login> and L</auth> also L</access_token> and
L</access_secret>. Any other L<attribute|/ATTRIBUTES> can be set here as
well.

=head2 can

  $code = $xing->can($name);

Overrides L<UNIVERSAL/can>. Usually API functions are dynamically built
at first time they are called. C<can> does the same, but rather than
executing the method, it just returns a reference to it.

=head2 login

  $res = $xing->login or die $res;
  my $c = $res->content;
  my ($auth_url, $token, $secret) = @c{qw(url token token_secret)};

or

  $res = $xing->login(callback => $callback_url) or die $res;
  ...

OAuth handshake step 1: Obtain a temporary request token.

If a callback url is given, the user will be re-directed back to that
location from the XING authorization page after successfull completion
of OAuth handshake step 2, otherwise (or if callback has the value
C<oob>) a PIN code (C<oauth_verifier>) is displayed to the user on the
XING authorization page, that must be entered in the consuming
application.

Always returns a L<WebServive::XING::Response> object.

L<WebService::XING::Response/content> contains a hash with the following
elements:

=over

=item C<url>:

The XING authorization URL. For the second step of the OAuth handshake
the user must be redirected to that location.

=item C<token>:

The temporary request token. Needed in L</auth>.

=item C<token_secret>:

The temporary request token secret. Needed in L</auth>.

=back

=head2 auth

  $xing->auth(
    token => $token,
    token_secret => $token_secret,
    verifier => $verifier,
  );

OAuth handshake step 3: Obtain an access token.
Requires the following three named parameters:

=over

=item C<token>:

The B<request token> as returned in the response of a successfull
L<login> call.

=item C<token_secret>:

The B<request token_secret> as returned in the response of a successfull
L<login> call.

=item C<verifier>:

The OAuth verifier, that is provided to the callback as the
C<oauth_verifier> parameter - or that is displayed to the user for an
out-of-band authorization.

=back

The L<content property|WebService::XING::Response/content> of the
L<response|WebService::XING::Response> contains a hash with the 
following elements:

=over

=item C<token>:

The access token.

=item C<token_secret>:

The access token secret.

=item C<user_id>:

The scrambled XING user id.

=back

These three values are also stored in the object instance, so it is
not strictly required to store them. It might be useful for a web
application though, to keep only these access credentials in a
session, rather than the whole L<WebService::XING> object.

=head2 get_user_details

  $res = $xing->get_user_details(id => $id, fields => \@fields);

See L<https://dev.xing.com/docs/get/users/:id>

=head2 find_user_by_email_address

  $res = $xing->find_by_emails(
    emails => \@emails, user_fields => \@user_fields
  );

See L<https://dev.xing.com/docs/get/users/find_by_emails>

=head2 get_job_posting

  $res = $xing->get_job_posting(
    id => $id, user_fields => \@user_fields
  );

See L<https://dev.xing.com/docs/get/jobs/:id>

=head2 find_jobs

  $res = $xing->find_jobs(
    query => $query, limit => $limit, location => $location,
    offset => $offset, user_fields => \@user_fields
  );

See L<https://dev.xing.com/docs/get/jobs/find>

=head2 list_job_recommendations

  $res = $xing->list_job_recommendations(
    user_id => $user_id, limit => $limit, offset => $offset,
    user_fields => \@user_fields
  );

See L<https://dev.xing.com/docs/get/users/:user_id/jobs/recommendations>

=head2 list_conversations

  $res = $xing->list_conversations(
    user_id => $user_id, limit => $limit, offset => $offset,
    user_fields => \@user_fields, with_latest_messages => $number
  );

See L<https://dev.xing.com/docs/get/users/:user_id/conversations>

=head2 create_conversation

  $res = $xing->create_conversation(
    user_id => $user_id, content => $content, subject => $subject,
    recipient_ids => \@recipient_ids
  );

See L<https://dev.xing.com/docs/post/users/:user_id/conversations>

=head2 get_conversation

  $res = $xing->get_conversation(
    user_id => $user_id, id => $conversation_id,
    user_fields => \@user_fields, with_latest_messages => $number
  );

See L<https://dev.xing.com/docs/get/users/:user_id/conversations/:id>

=head2 mark_conversation_read

  $res = $xing->mark_conversation_read(
    user_id => $user_id, id => $id
  );

See L<https://dev.xing.com/docs/put/users/:user_id/conversations/:id/read>

=head2 list_conversation_messages

  $res = $xing->list_conversation_messages(
    user_id => $user_id, conversation_id => $conversation_id,
    limit => $limit, offset => $offset, user_fields => \@user_fields
  );

See L<https://dev.xing.com/docs/get/users/:user_id/conversations/:conversation_id/messages>

=head2 get_conversation_message

  $res = $xing->get_conversation_message(
    user_id => $user_id, conversation_id => $conversation_id,
    id => $message_id, user_fields => \@user_fields
  );

See L<https://dev.xing.com/docs/get/users/:user_id/conversations/:conversation_id/messages/:id>

=head2 mark_conversation_message_read

  $res = $xing->mark_conversation_message_read(
    user_id => $user_id, conversation_id => $conversation_id,
    id => $message_id
  );

See L<https://dev.xing.com/docs/put/users/:user_id/conversations/:conversation_id/messages/:id/read>

=head2 mark_conversation_message_unread

  $res = $xing->mark_conversation_message_unread(
    user_id => $user_id, conversation_id => $conversation_id,
    id => $message_id
  );

See L<https://dev.xing.com/docs/delete/users/:user_id/conversations/:conversation_id/messages/:id/read>

=head2 create_conversation_message

  $res = $xing->create_conversation_message(
    user_id => $user_id, conversation_id => $conversation_id,
    content => $content
  );

See L<https://dev.xing.com/docs/delete/users/:user_id/conversations/:conversation_id/messages/:id/read>

=head2 delete_conversation

  $res = $xing->delete_conversation(
    user_id => $user_id, id => $conversation_id
  );

See L<https://dev.xing.com/docs/delete/users/:user_id/conversations/:id>

=head2 create_status_message

  $res = $xing->create_status_message(id => $id, message => $message);

See L<https://dev.xing.com/docs/post/users/:id/status_message>

=head2 get_profile_message

  $res = $xing->get_profile_message(user_id => $user_id);

See L<https://dev.xing.com/docs/get/users/:user_id/profile_message>

=head2 update_profile_message

  $res = $xing->update_profile_message(
    user_id => $user_id, message => $message, public => $bool
  );

See L<https://dev.xing.com/docs/put/users/:user_id/profile_message>

=head2 list_contacts

  $res = $xing->list_contacts(
    user_id => $user_id,
    limit => $limit, offset => $offset, order_by => $order_by,
    user_fields => \@user_fields
  );

See L<https://dev.xing.com/docs/get/users/:user_id/contacts>

=head2 list_contact_tags

  $res = $xing->list_contacts(
    user_id => $user_id, contact_id => $contact_id
  );

See L<https://dev.xing.com/docs/get/users/:user_id/contacts/:contact_id/tags>

=head2 list_shared_contacts

  $res = $xing->list_shared_contacts(
    user_id => $user_id,
    limit => $limit, offset => $offset, order_by => $order_by,
    user_fields => \@user_fields
  );

See L<https://dev.xing.com/docs/get/users/:user_id/contacts/shared>

=head2 list_incoming_contact_requests

  $res = $xing->list_incoming_contact_requests(
    user_id => $user_id,
    limit => $limit, offset => $offset,
    user_fields => \@user_fields
  );

See L<https://dev.xing.com/docs/get/users/:user_id/contact_requests>

=head2 list_sent_contact_requests

  $res = $xing->list_sent_contact_requests(
    user_id => $user_id, limit => $limit, offset => $offset
  );

See L<https://dev.xing.com/docs/get/users/:user_id/contact_requests/sent>

=head2 create_contact_request

  $res = $xing->create_contact_request(
    user_id => $user_id, message => $message
  );

See L<https://dev.xing.com/docs/post/users/:user_id/contact_requests>

=head2 accept_contact_request

  $res = $xing->accept_contact_request(
    id => $sender_id, user_id => $recipient_id
  );

See L<https://dev.xing.com/docs/put/users/:user_id/contact_requests/:id/accept>

=head2 delete_contact_request

  $res = $xing->delete_contact_request(
    id => $sender_id, user_id => $recipient_id
  );

See L<https://dev.xing.com/docs/delete/users/:user_id/contact_requests/:id>

=head2 get_contact_paths

  $res = $xing->get_contact_paths(
    user_id => $user_id,
    other_user_id => $other_user_id,
    all_paths => $bool,
    user_fields => \@user_fields
  );

See L<https://dev.xing.com/docs/get/users/:user_id/network/:other_user_id/paths>

=head2 list_bookmarks

  $res = $xing->list_bookmarks(
    user_id => $user_id,
    limit => $limit, offset => $offset,
    user_fields => \@user_fields
  );

See L<https://dev.xing.com/docs/get/users/:user_id/bookmarks>

=head2 create_bookmark

  $res = $xing->create_bookmark(id => $id, user_id => $user_id);

See L<https://dev.xing.com/docs/put/users/:user_id/bookmarks/:id>

=head2 delete_bookmark

  $res = $xing->delete_bookmark(id => $id, user_id => $user_id);

See L<https://dev.xing.com/docs/delete/users/:user_id/bookmarks/:id>

=head2 get_network_feed

  $res = $xing->get_network_feed(
    user_id => $user_id,
    aggregate => $bool,
    since => $date,
    user_fields => \@user_fields
  );

  $res = $xing->get_network_feed(
    user_id => $user_id,
    aggregate => $bool,
    until => $date,
    user_fields => \@user_fields
  );

See L<https://dev.xing.com/docs/get/users/:user_id/network_feed>

=head2 get_user_feed

  $res = $xing->get_user_feed(
    user_id => $user_id,
    since => $date,
    user_fields => \@user_fields
  );

  $res = $xing->get_user_feed(
    user_id => $user_id,
    until => $date,
    user_fields => \@user_fields
  );

See L<https://dev.xing.com/docs/get/users/:id/feed>

=head2 get_activity

  $res = $xing->get_activity(id => $id, user_fields => \@user_fields);

See L<https://dev.xing.com/docs/get/activities/:id>

=head2 share_activity

  $res = $xing->share_activity(id => $id, text => $text);

See L<https://dev.xing.com/docs/post/activities/:id/share>

=head2 delete_activity

  $res = $xing->delete_activity(id => $id);

See L<https://dev.xing.com/docs/delete/activities/:id>

=head2 list_activity_comments

  $res = $xing->list_activity_comments(
    activity_id => $activity_id,
    limit => $limit, offset => $offset,
    user_fields => \@user_fields
  );

See L<https://dev.xing.com/docs/get/activities/:activity_id/comments>

=head2 create_activity_comment

  $res = $xing->create_activity_comment(
    activity_id => $activity_id,
    text => $text
  );

See L<https://dev.xing.com/docs/post/activities/:activity_id/comments>

=head2 delete_activity_comment

  $res = $xing->delete_activity_comment(
    activity_id => $activity_id,
    id => $id
  );

See L<https://dev.xing.com/docs/delete/activities/:activity_id/comments/:id>

=head2 list_activity_likes

  $res = $xing->list_activity_likes(
    activity_id => $activity_id,
    limit => $limit, offset => $offset,
    user_fields => \@user_fields
  );

See L<https://dev.xing.com/docs/get/activities/:activity_id/likes>

=head2 create_activity_like

  $res = $xing->create_activity_like(activity_id => $activity_id);

See L<https://dev.xing.com/docs/put/activities/:activity_id/like>

=head2 delete_activity_like

  $res = $xing->delete_activity_like(activity_id => $activity_id);

See L<https://dev.xing.com/docs/delete/activities/:activity_id/like>

=head2 list_profile_visits

  $res = $xing->list_profile_visits(user_id => $user_id);

See L<https://dev.xing.com/docs/get/users/:user_id/visits>

=head2 create_profile_visit

  $res = $xing->create_profile_visit(
    user_id => $user_id,
    limit => $limit, offset => $offset,
    since => $date,
    strip_html => $bool
  );

See L<https://dev.xing.com/docs/post/users/:user_id/visits>

=head2 list_recommendations

  $res = $xing->list_recommendations(
    user_id => $user_id,
    limit => $limit, offset => $offset,
    similar_user_id => $similar_user_id,
    user_fields => \@user_fields
  );

See L<https://dev.xing.com/docs/get/users/:user_id/network/recommendations>

=head2 delete_recommendation

  $res = $xing->list_recommendation(
    user_id => $user_id, id => $delete_user_id,
  );

See L<https://dev.xing.com/docs/delete/users/:user_id/network/recommendations/user/:id>

=head2 create_invitations

  $res = $xing->create_invitations(
    to_emails => \@to_emails,
    message => $message,
    user_fields => \@user_fields
  );

See L<https://dev.xing.com/docs/post/users/invite>

=head2 update_geo_location

  $res = $xing->update_geo_location(
    user_id => $user_id,
    accuracy => $accuracy,
    latitude => $latitude, longitude => $longitude,
    ttl => $ttl
  );

See L<https://dev.xing.com/docs/put/users/:user_id/geo_location>

=head2 list_nearby_users

  $res = $xing->list_nearby_users(
    user_id => $user_id,
    age => $age,
    radius => $radius,
    user_fields => \@user_fields
  );

See L<https://dev.xing.com/docs/get/users/:user_id/nearby_users>

=head2 request

  $res = $xing->request($method => $resource, @args);

Call any API function:

=over

=item C<$method>:

C<GET>, C<POST>, C<PUT> or C<DELETE>.

=item C<$resource>:

An api resource, e.g. F</v1/users/me>.

=item C<@args>:

A list of named arguments, e.g. C<< id => 'me', text => 'Blah!' >>.

=back

=head1 DEPRECATED METHODS

For the sake of consistency a couple of API methods have been renamed.
These methods are still available under their old names. The old names
are not detectable by means of L</Method Introspection>, and will be
removed in a future release.

=head2 get_contacts

Renamed to L</list_contacts>.

=head2 get_shared_contacts

Renamed to L</list_shared_contacts>.

=head2 get_incoming_contact_requests

Renamed to L</list_incoming_contact_requests>.

=head2 get_sent_contact_requests

Renamed to L</list_sent_contact_requests>.

=head2 get_bookmarks

Renamed to L</list_bookmarks>.

=head2 get_activity_comments

Renamed to L</list_activity_comments>.

=head2 get_activity_likes

Renamed to L</list_activity_likes>.

=head2 get_profile_visits

Renamed to L</list_profile_visits>.

=head2 get_recommendations

Renamed to L</list_recommendations>.

=head2 block_recommendation

Renamed to L</delete_recommendation>.

=head2 get_nearby_users

Renamed to L</list_nearby_users>.

=head1 SEE ALSO

L<WebService::XING::Response>, L<WebService::XING::Function>,
L<https://dev.xing.com/>

=head1 AUTHOR

Bernhard Graf, C<< <graf (a) cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Bernhard Graf.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

