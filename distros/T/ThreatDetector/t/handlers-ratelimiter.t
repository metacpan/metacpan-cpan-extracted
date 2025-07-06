#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 4;
use lib 'lib';
use ThreatDetector::Handlers::RateLimiter qw(handle_rate_burst get_rate_burst_events);

@ThreatDetector::Handlers::RateLimiter::RATE_BURST_EVENTS = ();
no warnings 'once';
%ThreatDetector::Handlers::RateLimiter::ip_activity = ();

my $ip = '198.18.0.1';

my $entry = {
    ip => $ip,
    method => 'GET',
    uri => '/api/data',
    status => '200',
    user_agent => 'test-agent/1.0',
    referer => 'https://test.local/',
};

for (1..25) {
    handle_rate_burst($entry);
}

my @events = get_rate_burst_events();
is(scalar @events, 1, 'One rate burst event was recorded');

my $event = $events[0];

ok($event->{timestamp} =~ /^\d+\.\d+$/, 'Timestamp is in correct format');
is($event->{ip}, $ip, 'Correct IP logged');
ok($event->{count} > 20, 'Count exceeds threshold');