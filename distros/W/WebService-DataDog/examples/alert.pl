#!/usr/bin/perl

use strict;
use warnings;

use WebService::DataDog;
use Try::Tiny;
use Data::Dumper;

my $datadog = WebService::DataDog->new(
	api_key         => 'YOUR_API_KEY',
	application_key => 'YOUR_APP_KEY',
#	verbose         => 1,
);

my $alert = $datadog->build('Alert');
my $alert_list;

try
{
	# Find all alerts 
	$alert_list = $alert->retrieve_all();
}
catch
{
	print "FAILED - Couldn't retrieve alerts because: @_ \n";
};

print "Alert list:\n", Dumper($alert_list);


# Grab first alert from list returned
my $one_alert = $alert_list->[0]->{'id'};

# Alert details
my $alert_details = $alert->retrieve( id => $one_alert );
print "Details of alert >$one_alert<: ", Dumper($alert_details);

# Create new alert
my $new_alert_id = $alert->create(
	query    => "sum(last_1d):sum:system.net.bytes_rcvd{host:host0} > 100",
	name     => "Bytes received on host0",
	message  => "Message goes here",
	silenced => 1,
);
print "Created new alert >$new_alert_id<\n";

# Change name of existing alert
$alert->update(
	id    => $new_alert_id,
	query    => "sum(last_1d):sum:system.net.bytes_rcvd{host:host0} > 100",
	name  => "Bits received on host0",
);


# Mute all alerts
$alert->mute_all();

# Unmute all alerts
$alert->unmute_all();
