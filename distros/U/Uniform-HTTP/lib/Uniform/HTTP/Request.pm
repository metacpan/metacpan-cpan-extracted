package Uniform::HTTP::Request;

use strict;
use warnings;
use Carp qw(croak);
use parent 'Uniform::HTTP::Message';

our $VERSION = '0.04';

sub new {
    my ($class, @args) = @_;
    my $args = Uniform::HTTP::Message::_named_args('new', @args);

    for my $name (keys %$args) {
        croak "unknown constructor option '$name'"
            unless $name eq 'method'
                || $name eq 'target'
                || $name eq 'scheme'
                || $name eq 'authority'
                || $name eq 'protocol'
                || $name eq 'version'
                || $name eq 'headers'
                || $name eq 'trailers'
                || $name eq 'body';
    }

    croak 'method is required' unless exists $args->{method};
    croak 'target is required' unless exists $args->{target};

    my @common;
    for my $name (qw(version headers trailers body)) {
        push @common, $name => $args->{$name} if exists $args->{$name};
    }

    my $self = $class->SUPER::new(@common);
    $self->method($args->{method});
    $self->target($args->{target});
    $self->scheme($args->{scheme}) if exists $args->{scheme};
    $self->authority($args->{authority}) if exists $args->{authority};
    $self->protocol($args->{protocol}) if exists $args->{protocol};
    return $self;
}

