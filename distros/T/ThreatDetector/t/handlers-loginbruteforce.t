#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 6;
use lib 'lib';
use ThreatDetector::Handlers::LoginBruteForce qw(handle_login_bruteforce get_login_brute_force_events);

@ThreatDetector::Handlers::LoginBruteForce::BRUTE_FORCE_EVENTS = ();

my $entry_with_referer = {
    ip => '192.0.2.99',
    method => 'POST',
    uri => '/login',
    status => '401',
    user_agent => 'Hydra/9.3',
    referer => 'https://example.com/login',
};

handle_login_bruteforce($entry_with_referer);

my $entry_without_referer = {
    ip => '203.0.113.44',
    method => 'POST',
    uri => '/admin/login',
    status => '403',
    user_agent => 'BurpSuite',
};

handle_login_bruteforce($entry_without_referer);
my @events = get_login_brute_force_events();
is(scalar @events, 2, 'Two brute-force events recorded');

my $event1 = $events[0];
my $event2 = $events[1];

ok($event1->{timestamp} =~ /^\d+\.\d+$/, 'Timestamp format valid (event 1)');
is($event1->{referer}, 'https://example.com/login', 'Referer recorded correctly (event 1)');

ok($event2->{timestamp} =~ /^\d+\.\d+$/, 'Timestamp format valid (event 2)');
is($event2->{ip}, '203.0.113.44', 'Correct IP recorded (event 2)');
is($event2->{referer}, '', 'Missing referer handled as emtpy string (event 2)');