package Web::Request;
BEGIN {
  $Web::Request::AUTHORITY = 'cpan:DOY';
}
{
  $Web::Request::VERSION = '0.11';
}
use Moose;
# ABSTRACT: common request class for web frameworks

use Encode ();
use HTTP::Body ();
use HTTP::Headers ();
use HTTP::Message::PSGI ();
use Module::Runtime ();
use Stream::Buffered ();
use URI ();
use URI::Escape ();


has env => (
    traits   => ['Hash'],
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
    handles  => {
        address         => [ get => 'REMOTE_ADDR' ],
        remote_host     => [ get => 'REMOTE_HOST' ],
        protocol        => [ get => 'SERVER_PROTOCOL' ],
        method          => [ get => 'REQUEST_METHOD' ],
        port            => [ get => 'SERVER_PORT' ],
        request_uri     => [ get => 'REQUEST_URI' ],
        path_info       => [ get => 'PATH_INFO' ],
        script_name     => [ get => 'SCRIPT_NAME' ],
        scheme          => [ get => 'psgi.url_scheme' ],
        _input          => [ get => 'psgi.input' ],
        content_length  => [ get => 'CONTENT_LENGTH' ],
        content_type    => [ get => 'CONTENT_TYPE' ],
        session         => [ get => 'psgix.session' ],
        session_options => [ get => 'psgix.session.options' ],
        logger          => [ get => 'psgix.logger' ],
    },
);

has _base_uri => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;

        my $env = $self->env;

        my $scheme = $self->scheme || "http";
        my $server = $self->host;
        my $path = $self->script_name || '/';

        return "${scheme}://${server}${path}";
    },
);

has base_uri => (
    is      => 'ro',
    isa     => 'URI',
    lazy    => 1,
    default => sub { URI->new(shift->_base_uri)->canonical },
);

has uri => (
    is      => 'ro',
    isa     => 'URI',
    lazy    => 1,
    default => sub {
        my $self = shift;

        my $base = $self->_base_uri;

        # We have to escape back PATH_INFO in case they include stuff
        # like ? or # so that the URI parser won't be tricked. However
        # we should preserve '/' since encoding them into %2f doesn't
        # make sense. This means when a request like /foo%2fbar comes
        # in, we recognize it as /foo/bar which is not ideal, but that's
        # how the PSGI PATH_INFO spec goes and we can't do anything
        # about it. See PSGI::FAQ for details.
        my $path_escape_class = q{^/;:@&=A-Za-z0-9\$_.+!*'(),-};

        my $path = URI::Escape::uri_escape(
            $self->path_info || '',
            $path_escape_class
        );
        $path .= '?' . $self->env->{QUERY_STRING}
            if defined $self->env->{QUERY_STRING}
            && $self->env->{QUERY_STRING} ne '';

        $base =~ s!/$!! if $path =~ m!^/!;

        return URI->new($base . $path)->canonical;
    },
);

has headers => (
    is      => 'ro',
    isa     => 'HTTP::Headers',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $env = $self->env;
        return HTTP::Headers->new(
            map {
                (my $field = $_) =~ s/^HTTPS?_//;
                $field => $env->{$_}
            } grep {
                /^(?:HTTP|CONTENT)/i
            } keys %$env
        );
    },
    handles => ['header', 'content_encoding', 'referer', 'user_agent'],
);

has cookies => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub {
        my $self = shift;

        my $cookie_str = $self->env->{HTTP_COOKIE};
        return {} unless defined $cookie_str;

        my %results;
        for my $pair (grep { /=/ } split /[;,] ?/, $cookie_str) {
            $pair =~ s/^\s+|\s+$//g;
            my ($key, $value) = map {
                URI::Escape::uri_unescape($_)
            } split(/=/, $pair, 2);
            # XXX $self->decode too?
            $results{$key} = $value unless exists $results{$key};
        }

        return \%results;
    },
);

