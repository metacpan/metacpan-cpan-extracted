package UAV::Pilot::Wumpus::Server::Backend::RaspberryPiI2C;
use v5.14;
use Moose;
use namespace::autoclean;
use UAV::Pilot::Wumpus::Server::Backend;
use UAV::Pilot::Wumpus::PacketFactory;
use HiPi::Device::I2C ();
use HiPi::BCM2835::I2C qw( :all );
use Time::HiRes ();


has '_i2c' => (
    is     => 'ro',
    isa    => 'HiPi::BCM2835::I2C',
    writer => '_set_i2c',
);
has 'slave_addr' => (
    is      => 'ro',
    isa     => 'Int',
    default => 0x09,
);
has 'throttle_register' => (
    is      => 'ro',
    isa     => 'Int',
    default => 0x01,
);
has 'turn_register' => (
    is      => 'ro',
    isa     => 'Int',
    default => 0x02,
);
has 'i2c_device' => (
    is      => 'ro',
    isa     => 'Int',
    default => BB_I2C_PERI_1,
);
has '_last_time_packet_sent' => (
    is      => 'rw',
    isa     => 'Num',
    default => 0.0,
);
has 'ch1_max_out' => (
    is      => 'ro',
    isa     => 'Int',
    default => 2000, # Could be 2300, depending on ESC
);
has 'ch1_min_out' => (
    is      => 'ro',
    isa     => 'Int',
    default => 1000, # Could be 700, depending on ESC
);
has 'ch2_max_out' => (
    is      => 'ro',
    isa     => 'Int',
    default => 180,
);
has 'ch2_min_out' => (
    is      => 'ro',
    isa     => 'Int',
    default => 0,
);
has 'ch3_max_out' => (
    is      => 'ro',
    isa     => 'Int',
    default => 100,
);
has 'ch3_min_out' => (
    is      => 'ro',
    isa     => 'Int',
    default => 0,
);
has 'ch4_max_out' => (
    is      => 'ro',
    isa     => 'Int',
    default => 100,
);
has 'ch4_min_out' => (
    is      => 'ro',
    isa     => 'Int',
    default => 0,
);
has 'ch5_max_out' => (
    is      => 'ro',
    isa     => 'Int',
    default => 100,
);
has 'ch5_min_out' => (
    is      => 'ro',
    isa     => 'Int',
    default => 0,
);
has 'ch6_max_out' => (
    is      => 'ro',
    isa     => 'Int',
    default => 100,
);
has 'ch6_min_out' => (
    is      => 'ro',
    isa     => 'Int',
    default => 0,
);
has 'ch7_max_out' => (
    is      => 'ro',
    isa     => 'Int',
    default => 100,
);
has 'ch7_min_out' => (
    is      => 'ro',
    isa     => 'Int',
    default => 0,
);
has 'ch8_max_out' => (
    is      => 'ro',
    isa     => 'Int',
    default => 100,
);
has 'ch8_min_out' => (
    is      => 'ro',
    isa     => 'Int',
    default => 0,
);

with 'UAV::Pilot::Wumpus::Server::Backend';
with 'UAV::Pilot::Logger';


sub BUILD
{
    my ($self) = @_;
    my $logger = $self->_logger;
    $logger->info( 'Attempting to init i2c comm on slave addr ['
        . $self->slave_addr . ']' );

    my $i2c = HiPi::BCM2835::I2C->new(
        peripheral => $self->i2c_device,
        address    => $self->slave_addr,
    );
    $self->_set_i2c( $i2c );

    $logger->info( 'Init i2c comm done' );
    return 1;
}


sub _packet_request_startup
{
    my ($self, $packet) = @_;
    $self->_set_started( 1 );
    return 1;
}

sub _packet_radio_trims
{
    # Ignore
}

sub _packet_radio_out
{
    my ($self, $packet, $server) = @_;
    $self->_logger->info( 'Writing packet: ' . ref($packet) );

    my $throttle = $self->_map_ch1_value( $server, $packet->ch1_out );
    my $turn     = $self->_map_ch2_value( $server, $packet->ch2_out );
    my @throttle_bytes = ( ($throttle >> 8), ($throttle & 0xff) );
    my @turn_bytes     = ( ($turn     >> 8), ($turn     & 0xff) );

    $self->_write_packet( $self->throttle_register, @throttle_bytes );
    $self->_write_packet( $self->turn_register,     @turn_bytes     );
    return 1;
}


sub _write_packet
{
    my ($self, $register, @bytes) = @_;
    my $logger = $self->_logger;

    eval {
        $logger->info( "Writing [@bytes] to register [$register]" );
        $self->_i2c->bus_write( $register, @bytes );
    };
    if( $@ ) {
        $logger->warn( 'Could not write i2c data: ' . $@ );
    }

    return 1;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__


=head1 NAME

  UAV::Pilot::Wumpus::Server::Backend::RaspberryPiI2C

=head1 DESCRIPTION

Does the C<UAV::Pilot::Wumpus::Server::Backend> role.  Communicates using 
the Raspberry Pi's I2C interface, using a protocol compatible with the 
Wumpus Arduino code.

The Arduino code and hardware description are available at:

https://github.com/frezik/wumpus-rover

=cut
