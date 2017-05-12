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


my $dashboard = $datadog->build('Dashboard');
my $dashboard_list;
# Example - list of all user-created/cloned dashboards
try
{
	$dashboard_list = $dashboard->retrieve_all();
}
catch
{
	print "FAILED - Couldn't retrieve dashboards because: @_ \n";
};

print "Dashboard list:\n", Dumper($dashboard_list);

# Example - update existing user-created dashboard
try
{
	$dashboard->update(
		id    => '504',
		title => "New title here",
	);
}
catch
{
	print "FAILED - Could not update dashboard title because: @_ \n";
};



# Example - delete existing user-created dashboard
# BE VERY CAREFUL WITH THIS! Also note: you cannot delete system/auto generated dashboards via the API
try
{
	$dashboard->delete( id => '504' );
}
catch
{
	print "FAILED - Could not delete dashboard id '504' because: @_ \n";
};


# Example - create new dashboard with a single graph
try
{
	$dashboard->create(
		title       => "TEST DASH",
		description => "test dashboard",
		graphs      =>
		[
			{
				title => "Sum of Memory Free",
				definition =>
				{
					events   =>[],
					requests => [
						{ q => "sum:system.mem.free{*}" }
					]
				},
				viz => "timeseries"
			},
		],
	);
}
catch
{
	print "FAILED - Could not create new dashboard because: @_ \n";
};

