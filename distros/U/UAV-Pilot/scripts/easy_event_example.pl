#!/usr/bin/perl
use v5.14;
use warnings;
use AnyEvent;
use UAV::Pilot;
use UAV::Pilot::Driver::ARDrone;
use UAV::Pilot::Control::ARDrone::Event;
use UAV::Pilot::EasyEvent;

my $IP = '192.168.1.1';


my $ardrone = UAV::Pilot::Driver::ARDrone->new({
    host => $IP,
});
$ardrone->connect;
my $dev = UAV::Pilot::Control::ARDrone::Event->new({
    sender => $ardrone,
});

my $cv = $dev->init_event_loop;
my $event = UAV::Pilot::EasyEvent->new({
    condvar => $cv,
});


$event->add_timer({
    duration       => 10,
    duration_units => $event->UNITS_MILLISECOND,
    cb             => sub {
        $dev->takeoff;
    },
})->add_timer({
    duration       => 10_000,
    duration_units => $event->UNITS_MILLISECOND,
    cb             => sub {
        $dev->yaw( 1.0 );
    },
})->add_timer({
    duration       => 2000,
    duration_units => $event->UNITS_MILLISECOND,
    cb             => sub {
        $dev->yaw( -1.0 );
    },
})->add_timer({
    duration       => 2000,
    duration_units => $event->UNITS_MILLISECOND,
    cb             => sub {
        $dev->yaw( 0 );
        $dev->land;
        $cv->send;
    },
});

$event->activate_events;
$cv->recv;
