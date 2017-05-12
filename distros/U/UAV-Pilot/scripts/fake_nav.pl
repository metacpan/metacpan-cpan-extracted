#!/usr/bin/perl
use v5.14;
use warnings;
use UAV::Pilot::Driver::ARDrone;
use UAV::Pilot::Driver::ARDrone::NavPacket;
use UAV::Pilot::Control::ARDrone::SDLNavOutput;
use SDL;
use SDL::Event;
use SDL::Events;


my $packet = make_packet( join('',
    '88776655', # Header
    'd004800f', # Drone state
    '346f0000', # Sequence number
    '01000000', # Vision flag
    # Options
    '0000', # Demo ID
    '9400', # Demo Size (148 bytes)
    '00000200', # Control State (landed, flying, hovering, etc.)
    '59000000', # Battery Voltage Filtered (mV? Percentage?)
    'bf4ccccd', # Pitch (-0.8)
    '00209ec4', # Roll
    '00941a47', # Yaw
    '00000000', # Altitude (cm)
    '00000000', # Estimated linear velocity (x)
    '00000000', # Estimated linear velocity (y)
    '00000000', # Estimated linear velocity (z)
    '00000000', # Streamed Frame Index
    '000000000000000000000000', # Deprecated camera detection params
    '00000000', # Camera Detection, Type of Tag
    '0000000000000000', # Deprecated camera detection params
    '0000000000000000',
    '0000000000000000',
    '0000000000000000',
    '0000000003000000',
    '0e4f453fe9fb22bf',
    'e7ffcdbcd111233f',
    '3455453f70f5003c',
    'c67a6b3c9feab4bc',
    '3ee97f3f00000000',
    '0000000000000000',
    '10004801',
    '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000',
    '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000',
    '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000',
    '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000',
    '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000',
    '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000',
    '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000',
    '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000',
    '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000',
    '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000',
    '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000',
    '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000',
    '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000',
    '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000',
    '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000',
    '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000', '0000',
    '0000', '0000',
    'ffff',     # Checksum ID
    '0800',     # Checksum Length
    '201b0000', # Checksum Data
) );
my $nav = UAV::Pilot::Driver::ARDrone::NavPacket->new({
    packet => $packet,
});

my $sdl = UAV::Pilot::Control::ARDrone::SDLNavOutput->new;
print "Nav Data\n--------\n" . $nav->to_string . "\n";
$sdl->render( $nav );

sleep 10;


sub make_packet
{
    my ($hex_str) = @_;
    pack 'H*', $hex_str;
}
