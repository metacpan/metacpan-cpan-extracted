#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use JSON;
use lib 'lib';
use ThreatDetector::Handlers::ClientError qw(handle_client_error get_client_error_events);

my @initial = get_client_error_events();
is(scalar(@initial), 0, 'Initial client error event array is empty');

my $entry = {
    ip => '198.51.100.23',
    method => 'GET',
    uri => '/secret/page',
    status => 403,
    user_agent => 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)',
};

local *STDOUT;
open STDOUT, '>', \my $dummy_output;

handle_client_error($entry);

my @events = get_client_error_events();
is(scalar(@events), 1, 'One client error event recorded');

my $event = $events[0];

ok(defined $event->{timestamp}, 'Timestamp is defined');
is($event->{type}, 'client_error', 'Correct event type');
is($event->{ip}, $entry->{ip}, 'Correct IP');
is($event->{method}, $entry->{method}, 'Correct method');
is($event->{uri}, $entry->{uri}, 'Correct URI');
is($event->{status}, $entry->{status}, 'Correct status');
is($event->{user_agent}, $entry->{user_agent}, 'Correct user-agent');

done_testing();