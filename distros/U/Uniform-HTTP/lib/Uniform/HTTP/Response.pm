package Uniform::HTTP::Response;

use strict;
use warnings;
use Carp qw(croak);
use parent 'Uniform::HTTP::Message';

our $VERSION = '0.02';

sub new {
    my ($class, @args) = @_;
    my $args = Uniform::HTTP::Message::_named_args('new', @args);

    for my $name (keys %$args) {
        croak "unknown constructor option '$name'"
            unless $name eq 'status'
                || $name eq 'reason'
                || $name eq 'version'
                || $name eq 'headers'
                || $name eq 'body';
    }

    croak 'status is required' unless exists $args->{status};

    my @common;
    for my $name (qw(version headers body)) {
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

    $self->_assert_mutable;
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

    $self->_assert_mutable;
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
        status  => 201,
        reason  => 'Created',
        version => '1.1',
        headers => [ [ 'Content-Type', 'application/json' ] ],
        body    => '{}',
    );

=head1 DESCRIPTION

Uniform::HTTP::Response adds status and optional reason-phrase semantics to
L<Uniform::HTTP::Message>. It does not send a response or represent output
progress.

=head1 CONSTRUCTOR

=head2 new

Requires a named C<status> argument. It accepts optional C<reason> and the
common C<version>, C<headers>, and C<body> arguments. No reason phrase or HTTP
version is synthesized.

=head1 METHODS

=head2 status

Returns an integer HTTP status from 100 through 599. Passing a valid status
sets it and returns the response.

=head2 reason

Returns the reason phrase or C<undef> when none was supplied. Passing a byte
string sets it; passing C<undef> clears it. Uniform does not synthesize standard
phrases such as C<OK>.

=head1 INHERITED METHODS

See L<Uniform::HTTP::Message> for headers, body state, version, capability
reporting, and mutation.

=head1 AUTHOR

Joshua S. Day E<lt>HAX@cpan.orgE<gt>

=head1 LICENSE

This software is available under the MIT License.

=cut
