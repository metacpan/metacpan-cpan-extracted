package Uniform::HTTP::Response;

use strict;
use warnings;
use Carp qw(croak);
use parent 'Uniform::HTTP::Message';

our $VERSION = '0.06';

sub new {
    my ($class, @args) = @_;
    my $args = Uniform::HTTP::Message::_named_args('new', @args);

    for my $name (keys %$args) {
        croak "unknown constructor option '$name'"
            unless $name eq 'status'
                || $name eq 'reason'
                || $name eq 'version'
                || $name eq 'headers'
                || $name eq 'trailers'
                || $name eq 'body';
    }

    croak 'status is required' unless exists $args->{status};

    my @common;
    for my $name (qw(version headers trailers body)) {
        push @common, $name => $args->{$name} if exists $args->{$name};
    }

    my $self = $class->SUPER::new(@common);
    $self->status($args->{status});
    $self->reason($args->{reason}) if exists $args->{reason};
    return $self;
}

sub status {
    my ($self, @args) = @_;
    return $self->{status} unless @args;
    croak 'status() accepts at most one value' unless @args == 1;

    $self->_assert_initial_mutable;
    my $status = $args[0];
    croak 'status must be an integer from 100 through 599'
        unless defined($status)
            && !ref($status)
            && $status =~ /\A[0-9]+\z/
            && $status >= 100
            && $status <= 599;
    $self->{status} = 0 + $status;
    return $self;
}

sub reason {
    my ($self, @args) = @_;
    return $self->{reason} unless @args;
    croak 'reason() accepts at most one value' unless @args == 1;

    $self->_assert_initial_mutable;
    if (!defined $args[0]) {
        $self->{reason} = undef;
        return $self;
    }

    my $reason = Uniform::HTTP::Message::_byte_string('reason', $args[0]);
    croak 'reason contains a prohibited control byte'
        if $reason =~ /[\x00-\x08\x0a-\x1f\x7f]/;
    $self->{reason} = $reason;
    return $self;
}

1;

__END__

=head1 NAME

Uniform::HTTP::Response - Framework-neutral HTTP response

=head1 SYNOPSIS

    use Uniform::HTTP::Response;

    my $response = Uniform::HTTP::Response->new(
        status  => 200,
        headers => [
            [ 'Content-Type', 'text/plain' ],
        ],
        body => "hello\n",
    );

=head1 DESCRIPTION

Uniform::HTTP::Response represents HTTP response data without sending a
response or owning a connection, transaction, framework, or event loop.

A response always has a status. It may also carry a reason phrase, version,
headers, trailers, and a buffered body.

=head1 CONSTRUCTOR

=head2 new

    my $response = Uniform::HTTP::Response->new(
        status => 200,
        body   => 'ok',
    );

C<status> is required.

Optional arguments are:

=over 4

=item * C<reason>

=item * C<version>

=item * C<headers>

=item * C<trailers>

=item * C<body>

=back

=head1 METHODS

=head2 status

    my $status = $response->status;

Returns the HTTP status code.

Set it with:

    $response->status(404);

Valid status values are integers from 100 through 599.

=head2 reason

    my $reason = $response->reason;

Returns the reason phrase, or C<undef> when none was supplied.

Set or clear it with:

    $response->reason('Not Found');
    $response->reason(undef);

Uniform does not invent standard reason phrases such as C<OK>.

=head1 INFORMATIONAL RESPONSES

A status from 100 through 199 uses a normal Response object:

    my $hints = Uniform::HTTP::Response->new(
        status => 103,
        headers => [ [ 'Link', '</style.css>; rel=preload' ] ],
    );

Each informational and final response is a separate object. A complete
informational message does not mean its exchange is finished. The HTTP
implementation owns ordering and rules such as whether 101 or a body is
allowed in the selected protocol and request context.

Status and reason setters are blocked by C<freeze_initial()> and C<freeze()>.
Received HTTP/2 and HTTP/3 responses normally have no reason phrase.
Application-created responses may leave C<version> unset for the sender to
choose independently.

=head1 INHERITED METHODS

Headers, trailers, bodies, versions, section mutability, and completeness
come from L<Uniform::HTTP::Message>.

=head1 SEE ALSO

L<Uniform::HTTP>, L<Uniform::HTTP::Message>,
L<Uniform::HTTP::Request>.

=head1 AUTHOR

Joshua S. Day E<lt>HAX@cpan.orgE<gt>

=head1 LICENSE

This software is available under the MIT License.

=cut
