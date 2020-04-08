package WebService::Client;
use Moo::Role;

our $VERSION = '1.0000'; # VERSION

use Carp qw(croak);
use HTTP::Request;
use HTTP::Request::Common qw(DELETE GET POST PUT);
use JSON::MaybeXS qw();
use LWP::UserAgent;
use WebService::Client::Response;

has base_url => (
    is      => 'rw',
    default => sub { '' },
);

has ua => (
    is      => 'ro',
    lazy    => 1,
    default => sub { LWP::UserAgent->new(timeout => shift->timeout) },
);

has timeout => (
    is      => 'ro',
    default => sub { 10 },
);

has retries => (
    is      => 'ro',
    default => sub { 0 },
    isa     => sub {
        my $r = shift;
        die 'retries must be a nonnegative integer'
            unless defined $r and $r =~ /^\d+$/;
    },
);

has logger => ( is => 'ro' );

has log_method => (
    is      => 'ro',
    default => sub { 'DEBUG' },
);

has content_type => (
    is      => 'rw',
    default => sub { 'application/json' },
);

has deserializer => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $json = $self->json;
        sub {
            my ($res, %args) = @_;
            return $json->decode($res->content);
        }
    },
);

has serializer => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $json = $self->json;
        sub {
            my ($data, %args) = @_;
            # TODO: remove the next line after clients are updated to inject
            # custom serializers that will handle this logic
            return $data unless _content_type($args{headers}) =~ /json/;
            return $json->encode($data);
        }
    }
);

has json => (
    is      => 'ro',
    lazy    => 1,
    default => sub { JSON::MaybeXS->new() },
);

has mode => (
    is      => 'ro',
    default => sub { '' },
);

sub get {
    my ($self, $path, $params, %args) = @_;
    $params ||= {};
    my $headers = $self->_headers(\%args);
    my $url = $self->_url($path);
    my $q = '';
    if (%$params) {
        my @items;
        while (my ($key, $value) = each %$params) {
            if ('ARRAY' eq ref $value) {
                push @items, map "$key\[]=$_", @$value;
            }
            else {
                push @items, "$key=$value";
            }
        }
        if (@items) {
            $q = '?' . join '&', @items;
        }
    }
    my $req = GET "$url$q", %$headers;
    return $self->req($req, %args);
}

sub post {
    my ($self, $path, $data, %args) = @_;
    my $headers = $self->_headers(\%args);
    my $url = $self->_url($path);
    my $req = POST $url, %$headers, $self->_content($data, %args);
    return $self->req($req, %args);
}

sub put {
    my ($self, $path, $data, %args) = @_;
    my $headers = $self->_headers(\%args);
    my $url = $self->_url($path);
    my $req = PUT $url, %$headers, $self->_content($data, %args);
    return $self->req($req, %args);
}

sub patch {
    my ($self, $path, $data, %args) = @_;
    my $headers = $self->_headers(\%args);
    my $url = $self->_url($path);
    my %content = $self->_content($data, %args);
    my $req = HTTP::Request->new(
        'PATCH', $url, [%$headers], $content{content}
    );
    return $self->req($req, %args);
}

sub delete {
    my ($self, $path, %args) = @_;
    my $headers = $self->_headers(\%args);
    my $url = $self->_url($path);
    my $req = DELETE $url, %$headers;
    return $self->req($req, %args);
}

sub req {
    my ($self, $req, %args) = @_;
    $self->_log_request($req);
    my $res = $self->ua->request($req);
    $self->_log_response($res);

    my $retries = $self->retries;
    while ($res->code =~ /^5/ and $retries--) {
        sleep 1;
        $res = $self->ua->request($req);
        $self->_log_response($res);
    }

    $self->prepare_response($res);

    if ($self->mode) {
        return WebService::Client::Response->new(
            res  => $res,
            json => $self->json,
        );
    }

    return if $req->method eq 'GET' and $res->code =~ /404|410/;
    die $res unless $res->is_success;
    return 1 unless $res->content;
    my $des = $self->deserializer;
    $des = $args{deserializer} if exists $args{deserializer};
    if ($des) {
        die 'deserializer must be a coderef or undef'
            unless 'CODE' eq ref $des;
        return $des->($res, %args);
    }
    else {
        return $res->content;
    }
}

