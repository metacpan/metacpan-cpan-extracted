#!/usr/bin/perl

use strict;
use warnings;

use WebService::DataDog;
use Try::Tiny;
use Data::Dumper;

my $datadog = WebService::DataDog->new(
	api_key         => 'YOUR_API_KEY',
	application_key => 'YOUR_APPLICATION_KEY',
#	verbose         => 1,
);

my $event = $datadog->build('Event');
my $event_list;

try
{
	# Find all events that occurred in the last 9 days
	$event_list = $event->search(
		start => time - ( 9 * 24 * 60 * 60),
	);
}
catch
{
	print "FAILED - Couldn't retrieve events because: @_ \n";
};

print "Event list:\n", Dumper($event_list);


$event_list = undef;
try
{
	# Find all GitHub events that occurred in the last 30 days
	$event_list = $event->search(
		start   => time - ( 30 * 24 * 60 * 60),
		sources => [ 'Github' ],
	);
}
catch
{
	print "FAILED - Couldn't retrieve events because: @_ \n";
};

print "GitHub Event list:\n", Dumper($event_list);

# Grab first event from list returned
my $one_event = $event_list->[0]->{'id'};

# Event details
my $event_details = $event->retrieve( id => $one_event );
print "Details of event >$one_event<: ", Dumper($event_details);

# Post a new event to stream
$event->create(
	title => "Example event title(" . time() . ")",
	text  => "example event body/description",
);

