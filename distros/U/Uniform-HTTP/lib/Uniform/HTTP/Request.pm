package Uniform::HTTP::Request;

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
            unless $name eq 'method'
                || $name eq 'target'
                || $name eq 'version'
                || $name eq 'headers'
                || $name eq 'body';
    }

    croak 'method is required' unless exists $args->{method};
    croak 'target is required' unless exists $args->{target};

    my @common;
    for my $name (qw(version headers body)) {
        push @common, $name => $args->{$name} if exists $args->{$name};
    }

    my $self = $class->SUPER::new(@common);
    $self->method($args->{method});
    $self->target($args->{target});
    return $self;
}

sub method {
    my ($self, @args) = @_;
    return $self->{method} unless @args;
    croak 'method() accepts at most one value' unless @args == 1;

    $self->_assert_mutable;
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

    $self->_assert_mutable;
    my $target = Uniform::HTTP::Message::_byte_string('target', $args[0]);
    croak 'target must not be empty' unless length $target;
    croak 'target must not contain spaces or control bytes'
        if $target =~ /[\x00-\x20\x7f]/;
    $self->{target} = $target;
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
        method  => 'POST',
        target  => '/items?draft=1',
        version => '1.1',
        headers => [ [ 'Content-Type', 'application/json' ] ],
        body    => '{"name":"example"}',
    );

=head1 DESCRIPTION

Uniform::HTTP::Request adds method and request-target semantics to
L<Uniform::HTTP::Message>. It is a detached message object, not a transaction
or connection.

=head1 CONSTRUCTOR

=head2 new

Requires named C<method> and C<target> arguments. It also accepts the common
C<version>, C<headers>, and C<body> arguments.

=head1 METHODS

=head2 method

Returns the case-sensitive HTTP method token. Passing a token sets it and
returns the request.

=head2 target

Returns the HTTP request-target as bytes, not as a URI object. Passing a target
sets it and returns the request.

=head2 target_is_exact

Returns true for canonical requests because C<target()> is exactly the value
supplied by the caller. An adapter returns false when it had to reconstruct a
target from framework data.

=head1 INHERITED METHODS

See L<Uniform::HTTP::Message> for headers, body state, version, capability
reporting, and mutation.

=head1 AUTHOR

Joshua S. Day E<lt>HAX@cpan.orgE<gt>

=head1 LICENSE

This software is available under the MIT License.

=cut