sub log {
    my ($self, $msg) = @_;
    return unless $self->logger;
    my $log_method = $self->log_method;
    $self->logger->$log_method($msg);
}

sub prepare_response {
    my ($self, $res) = @_;
    Moo::Role->apply_roles_to_object($res, 'HTTP::Response::Stringable');
    return;
}

sub _url {
    my ($self, $path) = @_;
    croak 'The path is missing' unless defined $path;
    return $path =~ /^http/ ? $path : $self->base_url . $path;
}

sub _headers {
    my ($self, $args) = @_;
    my $headers = $args->{headers} ||= {};
    croak 'The headers param must be a hashref' unless 'HASH' eq ref $headers;
    $headers->{content_type} = $self->content_type
        unless _content_type($headers);
    return $headers;
}

sub _log_request {
    my ($self, $req) = @_;
    $self->log(ref($self) . " REQUEST:\n" . $req->as_string);
}

sub _log_response {
    my ($self, $res) = @_;
    $self->log(ref($self) . " RESPONSE:\n" . $res->as_string);
}

sub _content_type {
    my ($headers) = @_;
    return $headers->{'Content-Type'}
        || $headers->{'content-type'}
        || $headers->{content_type};
}

sub _content {
    my ($self, $data, %args) = @_;
    my @content;
    if (defined $data) {
        my $ser = $self->serializer;
        $ser = $args{serializer} if exists $args{serializer};
        if ($ser) {
            die 'serializer must be a coderef or undef'
                unless 'CODE' eq ref $ser;
            $data = $ser->($data, %args);
        }
        @content = ( content => $data );
    }
    return @content;
}

# ABSTRACT: A base role for quickly and easily creating web service clients


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Client - A base role for quickly and easily creating web service clients

=head1 VERSION

version 1.0000

=head1 SYNOPSIS

    {
        package WebService::Foo;
        use Moo;
        with 'WebService::Client';

        has auth_token  => ( is => 'ro', required => 1 );

        method BUILD() {
            $self->base_url('https://foo.com/v1');

            $self->ua->default_header('X-Auth-Token' => $self->auth_token);
            # or if the web service uses http basic/digest authentication:
            # $self->ua->credentials( ... );
            # or
            # $self->ua->default_headers->authorization_basic( ... );
        }

        sub get_widgets() {
            my ($self) = @_;
            return $self->get("/widgets");
        }

        sub get_widget($id) {
            my ($self, $id) = @_;
            return $self->get("/widgets/$id");
        }

        sub create_widget($widget_data) {
            my ($self, $widget_data) = @_;
            return $self->post("/widgets", $widget_data);
        }
    }

    my $client = WebService::Foo->new(
        auth_token => 'abc',
        logger     => Log::Tiny->new('/tmp/foo.log'), # optional
        log_method => 'info', # optional, defaults to 'DEBUG'
        timeout    => 10, # optional, defaults to 10
        retries    => 0,  # optional, defaults to 0
    );
    my $widget = $client->create_widget({ color => 'blue' });
    print $client->get_widget($widget->{id})->{color};

Minimal example which retrieves the current Bitcoin price:

    package CoinDeskClient;
    use Moo;
    with 'WebService::Client';

    my $client = CoinDeskClient->new(base_url => 'https://api.coindesk.com/v1');
    print $client->get('/bpi/currentprice.json')->{bpi}{USD}{rate_float};

=head1 DESCRIPTION

This module is a base role for quickly and easily creating web service clients.
Every time I created a web service client, I noticed that I kept rewriting the
same boilerplate code independent of the web service.
This module does the boring boilerplate for you so you can just focus on
the fun part - writing the web service specific code.

=head1 METHODS

