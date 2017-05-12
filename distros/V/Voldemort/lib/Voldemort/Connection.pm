package Voldemort::Connection;

=pod

=head1 NAME

Voldemort::Connection

=cut

use Moose::Role;
use Voldemort::Message;

=head1 METHODS

=head2 connect

Instructs a Connection object to connect.

=cut

requires 'connect';

=head2 discconect

Instructs a Connection object to disconnect.

=cut

requires 'disconnect';

=head2 select

Returns an IO::Select object of the current connection.

=cut

has 'select' => (
    is  => 'rw',
    isa => 'IO::Select'
);

=head2 is_connected

Moose boolean property indicating if the current connection should be available.

=cut

has 'is_connected' => (
    isa     => 'Bool',
    is      => 'rw',
    default => 0,
);

=head2 socket

Moose IO::Socket property used for communication.  

=cut

has 'socket' => (
    is  => 'rw',
    isa => 'IO::Socket::INET'
);

=head2 to

Moose string property in the format of host:port where to connect to.  Required.

=cut

has 'to' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);


=head2 delete_handler, put_handler, get_handler

Moose Voldemort::Message property handling gets, puts and deletes.

=cut

has 'get_handler' => (
    'is'   => 'rw',
    'does' => 'Voldemort::Message'
);


has 'delete_handler' => (
    'is'   => 'rw',
    'does' => 'Voldemort::Message'
);
has 'put_handler' => (
    'is'   => 'rw',
    'does' => 'Voldemort::Message'
);

sub can_read {
    my $self = shift;
    return $self->select()->can_read(@_);
}

sub can_write {
    my $self = shift;
    return $self->select->can_write(@_);
}

sub flush {
    my $self = shift;
    $self->socket()->flush();
    return;
}

sub send {
    my $self = shift;
    return $self->socket()->send(shift) || carp($!);
}

sub recv {
    my $self = shift;

    my $buffer;
    $self->socket()->recv( $buffer, shift );
    return $buffer;
}

1;