has _http_body => (
    is  => 'rw',
    isa => 'HTTP::Body',
);

has _parsed_body => (
    traits  => ['Hash'],
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub {
        my $self = shift;

        my $ct = $self->content_type;
        my $cl = $self->content_length;
        if (!$ct && !$cl) {
            if (!$self->env->{'psgix.input.buffered'}) {
                $self->env->{'psgix.input.buffered'} = 1;
                $self->env->{'psgi.input'} = Stream::Buffered->new(0)->rewind;
            }
            return {
                body    => {},
                uploads => {},
            };
        }

        my $body = HTTP::Body->new($ct, $cl);
        # automatically clean up, but wait until the request object is gone
        $body->cleanup(1);
        $self->_http_body($body);

        my $input = $self->_input;

        my $buffer;
        if ($self->env->{'psgix.input.buffered'}) {
            $input->seek(0, 0);
        }
        else {
            $buffer = Stream::Buffered->new($cl);
        }

        my $spin = 0;
        while ($cl) {
            $input->read(my $chunk, $cl < 8192 ? $cl : 8192);
            my $read = length($chunk);
            $cl -= $read;
            $body->add($chunk);
            $buffer->print($chunk) if $buffer;

            if ($read == 0 && $spin++ > 2000) {
                confess "Bad Content-Length ($cl bytes remaining)";
            }
        }

        if ($buffer) {
            $self->env->{'psgix.input.buffered'} = 1;
            $self->env->{'psgi.input'} = $buffer->rewind;
        }
        else {
            $input->seek(0, 0);
        }

        return {
            body    => $body->param,
            uploads => $body->upload,
        }
    },
    handles => {
        _body    => [ get => 'body' ],
        _uploads => [ get => 'uploads' ],
    },
);

has query_parameters => (
    is      => 'ro',
    isa     => 'HashRef[Str]',
    lazy    => 1,
    clearer => '_clear_query_parameters',
    default => sub {
        my $self = shift;

        my %params = (
            $self->uri->query_form,
            (map { $_ => '' } $self->uri->query_keywords),
        );
        return {
            map { $self->_decode($_) } map { $_ => $params{$_} } keys %params
        };
    },
);

has all_query_parameters => (
    is      => 'ro',
    isa     => 'HashRef[ArrayRef[Str]]',
    lazy    => 1,
    clearer => '_clear_all_query_parameters',
    default => sub {
        my $self = shift;

        my @params = $self->uri->query_form;
        my $ret = {};

        while (my ($k, $v) = splice @params, 0, 2) {
            $k = $self->_decode($k);
            push @{ $ret->{$k} ||= [] }, $self->_decode($v);
        }

        return $ret;
    },
);

has body_parameters => (
    is      => 'ro',
    isa     => 'HashRef[Str]',
    lazy    => 1,
    clearer => '_clear_body_parameters',
    default => sub {
        my $self = shift;

        my $body = $self->_body;

        my $ret = {};
        for my $key (keys %$body) {
            my $val = $body->{$key};
            $key = $self->_decode($key);
            $ret->{$key} = $self->_decode(ref($val) ? $val->[-1] : $val);
        }

        return $ret;
    },
);

has all_body_parameters => (
    is      => 'ro',
    isa     => 'HashRef[ArrayRef[Str]]',
    lazy    => 1,
    clearer => '_clear_all_body_parameters',
    default => sub {
        my $self = shift;

        my $body = $self->_body;

        my $ret = {};
        for my $key (keys %$body) {
            my $val = $body->{$key};
            $key = $self->_decode($key);
            $ret->{$key} = ref($val)
                ? [ map { $self->_decode($_) } @$val ]
                : [ $self->_decode($val) ];
        }

        return $ret;
    },
);

