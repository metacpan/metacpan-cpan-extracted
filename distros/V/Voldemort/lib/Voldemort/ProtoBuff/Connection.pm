package Voldemort::ProtoBuff::Connection;

use Moose;
use Google::ProtocolBuffers;
use IO::Socket::INET;
use Carp;

use Voldemort::ProtoBuff::GetMessage;
use Voldemort::ProtoBuff::PutMessage;
use Voldemort::ProtoBuff::DeleteMessage;

with 'Voldemort::Connection';

has '+get_handler' => (
    'default' => sub { Voldemort::ProtoBuff::GetMessage->new() },
    'lazy'    => 1
);
has '+delete_handler' => (
    'default' => sub { Voldemort::ProtoBuff::DeleteMessage->new() },
    'lazy'    => 1
);
has '+put_handler' => (
    'default' => sub { Voldemort::ProtoBuff::PutMessage->new() },
    'lazy'    => 1
);

sub connect {
    my $self   = shift;
    my $socket = IO::Socket::INET->new(
        'PeerAddr' => $self->to(),
        'Proto'    => 'tcp',
    ) || carp $@;

    ( carp && return ) if !defined $socket;
    $self->select( IO::Select->new($socket) );

    binmode $socket;
    $self->socket($socket);
    $self->send('pb0');
    my $buffer = $self->recv(2);

    $self->disconnect() if $buffer ne 'ok';
    return;
}

sub disconnect {
    my $self = shift;
    $self->socket->close();
    return;
}

__PACKAGE__->meta->make_immutable();
1;
