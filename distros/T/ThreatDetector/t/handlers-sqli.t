#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 6;
use lib 'lib';
use ThreatDetector::Handlers::SQLInjection qw(handle_sql_injection get_sqli_events);

@ThreatDetector::Handlers::SQLInjection::SQLI_EVENTS = ();

my $entry_with_referer = {
    ip => '203.0.113.1',
    method => 'GET',
    uri => '/search.php?q=%27+OR+1%3D1--',
    status => '200',
    user_agent => 'sqlmap/1.4',
    referer => 'http://example.com/',
};

handle_sql_injection($entry_with_referer);

my $entry_without_referer = {
    ip => '198.51.100.42',
    method => 'POST',
    uri => '/login',
    status => '403',
    user_agent => 'CustomScanner/2.0',
};

handle_sql_injection($entry_without_referer);

my @events = get_sqli_events();
is(scalar @events, 2, 'Two SQLi events were recorded');

my $event1 = $events[0];
my $event2 = $events[1];

ok($event1->{timestamp} =~ /\d+\.\d+$/, 'Timestamp format valid (event 1)');
is($event1->{referer}, 'http://example.com/', 'Referer recorded (event 1)');
is($event2->{referer}, '', 'Missing referer handled as empty string (event 2)');
is($event2->{method}, 'POST', 'correct HTTP method recorded (event 2)');
ok($event2->{uri} =~ /login/, 'Correct URI recorded (event 2)');