These are the methods this role composes into your class.
The HTTP methods (get, post, put, and delete) will return the deserialized
response data, if the response body contained any data.
This will usually be a hashref.
If the web service responds with a failure, then the corresponding HTTP
response object is thrown as an exception.
This exception is a L<HTTP::Response> object that has the
L<HTTP::Response::Stringable> role so it can be easily logged.
GET requests that respond with a status code of C<404> or C<410> will not
throw an exception.
Instead, they will simply return C<undef>.

The http methods C<get/post/put/delete> can all take the following optional
named arguments:

=over

=item headers

A hashref of custom headers to send for this request.
In the future, this may also accept an arrayref.
The header values can be any format that L<HTTP::Headers> recognizes,
so you can pass C<content_type> instead of C<Content-Type>.

=item serializer

A coderef that does custom serialization for this request.
Set this to C<undef> if you don't want any serialization to happen for this
request.

=item deserializer

A coderef that does custom deserialization for this request.
Set this to C<undef> if you want the raw http response body to be returned.

=back

Example:

    $client->post(
        /widgets,
        { color => 'blue' },
        headers      => { x_custom_header => 'blah' },
        serializer   => sub { ... },
        deserialized => sub { ... },
    }

=head2 get

    $client->get('/foo');
    $client->get('/foo', { query => 'params' });
    $client->get('/foo', { query => [qw(array params)] });

Makes an HTTP GET request.

=head2 post

    $client->post('/foo', { some => 'data' });
    $client->post('/foo', { some => 'data' }, headers => { foo => 'bar' });

Makes an HTTP POST request.

=head2 put

    $client->put('/foo', { some => 'data' });

Makes an HTTP PUT request.

=head2 patch

    $client->patch('/foo', { some => 'data' });

Makes an HTTP PATCH request.

=head2 delete

    $client->delete('/foo');

Makes an HTTP DELETE request.

=head2 req

    my $req = HTTP::Request->new(...);
    $client->req($req);

This is called internally by the above HTTP methods.
You will usually not need to call this explicitly.
It is exposed as part of the public interface in case you may want to add
a method modifier to it.
Here is a contrived example:

    around req => sub {
        my ($orig, $self, $req) = @_;
        $req->authorization_basic($self->login, $self->password);
        return $self->$orig($req, @rest);
    };

=head2 log

Logs a message using the provided logger.

=head1 ATTRIBUTES

=head2 base_url

This is the only attribute that is required.
This is the base url that all request will be made against.

=head2 ua

Optional. A proper default LWP::UserAgent will be created for you.

=head2 json

Optional. A proper default JSON object will be created via L<JSON::MaybeXS>

You can also pass in your own custom JSON object to have more control over
the JSON settings:

    my $client = WebService::Foo->new(
        json => JSON::MaybeXS->new(utf8 => 1, pretty => 1)
    );

=head2 timeout

Optional.
Default is 10.

=head2 retries

Optional.
Default is 0.

=head2 logger

Optional.

=head2 content_type

Optional.
Default is C<'application/json'>.

=head2 serializer

Optional.
A coderef that serializes the request content.
Set this to C<undef> if you don't want any serialization to happen.

=head2 deserializer

Optional.
A coderef that deserializes the response body.
Set this to C<undef> if you want the raw http response body to be returned.

=head1 EXAMPLES

Here are some examples of web service clients built with this role.
You can view their source to help you get started.

=over

=item *

L<Business::BalancedPayments>

=item *

L<WebService::HipChat>

=item *

L<WebService::Lob>

=item *

L<WebService::SmartyStreets>

=item *

L<WebService::Stripe>

=back

=head1 SEE ALSO

=over

=item *

L<Net::HTTP::API>

=item *

L<Role::REST::Client>

=back

=head1 CONTRIBUTORS

=over

=item *

Dean Hamstead <L<https://github.com/djzort>>

=item *

Todd Wade <L<https://github.com/trwww>>

=back

=head1 AUTHOR

Naveed Massjouni <naveed@vt.edu>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Naveed Massjouni.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
