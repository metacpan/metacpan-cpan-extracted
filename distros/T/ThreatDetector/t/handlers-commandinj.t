#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 4;
use lib 'lib';
use ThreatDetector::Handlers::CommandInjection qw(handle_command_injection get_command_injection_events);

@ThreatDetector::Handlers::CommandInjection::COMMAND_INJECTION_EVENTS = ();

my $test_entry = {
    ip => '192.168.0.1',
    method => 'GET',
    uri => '/vulnerable.php?arg=;cat%20/etc/passwd',
    status => '200',
    user_agent => 'curl/7.68.0',
};

handle_command_injection($test_entry);

my @events = get_command_injection_events();

is(scalar @events, 1, 'One command injection event was recorded');

my $event = $events[0];

ok($event->{timestamp} =~ /^\d+\.\d+$/, 'Timestamp is in correct format (epoch.microseconds)');
is($event->{ip}, '192.168.0.1', 'Correct IP address logged');
is($event->{uri}, '/vulnerable.php?arg=;cat%20/etc/passwd', 'Correct URI logged');