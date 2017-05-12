package UAV::Pilot::Wumpus::Server::Backend;
use v5.14;
use Moose::Role;

use constant PACKET_METHOD_MAP => {
    'StartupRequest' => '_packet_request_startup',
    'RadioTrims'            => '_packet_radio_trims',
    'RadioMinMax'           => '_packet_radio_min_max',
    'RadioOutputs'          => '_packet_radio_out',
};
my @REQUIRED_PACKET_METHODS = grep {
    $_ !~ /\A (?:
        _packet_radio_min_max
    ) \z/x
} values %{ +PACKET_METHOD_MAP };

requires @REQUIRED_PACKET_METHODS;
requires qw{
   ch1_max_out ch1_min_out
   ch2_max_out ch2_min_out
   ch3_max_out ch3_min_out
   ch4_max_out ch4_min_out
   ch5_max_out ch5_min_out
   ch6_max_out ch6_min_out
   ch7_max_out ch7_min_out
   ch8_max_out ch8_min_out
};

with 'UAV::Pilot::Logger';

has 'started' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
    writer  => '_set_started',
);


sub process_packet
{
    my ($self, $packet, $server) = @_;
    my $packet_class = ref $packet;
    my ($short_class) = $packet_class =~ /:: (\w+) \z/x;

    if(! exists $self->PACKET_METHOD_MAP->{$short_class}) {
        $self->_logger->warn( "Couldn't find a method to handle packet"
            . " '$short_class'" );
        return 0;
    }

    my $method = $self->PACKET_METHOD_MAP->{$short_class};
    return $self->$method( $packet, $server );
}

sub _packet_radio_min_max
{
    my ($self, $packet, $server) = @_;
    foreach (1..8) {
        my $packet_min_call = 'ch' . $_ . '_min';
        my $server_min_call = '_set_ch' . $_ . '_min';
        my $packet_max_call = 'ch' . $_ . '_max';
        my $server_max_call = '_set_ch' . $_ . '_max';

        my $min_value = $packet->$packet_min_call // 0;
        $server->$server_min_call( $min_value );
        my $max_value = $packet->$packet_max_call // 0;
        $server->$server_max_call( $max_value );
    }
    return 1;
}

sub _packet_radio_maxes
{
    my ($self, $packet, $server) = @_;
    foreach (1..8) {
        my $packet_call = 'ch' . $_ . '_max';
        my $server_call = '_set_ch' . $_ . '_max';

        my $value = $packet->$packet_call // 0;
        $server->$server_call( $value );
    }
    return 1;
}

#
# Implement _map_ch1_value() through _map_ch8_value() here
#
foreach my $i (1..8) {
    my $sub_name = '_map_ch' . $i . '_value';
    my $min_in = 'ch' . $i . '_min';
    my $max_in = 'ch' . $i . '_max';
    my $min_out = 'ch' . $i . '_min_out';
    my $max_out = 'ch' . $i . '_max_out';

    no strict 'refs';
    *$sub_name = sub {
        my ($self, $server, $val) = @_;
        return $server->_map_value(
            $server->$min_in,
            $server->$max_in,
            $self->$min_out,
            $self->$max_out,
            $val,
        );
    }
}


1;
__END__


=head1 NAME

    UAV::Pilot::Wumpus::Server::Backend

=head1 DESCRIPTION

Role for Wumpus Backends.  A Backend connects directly to the hardware 
that drives the rover.  For instance, the RaspberryPiI2C backend communicates 
over the Raspberry Pi's I2C interface using a protocol shared by the 
wumpus_rover Arduino implementation.

Does the C<UAV::Pilot::Logger> role.

=head1 ATTRIBUTES

=head2 started

Specifies if this backend has been started yet.  Starting it is done by 
passing a C<RequestStartupMessage> packet to C<process_packet()>.


=head1 METHODS

=head2 process_packet

    process_packet( $packet )

Takes the packet and does something with it.  Usually, this something is a 
sensible thing to do.

=head1 REQUIRED METHODS/ATTRIBUTES

=head2 _packet_request_startup

    _packet_request_startup( $packet, $server )

Passed a packet and the server associated with the connection.  Handles the 
initial startup.

=head2 _packet_radio_trims

    _packet_request_trims( $packet, $server )

Passed a packet and the server associated with the connection.  Handles the 
radio trims.

=head2 _packet_radio_out

    _packet_radio_out( $packet, $server )

Passed a packet and the server associated with the connection.  Handles the 
radio outputs, which is the primary way of moving.

=head2 _ch*_min_out() and _ch*_max_out()

Returns the min/max settings for each channel that will be output by this 
backend.  Channels are numbered 1 through 8.

Why do we map the values at this level?  For the Arduino output, wouldn't it 
be better for it to take specified values and convert it to its own output 
internally?  Perhaps.  The reason why it was chosen to do the value mapping 
here is to make the Arduino end as simple-stupid as possible.

=cut