has uploads => (
    is      => 'ro',
    isa     => 'HashRef[Web::Request::Upload]',
    lazy    => 1,
    default => sub {
        my $self = shift;

        my $uploads = $self->_uploads;

        my $ret = {};
        for my $key (keys %$uploads) {
            my $val = $uploads->{$key};
            $ret->{$key} = ref($val) eq 'ARRAY'
                ? $self->_new_upload($val->[-1])
                : $self->_new_upload($val);
        }

        return $ret;
    },
);

has all_uploads => (
    is      => 'ro',
    isa     => 'HashRef[ArrayRef[Web::Request::Upload]]',
    lazy    => 1,
    default => sub {
        my $self = shift;

        my $uploads = $self->_uploads;

        my $ret = {};
        for my $key (keys %$uploads) {
            my $val = $uploads->{$key};
            $ret->{$key} = ref($val) eq 'ARRAY'
                ? [ map { $self->_new_upload($_) } @$val ]
                : [ $self->_new_upload($val) ];
        }

        return $ret;
    },
);

has _encoding_obj => (
    is        => 'rw',
    isa       => 'Object', # no idea what this should be
    clearer   => '_clear_encoding_obj',
    predicate => 'has_encoding',
);

sub BUILD {
    my $self = shift;
    my ($params) = @_;
    if (defined $params->{encoding}) {
        $self->encoding($params->{encoding});
    }
    else {
        $self->encoding($self->default_encoding);
    }
}

sub new_from_env {
    my $class = shift;
    my ($env) = @_;

    return $class->new(env => $env);
}

sub new_from_request {
    my $class = shift;
    my ($req) = @_;

    return $class->new_from_env(HTTP::Message::PSGI::req_to_psgi($req));
}

sub new_response {
    my $self = shift;

    Module::Runtime::use_package_optimistically($self->response_class);
    my $res = $self->response_class->new(@_);
    $res->_encoding_obj($self->_encoding_obj)
        if $self->has_encoding;
    return $res;
}

sub _new_upload {
    my $self = shift;

    Module::Runtime::use_package_optimistically($self->upload_class);
    $self->upload_class->new(@_);
}

sub host {
    my $self = shift;

    my $env = $self->env;
    my $host = $env->{HTTP_HOST};
    $host = ($env->{SERVER_NAME} || '') . ':'
          . ($env->{SERVER_PORT} || 80)
        unless defined $host;

    return $host;
}

sub path {
    my $self = shift;

    my $path = $self->path_info;
    return $path if length($path);
    return '/';
}

sub parameters {
    my $self = shift;

    return {
        %{ $self->query_parameters },
        %{ $self->body_parameters },
    };
}

sub all_parameters {
    my $self = shift;

    my $ret = { %{ $self->all_query_parameters } };
    my $body_parameters = $self->all_body_parameters;

    for my $key (keys %$body_parameters) {
        push @{ $ret->{$key} ||= [] }, @{ $body_parameters->{$key} };
    }

    return $ret;
}

sub param {
    my $self = shift;
    my ($key) = @_;

    $self->parameters->{$key};
}

sub content {
    my $self = shift;

    unless ($self->env->{'psgix.input.buffered'}) {
        # the builder for this attribute also sets up psgi.input
        $self->_parsed_body;
    }

    my $fh = $self->_input         or return '';
    my $cl = $self->content_length or return '';

    $fh->seek(0, 0); # just in case middleware/apps read it without seeking back

    $fh->read(my $content, $cl, 0);
    $fh->seek(0, 0);

    return $self->_decode($content);
}

sub _decode {
    my $self = shift;
    my ($content) = @_;
    return $content unless $self->has_encoding;
    return $self->_encoding_obj->decode($content);
}

sub encoding {
    my $self = shift;

    if (@_ > 0) {
        my ($encoding) = @_;
        $self->_clear_encoded_data;
        if (defined($encoding)) {
            $self->_encoding_obj(Encode::find_encoding($encoding));
        }
        else {
            $self->_clear_encoding_obj;
        }
    }

    return $self->_encoding_obj ? $self->_encoding_obj->name : undef;
}

