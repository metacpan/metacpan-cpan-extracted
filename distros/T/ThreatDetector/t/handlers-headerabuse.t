#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 6;
use lib 'lib';
use ThreatDetector::Handlers::HeaderAbuse qw(handle_header_abuse get_header_abuse_events);

@ThreatDetector::Handlers::HeaderAbuse::HEADER_ABUSE_EVENTS = ();

my $entry_with_referer = {
    ip => '203.0.113.10',
    method => 'POST',
    uri => '/submit.php',
    status => '404',
    user_agent => 'qslmap/1.5.2',
    referer => 'http://malicious.com/',
};

handle_header_abuse($entry_with_referer);

my $entry_without_referer = {
    ip => '198.51.100.23',
    method => 'GET',
    uri => '/search?q=test',
    status => '200',
    user_agent => 'curl/7.64.1',
};

handle_header_abuse($entry_without_referer);

my @events = get_header_abuse_events();

is(scalar @events, 2, 'Two header abuse events recorded');

my $event1 = $events[0];
my $event2 = $events[1];

ok($event1->{timestamp} =~ /^\d+\.\d+$/, 'Timestamp format valid (event 1)');
is($event1->{referer}, 'http://malicious.com/', 'Referer correctly recorded (event 1)');

ok($event2->{timestamp} =~ /^\d+\.\d+$/, 'Timestamp format valid (event 2)');
is($event2->{ip}, '198.51.100.23', 'Correct IP recorded (event 2)');
is($event2->{referer}, '', 'Missing referer handled as emtpy string');