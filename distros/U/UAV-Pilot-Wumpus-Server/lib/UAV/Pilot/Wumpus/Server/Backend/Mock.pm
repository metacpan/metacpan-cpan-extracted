package UAV::Pilot::Wumpus::Server::Backend::Mock;
use v5.14;
use Moose;
use namespace::autoclean;
use UAV::Pilot::Wumpus::Server::Backend;


has 'started' => (
    is     => 'ro',
    isa    => 'Bool',
    writer => '_set_started',
);

foreach (1..8) {
    my $ch_trim_name = 'ch' . $_ . '_trim';
    my $ch_min_name  = 'ch' . $_ . '_min';
    my $ch_max_name  = 'ch' . $_ . '_max';
    my $ch_out_name  = 'ch' . $_ . '_out';

    has $ch_trim_name => (
        is     => 'ro',
        isa    => 'Maybe[Int]',
        writer => '_set_' . $ch_trim_name,
    );
    has $ch_min_name => (
        is     => 'ro',
        isa    => 'Maybe[Int]',
        writer => '_set_' . $ch_min_name,
    );
    has $ch_max_name => (
        is     => 'ro',
        isa    => 'Maybe[Int]',
        writer => '_set_' . $ch_max_name,
    );
    has $ch_out_name => (
        is     => 'ro',
        isa    => 'Maybe[Int]',
        writer => '_set_' . $ch_out_name,
    );
}

has 'ch1_max_out' => (
    is      => 'ro',
    isa     => 'Int',
    default => 100,
);
has 'ch1_min_out' => (
    is      => 'ro',
    isa     => 'Int',
    default => 0,
);
has 'ch2_max_out' => (
    is      => 'ro',
    isa     => 'Int',
    default => 100,
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


sub _packet_request_startup
{
    my ($self, $packet) = @_;
    $self->_set_started( 1 );
    return 1;
}

sub _packet_radio_trims
{
    my ($self, $packet) = @_;
    foreach (1..8) {
        my $fetch_method = 'ch' . $_ . '_trim';
        my $set_method   = '_set_ch' . $_ . '_trim';
        $self->$set_method( $packet->$fetch_method );
    }
    return 1;
}

sub _packet_radio_out
{
    my ($self, $packet, $server) = @_;
    foreach (1..8) {
        my $fetch_method = 'ch' . $_ . '_out';
        my $set_method   = '_set_ch' . $_ . '_out';
        my $ch_map_method = '_map_ch' . $_ . '_value';

        my $in_value = $packet->$fetch_method // 0;
        my $out_value = $self->$ch_map_method( $server, $in_value );
        $self->$set_method( $out_value );
    }
    return 1;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