sub _clear_encoded_data {
    my $self = shift;
    $self->_clear_encoding_obj;
    $self->_clear_query_parameters;
    $self->_clear_all_query_parameters;
    $self->_clear_body_parameters;
    $self->_clear_all_body_parameters;
}

sub response_class   { 'Web::Response'        }
sub upload_class     { 'Web::Request::Upload' }
sub default_encoding { 'iso8859-1'            }

__PACKAGE__->meta->make_immutable;
no Moose;



1;

__END__

=pod

=head1 NAME

Web::Request - common request class for web frameworks

=head1 VERSION

version 0.11

=head1 SYNOPSIS

  use Web::Request;

  my $app = sub {
      my ($env) = @_;
      my $req = Web::Request->new_from_env($env);
      # ...
  };

=head1 DESCRIPTION

Web::Request is a request class for L<PSGI> applications. It provides access to
all of the information received in a request, generated from the PSGI
environment. The available methods are listed below.

Note that Web::Request objects are intended to be (almost) entirely read-only -
although some methods (C<headers>, C<uri>, etc) may return mutable objects,
changing those objects will have no effect on the actual environment, or the
return values of any of the other methods. Doing this is entirely unsupported.
In addition, the return values of most methods that aren't direct accesses to
C<env> are cached, so if you do modify the actual environment hashref, you
should create a new Web::Request object for it.

The one exception is the C<encoding> attribute, which is allowed to be
modified. Changing the encoding will change the return value of any subsequent
calls to C<content>, C<query_parameters>, C<all_query_parameters>,
C<body_parameters>, and C<all_body_parameters>.

Web::Request is based heavily on L<Plack::Request>, but with the intention of
growing to become more generally useful to end users (rather than just
framework and middleware developers). In the future, it is expected to grow in
functionality to support a lot more convenient functionality, while
Plack::Request has a more minimalist goal.

=head1 METHODS

=head2 address

Returns the IP address of the remote client.

=head2 remote_host

Returns the hostname of the remote client. May be empty.

=head2 protocol

Returns the protocol (HTTP/1.0, HTTP/1.1, etc.) used in the current request.

=head2 method

Returns the HTTP method (GET, POST, etc.) used in the current request.

=head2 port

Returns the local port that this request was made on.

=head2 host

Returns the contents of the HTTP C<Host> header. If it doesn't exist, falls
back to recreating the host from the C<SERVER_NAME> and C<SERVER_PORT>
variables.

=head2 path

Returns the request path for the current request. Unlike C<path_info>, this
will never be empty, it will always start with C</>. This is most likely what
you want to use to dispatch on.

=head2 path_info

Returns the request path for the current request. This can be C<''> if
C<script_name> ends in a C</>. This can be appended to C<script_name> to get
the full (absolute) path that was requested from the server.

=head2 script_name

Returns the absolute path where your application is mounted. It may be C<''>
(in which case, C<path_info> will start with a C</>).

=head2 request_uri

Returns the raw, undecoded URI path (the literal path provided in the request,
so C</foo%20bar> in C<GET /foo%20bar HTTP/1.1>). You most likely want to use
C<path>, C<path_info>, or C<script_name> instead.

=head2 scheme

Returns C<http> or C<https> depending on the scheme used in the request.

=head2 session

Returns the session object, if a middleware is used which provides one. See
L<PSGI::Extensions>.

=head2 session_options

Returns the session options hashref, if a middleware is used which provides
one. See L<PSGI::Extensions>.

=head2 logger

Returns the logger object, if a middleware is used which provides one. See
L<PSGI::Extensions>.

=head2 uri

Returns the full URI used in the current request, as a L<URI> object.

=head2 base_uri

Returns the base URI for the current request (only the components up through
C<script_name>) as a L<URI> object.

=head2 headers

Returns a L<HTTP::Headers> object containing the headers for the current
request.

=head2 content_length

