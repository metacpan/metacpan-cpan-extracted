package Web::Response;
use Moose;
# ABSTRACT: common response class for web frameworks

use HTTP::Headers ();
use Plack::Util ();
use URI::Escape ();

use Web::Request::Types ();

=head1 SYNOPSIS

  use Web::Request;

  my $app = sub {
      my ($env) = @_;
      my $req = Web::Request->new_from_env($env);
      # ...
      return $req->new_response(status => 404)->finalize;
  };


=head1 DESCRIPTION

Web::Response is a response class for L<PSGI> applications. Generally, you will
want to create instances of this class via C<new_response> on the request
object, since that allows a framework which subclasses L<Web::Request> to also
return an appropriate subclass of Web::Response.

All attributes on Web::Response objects are writable, and the final state of
them will be used to generate a real L<PSGI> response when C<finalize> is
called.

=cut

has status => (
    is      => 'rw',
    isa     => 'Web::Request::Types::HTTPStatus',
    lazy    => 1,
    default => sub { confess "Status was not supplied" },
);

has headers => (
    is      => 'rw',
    isa     => 'Web::Request::Types::HTTP::Headers',
    lazy    => 1,
    coerce  => 1,
    default => sub { HTTP::Headers->new },
    handles => {
        header           => 'header',
        content_length   => 'content_length',
        content_type     => 'content_type',
        content_encoding => 'content_encoding',
        location         => [ header => 'Location' ],
    },
);

has content => (
    is      => 'rw',
    isa     => 'Web::Request::Types::PSGIBody',
    lazy    => 1,
    coerce  => 1,
    default => sub { [] },
);

has streaming_response => (
    is        => 'rw',
    isa       => 'CodeRef',
    predicate => 'has_streaming_response',
);

has cookies => (
    traits  => ['Hash'],
    is      => 'rw',
    isa     => 'HashRef[Str|HashRef[Str]]',
    lazy    => 1,
    default => sub { +{} },
    handles => {
        has_cookies => 'count',
    },
);

has _encoding_obj => (
    is        => 'rw',
    isa       => 'Object',
    predicate => 'has_encoding',
    handles   => {
        encoding => 'name',
    },
);

sub BUILDARGS {
    my $class = shift;

    if (@_ == 1 && ref($_[0]) eq 'ARRAY') {
        return {
            status => $_[0][0],
            (@{ $_[0] } > 1
                ? (headers => $_[0][1])
                : ()),
            (@{ $_[0] } > 2
                ? (content => $_[0][2])
                : ()),
        };
    }
    elsif (@_ == 1 && ref($_[0]) eq 'CODE') {
        return {
            streaming_response => $_[0],
        };
    }
    else {
        return $class->SUPER::BUILDARGS(@_);
    }
}

sub redirect {
    my $self = shift;
    my ($url, $status) = @_;

    $self->status($status || 302);
    $self->location($url);
}

sub finalize {
    my $self = shift;

    return $self->_finalize_streaming
        if $self->has_streaming_response;

    my $res = [
        $self->status,
        [
            map {
                my $k = $_;
                map {
                    my $v = $_;
                    # replace LWS with a single SP
                    $v =~ s/\015\012[\040|\011]+/chr(32)/ge;
                    # remove CR and LF since the char is invalid here
                    $v =~ s/\015|\012//g;
                    ( $k => $v )
                } $self->header($k);
            } $self->headers->header_field_names
        ],
        $self->content
    ];

    $self->_finalize_cookies($res);

    return $res unless $self->has_encoding;

    return Plack::Util::response_cb($res, sub {
        return sub {
            my $chunk = shift;
            return unless defined $chunk;
            return $self->_encode($chunk);
        };
    });
}

sub to_app {
    my $self = shift;
    return sub { $self->finalize };
}

sub _finalize_streaming {
    my $self = shift;

    my $streaming = $self->streaming_response;

    return $streaming
        unless $self->has_encoding || $self->has_cookies;

    return Plack::Util::response_cb($streaming, sub {
        my $res = shift;
        $self->_finalize_cookies($res);
        return unless $self->has_encoding;
        return sub {
            my $chunk = shift;
            return unless defined $chunk;
            return $self->_encode($chunk);
        };
    });
}

sub _encode {
    my $self = shift;
    my ($content) = @_;
    return $content unless $self->has_encoding;
    return $self->_encoding_obj->encode($content);
}

sub _finalize_cookies {
    my $self = shift;
    my ($res) = @_;

    my $cookies = $self->cookies;
    for my $name (keys %$cookies) {
        push @{ $res->[1] }, (
            'Set-Cookie' => $self->_bake_cookie($name, $cookies->{$name}),
        );
    }

    $self->cookies({});
}

