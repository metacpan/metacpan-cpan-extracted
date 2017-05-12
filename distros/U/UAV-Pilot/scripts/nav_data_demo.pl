#!/usr/bin/perl
use v5.14;
use warnings;
use UAV::Pilot::Driver::ARDrone;
use UAV::Pilot::Driver::ARDrone::NavPacket;
use IO::Socket::Multicast;
use Getopt::Long ();


my $HOST           = '192.168.1.1';
my $MULTICAST_ADDR = UAV::Pilot::Driver::ARDrone->ARDRONE_MULTICAST_ADDR;
my $PORT           = UAV::Pilot::Driver::ARDrone->ARDRONE_PORT_NAV_DATA;
my $SOCKET_TYPE    = UAV::Pilot::Driver::ARDrone->ARDRONE_PORT_NAV_DATA_TYPE;
my $IFACE          = 'wlan0';
my $SDL            = 0;

Getopt::Long::GetOptions(
    'host=s'  => \$HOST,
    'sdl'     => \$SDL,
    'iface=s' => \$IFACE,
);


say "Connectting to $HOST . . . ";
my $sender = UAV::Pilot::Driver::ARDrone->new({
    host => $HOST,
});
$sender->connect;

my $sdl = undef;
if( $SDL ) {
    say "Init SDL output . . . ";
    eval "require UAV::Pilot::Control::ARDrone::SDLNavOutput";
    die "Could not load SDL output: $@\n" if $@;

    $sdl = UAV::Pilot::Control::ARDrone::SDLNavOutput->new;
    say "SDL Output ready";
}

say "Ready to receive data from $HOST";
my $continue = 1;
while( $continue ) {
    if( $sender->read_nav_packet ) {
        my $last_nav_packet = $sender->last_nav_packet;

        if( $SDL ) {
            $sdl->render( $last_nav_packet );
        }
        else {
            say "Got nav packet: " . $last_nav_packet->to_string;
        }
    }

    sleep 1;
}
