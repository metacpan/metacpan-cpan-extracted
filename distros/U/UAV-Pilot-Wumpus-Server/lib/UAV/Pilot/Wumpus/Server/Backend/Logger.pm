package UAV::Pilot::Wumpus::Server::Backend::Logger;

use v5.14;
use warnings;
use Moose;
use namespace::autoclean;
use UAV::Pilot::Wumpus::Server::Backend;

my @CHANNELS = qw{ 
   ch1_max_out ch1_min_out
   ch2_max_out ch2_min_out
   ch3_max_out ch3_min_out
   ch4_max_out ch4_min_out
   ch5_max_out ch5_min_out
   ch6_max_out ch6_min_out
   ch7_max_out ch7_min_out
   ch8_max_out ch8_min_out
};
has \@CHANNELS => (
    is => 'rw',
    isa => 'Int',
    default => 0,
);

foreach my $chan (@CHANNELS) {
    after $chan => sub {
        my ($self, $value) = @_;
        say "Set $value on $chan";
    };
}

with 'UAV::Pilot::Wumpus::Server::Backend';


sub _packet_request_startup
{
    my ($self, $packet, $server) = @_;
    say "Requested startup";
    $self->_set_started( 1 );
    return 1;
}

sub _packet_radio_trims
{
    my ($self, $packet, $server) = @_;
    say "Set radio trims";
    return 1;
}

sub _packet_radio_out
{
    my ($self, $packet, $server) = @_;

    my @chan_vals = map {
        my $ch = 'ch' . $_ . '_out';
        $packet->$ch;
    } 1 .. 16;
    say "Radio output: " . join( ', ', @chan_vals );

    return 1;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__


=head1 NAME

  UAV::Pilot::Wumpus::Server::Backend::Logger

=head1 DESCRIPTION

Backend that logs to STDOUT.  Mainly for testing purposes.

=cut
