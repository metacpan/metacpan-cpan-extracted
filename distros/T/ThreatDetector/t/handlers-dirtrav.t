#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 4;
use lib 'lib';
use ThreatDetector::Handlers::DirectoryTraversal qw(handle_directory_traversal get_directory_traversal_events);

@ThreatDetector::Handlers::DirectoryTraversal::DIRECTORY_TRAVERSAL_EVENTS = ();

my $test_entry = {
    ip => '10.0.0.42',
    method => 'GET',
    uri => '/../../etc/passwd',
    status => '403',
    user_agent => 'Mozilla/5.0',
};

handle_directory_traversal($test_entry);

my @events = get_directory_traversal_events();

is(scalar @events, 1, 'One directory traversal event was recorded');

my $event = $events[0];

ok($event->{timestamp} =~ /^\d+\.\d+$/, 'Timestamp is in correct format');
is($event->{ip}, '10.0.0.42', 'Correct IP address logged');
is($event->{uri}, '/../../etc/passwd', 'Correct URI logged');