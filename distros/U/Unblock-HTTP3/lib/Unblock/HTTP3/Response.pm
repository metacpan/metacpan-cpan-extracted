package Unblock::HTTP3::Response;

use strict;
use warnings;
use Carp qw(croak);

use Uniform::HTTP::Response 0.04 ();
use parent -norequire, 'Uniform::HTTP::Response';

use Unblock::HTTP3 ();

our $VERSION = '0.01';

sub new {
    my ($class, @args) = @_;

    my $self = $class->SUPER::new(@args);
    $self->{_http3_reset_code} = undef;
    $self->{_http3_stop_sending_code} = undef;

    return $self;
}

sub reset_code {
    my ($self, @args) = @_;
    croak 'reset_code() does not accept arguments' if @args;
    return $self->{_http3_reset_code};
}

sub stop_sending_code {
    my ($self, @args) = @_;
    croak 'stop_sending_code() does not accept arguments' if @args;
    return $self->{_http3_stop_sending_code};
}

sub is_aborted {
    my ($self, @args) = @_;
    croak 'is_aborted() does not accept arguments' if @args;

    return defined($self->{_http3_reset_code})
        || defined($self->{_http3_stop_sending_code})
        ? 1
        : 0;
}

sub _mark_reset {
    my ($self, $code) = @_;
    $self->{_http3_reset_code} = 0 + $code;
    $self->mark_incomplete;
    $self->freeze;
    return $self;
}

sub _mark_stop_sending {
    my ($self, $code) = @_;
    $self->{_http3_stop_sending_code} = 0 + $code;
    $self->mark_incomplete;
    $self->freeze;
    return $self;
}

1;

__END__

=head1 NAME

Unblock::HTTP3::Response - Uniform HTTP response with HTTP/3 diagnostics

=head1 SYNOPSIS

    my $response = Unblock::HTTP3::Response->new(
        status => 200,
        body   => "hello\n",
    );

=head1 DESCRIPTION

C<Unblock::HTTP3::Response> is a thin subclass of
L<Uniform::HTTP::Response>.

Uniform::HTTP owns status, reason, version, headers, trailers, buffered body
state, fidelity, mutability, and completeness.

Unblock::HTTP3 adds request-stream abort diagnostics.

=head1 CONSTRUCTOR

=head2 new

Accepts the normal L<Uniform::HTTP::Response> constructor arguments.

=head1 METHODS

=head2 reset_code

Returns the HTTP/3 reset code recorded for this Response, or undef.

=head2 stop_sending_code

Returns the HTTP/3 STOP_SENDING code recorded for this Response, or undef.

=head2 is_aborted

True when a reset or STOP_SENDING code has been recorded.

=head1 SEE ALSO

L<Uniform::HTTP::Response>, L<Unblock::HTTP3::Connection>,
L<Unblock::HTTP3::Transaction>

=head1 AUTHOR

Joshua S. Day

=head1 LICENSE

This software is available under the MIT License.

=cut