sub _bake_cookie {
    my $self = shift;
    my ($name, $val) = @_;

    return '' unless defined $val;
    $val = { value => $val }
        unless ref($val) eq 'HASH';

    my @cookie = (
        URI::Escape::uri_escape($name)
      . '='
      . URI::Escape::uri_escape($val->{value})
    );

    push @cookie, 'domain='  . $val->{domain}
        if defined($val->{domain});
    push @cookie, 'path='    . $val->{path}
        if defined($val->{path});
    push @cookie, 'expires=' . $self->_date($val->{expires})
        if defined($val->{expires});
    push @cookie, 'max-age=' . $val->{'max-age'}
        if defined($val->{'max-age'});
    push @cookie, 'secure'
        if $val->{secure};
    push @cookie, 'HttpOnly'
        if $val->{httponly};

    return join '; ', @cookie;
}

# XXX DateTime?
my @MON  = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
my @WDAY = qw( Sun Mon Tue Wed Thu Fri Sat );

sub _date {
    my $self = shift;
    my ($expires) = @_;

    return $expires unless $expires =~ /^\d+$/;

    my ($sec, $min, $hour, $mday, $mon, $year, $wday) = gmtime($expires);
    $year += 1900;

    return sprintf("%s, %02d-%s-%04d %02d:%02d:%02d GMT",
                   $WDAY[$wday], $mday, $MON[$mon], $year, $hour, $min, $sec);
}

__PACKAGE__->meta->make_immutable;
no Moose;

=head1 CONSTRUCTOR

=head2 new(%params)

Returns a new Web::Response object. Valid parameters are:

=over 4

=item status

The HTTP status code for the response.

=item headers

The headers to return with the response. Can be provided as an arrayref, a
hashref, or an L<HTTP::Headers> object. Defaults to an L<HTTP::Headers> object
with no contents.

=item content

The content of the request. Can be provided as a string, an object which
overloads C<"">, an arrayref containing a list of either of those, a
filehandle, or an object that implements the C<getline> and C<close> methods.
Defaults to C<[]>.

=item streaming_response

Instead of C<status>/C<headers>/C<content>, you can provide a coderef which
implements the streaming response API described in the L<PSGI> specification.

=item cookies

A hashref of cookies to return with the response. The values in the hashref can
either be the string values of the cookies, or a hashref whose keys can be any
of C<value>, C<domain>, C<path>, C<expires>, C<max-age>, C<secure>,
C<httponly>. In addition to the date format that C<expires> normally uses,
C<expires> can also be provided as a UNIX timestamp (an epoch time, as returned
from C<time>). Defaults to C<{}>.

=back

In addition, a single parameter which is a valid PSGI response (a three element
arrayref or a coderef) will also be accepted, and will populate the attributes
as appropriate. If an arrayref is passed, the first element will be stored as
the C<status> attribute, the second element if it exists will be interpreted as
in the PSGI specification to create an L<HTTP::Headers> object and stored in
the C<headers> attribute, and the third element if it exists will be stored as
the C<content> attribute. If a coderef is passed, it will be stored in the
C<streaming_response> attribute.

=cut

=method status($status)

Sets (and returns) the status attribute, as described above.

=method headers($headers)

Sets (and returns) the headers attribute, as described above.

=method header($name, $val)

Shortcut for C<< $ret->headers->header($name, $val) >>.

=method content_length($length)

Shortcut for C<< $ret->headers->content_length($length) >>.

=method content_type($type)

Shortcut for C<< $ret->headers->content_type($type) >>.

=method content_encoding($encoding)

Shortcut for C<< $ret->headers->content_encoding($encoding) >>.

=method location($location)

Shortcut for C<< $ret->headers->header('Location', $location) >>.

=method content($content)

Sets (and returns) the C<content> attribute, as described above.

=method streaming_response

Sets and returns the streaming response coderef, as described above.

=method has_streaming_response

Returns whether or not a streaming response was provided.

=method cookies($cookies)

Sets (and returns) the C<cookies> attribute, as described above.

=method has_cookies

Returns whether or not any cookies have been defined.

=method redirect($location, $status)

Sets the C<Location> header to $location, and sets the status code to $status
(defaulting to 302 if not given).

=method finalize

Returns a valid L<PSGI> response, based on the values given. This can be either
an arrayref or a coderef, depending on if an immediate or streaming response
was provided. If both were provided, the streaming response will be preferred.

=method to_app

Returns a PSGI application which just returns the response in this object
directly.

=cut

1;