sub method {
    my ($self, @args) = @_;
    return $self->{method} unless @args;
    croak 'method() accepts at most one value' unless @args == 1;

    $self->_assert_initial_mutable;
    my $method = Uniform::HTTP::Message::_byte_string('method', $args[0]);
    croak 'method must be an HTTP token'
        unless $method =~ /\A[!\#\$%&'*+\-.\^_`|~0-9A-Za-z]+\z/;
    $self->{method} = $method;
    return $self;
}

sub target {
    my ($self, @args) = @_;
    return $self->{target} unless @args;
    croak 'target() accepts at most one value' unless @args == 1;

    $self->_assert_initial_mutable;
    my $target = Uniform::HTTP::Message::_byte_string('target', $args[0]);
    croak 'target must not be empty' unless length $target;
    croak 'target must not contain spaces or control bytes'
        if $target =~ /[\x00-\x20\x7f]/;
    $self->{target} = $target;
    return $self;
}

sub scheme {
    my ($self, @args) = @_;
    return $self->{scheme} unless @args;
    croak 'scheme() accepts at most one value' unless @args == 1;

    $self->_assert_initial_mutable;
    if (!defined $args[0]) {
        $self->{scheme} = undef;
        return $self;
    }

    my $scheme = Uniform::HTTP::Message::_byte_string('scheme', $args[0]);
    croak 'scheme must be a valid URI scheme'
        unless $scheme =~ /\A[A-Za-z][A-Za-z0-9+.-]*\z/;
    $self->{scheme} = $scheme;
    return $self;
}

sub authority {
    my ($self, @args) = @_;
    return $self->{authority} unless @args;
    croak 'authority() accepts at most one value' unless @args == 1;

    $self->_assert_initial_mutable;
    if (!defined $args[0]) {
        $self->{authority} = undef;
        return $self;
    }

    my $authority = Uniform::HTTP::Message::_byte_string(
        'authority', $args[0],
    );
    croak 'authority must not be empty' unless length $authority;
    croak 'authority contains a prohibited delimiter or control byte'
        if $authority =~ /[\x00-\x20\x7f\/?#]/;
    $self->{authority} = $authority;
    return $self;
}

sub protocol {
    my ($self, @args) = @_;
    return $self->{protocol} unless @args;
    croak 'protocol() accepts at most one value' unless @args == 1;

    $self->_assert_initial_mutable;
    if (!defined $args[0]) {
        $self->{protocol} = undef;
        return $self;
    }

    my $protocol = Uniform::HTTP::Message::_byte_string('protocol', $args[0]);
    croak 'protocol must be an HTTP token'
        unless $protocol =~ /\A[!\#\$%&'*+\-.\^_`|~0-9A-Za-z]+\z/;
    $self->{protocol} = $protocol;
    return $self;
}

sub target_is_exact {
    my ($self, @args) = @_;
    croak 'target_is_exact() does not accept arguments' if @args;
    return 1;
}

1;

__END__

=head1 NAME

Uniform::HTTP::Request - Framework-neutral HTTP request

=head1 SYNOPSIS

    use Uniform::HTTP::Request;

    my $request = Uniform::HTTP::Request->new(
        method    => 'GET',
        target    => '/items?id=42',
        scheme    => 'https',
        authority => 'example.com',
        headers   => [
            [ 'Accept', 'application/json' ],
        ],
    );

=head1 DESCRIPTION

Uniform::HTTP::Request represents HTTP request data without owning a
connection, transaction, event loop, or transport.

A request always has a method and request target. It may also carry scheme,
authority, protocol, version, headers, trailers, and a buffered body.

Creating or changing a request never sends anything.

=head1 CONSTRUCTOR

=head2 new

    my $request = Uniform::HTTP::Request->new(
        method => 'POST',
        target => '/items',
        body   => $bytes,
    );

C<method> and C<target> are required.

Optional arguments are:

=over 4

=item * C<scheme>

=item * C<authority>

=item * C<protocol>

=item * C<version>

=item * C<headers>

=item * C<trailers>

=item * C<body>

=back

=head1 METHODS

=head2 method

    my $method = $request->method;

Returns the HTTP method.

Set it with:

    $request->method('POST');

=head2 target

    my $target = $request->target;

Returns the HTTP request target as bytes.

Examples include:

    /
    /items?id=42
    *
    example.com:443

Set it with:

    $request->target('/other');

=head2 scheme

Returns the request scheme, such as C<http> or C<https>, or C<undef> when no
scheme is represented.

Uniform does not invent a scheme from the transport or target.

=head2 authority

Returns the request authority, such as:

    example.com
    example.com:8443

or C<undef> when none is represented.

Uniform does not invent an authority from C<Host> or the request target.

=head2 protocol

    my $protocol = $request->protocol;
    $request->protocol('websocket');
    $request->protocol(undef);

Returns the Extended CONNECT protocol-name token, or C<undef> when absent.
The exact token bytes and spelling are preserved. Tokens such as C<websocket>,
C<connect-udp>, and future names use the same API. It is not an HTTP version or
an Upgrade field list, and it is never inferred from Upgrade.

The token must use HTTP token syntax. Uniform does not interpret the token,
check a registry, change the method, or perform negotiation. All request
metadata setters are blocked by C<freeze_initial()> as well as C<freeze()>.

=head2 target_is_exact

Returns true for canonical Uniform requests because C<target()> contains the
exact value supplied by the caller.

Adapters return false when they had to reconstruct a target from separate
framework values.

=head1 HTTP/2 AND HTTP/3

HTTP/2 and HTTP/3 carry request routing information in pseudo-fields.

For normal requests, an adapter can expose exact C<:path> bytes through
C<target()>.

Ordinary CONNECT has no C<:path>. In that case the exact C<:authority> bytes
are exposed as the authority-form target:

    method    => 'CONNECT',
    target    => 'example.com:443',
    authority => 'example.com:443',

Extended CONNECT instead supplies protocol metadata and keeps the exact
C<:path> as the target:

    method    => 'CONNECT',
    protocol  => 'websocket',
    scheme    => 'https',
    authority => 'example.com',
    target    => '/chat',

The sender validates required field combinations and negotiation for its HTTP
version. Uniform checks individual value syntax, allowing metadata to be
assembled in any order. It does not certify a legal wire request.

Leaving C<version> unset is appropriate for an application-created request.
The sender may select a version without modifying the object.

=head1 INHERITED METHODS

Headers, trailers, bodies, versions, section mutability, and completeness
come from L<Uniform::HTTP::Message>.

=head1 SEE ALSO

L<Uniform::HTTP>, L<Uniform::HTTP::Message>,
L<Uniform::HTTP::Response>.

=head1 AUTHOR

Joshua S. Day E<lt>HAX@cpan.orgE<gt>

=head1 LICENSE

This software is available under the MIT License.

=cut
