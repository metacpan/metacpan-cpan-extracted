#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use JSON;
use lib 'lib';
use ThreatDetector::Handlers::BotFingerprint qw(handle_scanner get_scanner_fingerprint_events);

my @initial = get_scanner_fingerprint_events();
is(scalar(@initial), 0, 'Initial fingerprint event array is empty');

my $entry = {
    ip => '203.0.113.45',
    method => 'GET',
    uri => '/admin',
    status => 200,
    user_agent => 'sqlmap/1.5.2#stable',
};

local *STDOUT;
open STDOUT, '>', \my $dummy_output;

handle_scanner($entry);

my @events = get_scanner_fingerprint_events();
is(scalar(@events), 1, 'One scanner fingerprint event recorded');

my $event = $events[0];

ok(defined $event->{timestamp}, 'Event has timestamp');
is($event->{type}, 'scanner_fingerprint', 'Event type is correct');
is($event->{ip}, $entry->{ip}, 'IP matches');
is($event->{method}, $entry->{method}, 'Method matches');
is($event->{uri}, $entry->{uri}, 'URI matches');
is($event->{status}, $entry->{status}, 'Status matches');
is($event->{user_agent}, $entry->{user_agent}, 'User-agent matches');

done_testing();