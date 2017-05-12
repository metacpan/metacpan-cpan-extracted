#!/usr/bin/perl

use strict;
use warnings;

use WebService::DataDog;
use Try::Tiny;

my $datadog = WebService::DataDog->new(
	api_key         => 'YOUR_API_KEY',
	application_key => 'YOUR_APPLICATION_KEY',
#	verbose         => 1,
);


my $metric = $datadog->build('Metric');

my $success = 1;
try
{
	$metric->emit(
		name  => 'testmetric.cron.app_name.heartbeat',
	);
}
catch
{
	$success = 0;
	print "FAILED - Couldn't post metric because: @_ \n";
};

print "Metrics posting #1 " . ( $success ? 'succeeded' : 'failed' ) . "\n";



$success = 1;
# Post a counter a metric, with timestamp 'now'
try
{
	$metric->emit(
		name  => 'testmetric.cron.app_name.heartbeat',
		value => 1,
		type  => 'counter',
	);
}
catch
{
	$success = 0;
	print "FAILED - Couldn't post metric because: @_ \n";
};

print "Metrics posting #2 " . ( $success ? 'succeeded' : 'failed' ) . "\n";
