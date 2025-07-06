#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 6;
use lib 'lib';
use ThreatDetector::Handlers::MethodAbuse qw(handle_http_method get_http_method_abuse_events);

@ThreatDetector::Handlers::MethodAbuse::HTTP_METHOD_EVENTS = ();

my $entry_with_referer = {
    ip => '10.10.10.10',
    method => 'DELETE',
    uri => '/api/user/123',
    status => '405',
    user_agent => 'AttackScanner/2.0',
    referer => 'https://example.com',
};

handle_http_method($entry_with_referer);

my $entry_without_referer = {
    ip => '192.168.1.15',
    method => 'TRACE',
    uri => '/',
    status => '501',
    user_agent => 'Telnetclient/1.0',
};

handle_http_method($entry_without_referer);
my @events = get_http_method_abuse_events();

is(scalar @events, 2, 'Two method abuse events recorded');

my $event1 = $events[0];
my $event2 = $events[1];

ok($event1->{timestamp} =~ /^\d+\.\d+$/, 'Valid timestamp (event 1)');
is($event1->{referer}, 'https://example.com', 'Referer present (event 1)');

ok($event2->{timestamp} =~ /^\d+\.\d+$/, 'Valid timestamp (event 2)');
is($event2->{method}, 'TRACE', 'Correct HTTP method recorded (event 2)');
is($event2->{referer}, '', 'Missing referer handled as empty string (event 2)');