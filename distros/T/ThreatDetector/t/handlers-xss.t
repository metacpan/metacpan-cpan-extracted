#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 6;
use lib 'lib';
use ThreatDetector::Handlers::XSS qw(handle_xss get_xss_events);

@ThreatDetector::Handlers::XSS::XSS_EVENTS = ();

my $entry_with_referer = {
    ip => '10.0.0.5',
    method => 'GET',
    uri => '/profile?name=<script>alert(1)</script>',
    status => '200',
    user_agent => 'XSSScanner/5.1',
    referer => 'https://trusted.site/profile',
};

handle_xss($entry_with_referer);

my $entry_without_referer = {
    ip => '172.16.0.77',
    method => 'POST',
    uri => '/submit?bio=%3Cimg+src%3Dx+onerror%3Dalert(1)%3E',
    status => '403',
    user_agent => 'Fuzzer/1.0',
};

handle_xss($entry_without_referer);
my @events = get_xss_events();

is(scalar @events, 2, 'Two XSS events were recorded');

my $event1 = $events[0];
my $event2 = $events[1];

ok($event1->{timestamp} =~ /^\d+\.\d+$/, 'Timestamp format valid (event 1)');
is($event1->{referer}, 'https://trusted.site/profile', 'Referer correctly recorded (event 1)');
is($event2->{referer}, '', 'Missing referer handled as emtpy string (event 2)');
is($event2->{ip}, '172.16.0.77', 'correct IP address logged (event 2)');
ok($event2->{uri} =~ /onerror/, 'URI contains expected payload pattern (event 2)');