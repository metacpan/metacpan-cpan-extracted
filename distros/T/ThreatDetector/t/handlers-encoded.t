#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 4;
use lib 'lib';
use ThreatDetector::Handlers::EncodedPayload qw(handle_encoded get_encoded_payload_events);

@ThreatDetector::Handlers::EncodedPayload::ENCODED_PAYLOAD_EVENTS = ();

my $test_entry = {
    ip => '172.16.1.5',
    method => 'GET',
    uri => '/%2e%2e%2fadmin%2fconfig.php',
    status => '200',
    user_agent => 'python-requests/2.25.1',
};

handle_encoded($test_entry);

my @events = get_encoded_payload_events();
is(scalar @events, 1, 'One encoded payload event was recorded');

my $event = $events[0];

ok($event->{timestamp} =~ /^\d+\.\d+$/, 'Timestamp is in correct format');
is($event->{ip}, '172.16.1.5', 'Correct IP address logged');
is($event->{uri}, '/%2e%2e%2fadmin%2fconfig.php', 'Correct URI logged');