The length of the content, in bytes. Corresponds to the C<Content-Length>
header.

=head2 content_type

The MIME type of the content. Corresponds to the C<Content-Type> header.

=head2 content_encoding

The encoding of the content. Corresponds to the C<Content-Encoding> header.

=head2 referer

Returns the value of the C<Referer> header.

=head2 user_agent

Returns the value of the C<User-Agent> header.

=head2 header($name)

Shortcut for C<< $req->headers->header($name) >>.

=head2 cookies

Returns a hashref of cookies received in this request. The values are URI
decoded.

=head2 content

Returns the content received in this request, decoded based on the value of
C<encoding>.

=head2 param($param)

Returns the parameter value for the parameter named C<$param>. Returns the last
parameter given if more than one are passed.

=head2 parameters

Returns a hashref of parameter names to values. If a name is given more than
once, the last value is provided.

=head2 all_parameters

Returns a hashref where the keys are parameter names and the values are
arrayrefs holding every value given for that parameter name. All parameters are
stored in an arrayref, even if there is only a single value.

=head2 query_parameters

Like C<parameters>, but only return the parameters that were given in the query
string.

=head2 all_query_parameters

Like C<all_parameters>, but only return the parameters that were given in the
query string.

=head2 body_parameters

Like C<parameters>, but only return the parameters that were given in the
request body.

=head2 all_body_parameters

Like C<all_parameters>, but only return the parameters that were given in the
request body.

=head2 uploads

Returns a hashref of upload objects (instances of C<upload_class>). If more
than one upload is provided with a given name, returns the last one given.

=head2 all_uploads

Returns a hashref where the keys are upload names and the values are arrayrefs
holding an upload object (instance of C<upload_class>) for every upload given
for that name. All uploads are stored in an arrayref, even if there is only a
single value.

=head2 new_response(@params)

Returns a new response object, passing C<@params> to its constructor.

=head2 env

Returns the L<PSGI> environment that was provided in the constructor (or
generated from the L<HTTP::Request>, if C<new_from_request> was used).

=head2 encoding($enc)

Returns the encoding that was provided in the constructor. You can also pass an
encoding name to this method to set the encoding that will be used to decode
the content and encode the response. For instance, you can set the encoding to
UTF-8 in order to read the body content and parameters, and then set the
encoding to C<undef> at the end of the handler in order to indicate that the
response should not be encoded (for instance, if it is a binary file).

=head2 response_class

Returns the name of the class to use when creating a new response object via
C<new_response>. Defaults to L<Web::Response>. This can be overridden in
a subclass.

=head2 upload_class

Returns the name of the class to use when creating a new upload object for
C<uploads> or C<all_uploads>. Defaults to L<Web::Request::Upload>. This can be
overridden in a subclass.

=head2 default_encoding

Returns the name of the default encoding to use for decoding. Defaults to
iso8859-1. This can be overridden in a subclass.

=head1 CONSTRUCTORS

=head2 new_from_env($env)

Create a new Web::Request object from a L<PSGI> environment hashref.

=head2 new_from_request($request)

Create a new Web::Request object from a L<HTTP::Request> object.

=head2 new(%params)

Create a new Web::Request object with named parameters. Valid parameters are:

=over 4

=item env

A L<PSGI> environment hashref. Required.

=item encoding

The encoding to use for decoding all input in the request and encoding all
output in the response. Defaults to the value of C<default_encoding>. If
C<undef> is passed, no encoding or decoding will be done.

=back

=head1 BUGS

No known bugs.

Please report any bugs through RT: email
C<bug-web-request at rt.cpan.org>, or browse to
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Web-Request>.

=head1 SEE ALSO

L<Plack::Request> - Much of this module's API and implementation were taken
from Plack::Request.

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc Web::Request

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/release/Web-Request>

=item * Github

L<https://github.com/doy/web-request>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Web-Request>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Web-Request>

=back

=for Pod::Coverage BUILD

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jesse Luehrs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
