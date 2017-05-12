package UAV::Pilot::WumpusRover::Server::Mock;
use v5.14;
use Moose;
use namespace::autoclean;

extends 'UAV::Pilot::WumpusRover::Server';


has 'last_packet_out' => (
    is  => 'rw',
    isa => 'UAV::Pilot::WumpusRover::Packet',
);


sub _send_packet
{
    my ($self, $packet) = @_;
    $self->last_packet_out( $packet );
    return 1;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

