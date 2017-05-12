#!perl -T

use strict;
use warnings;

use Data::Dumper;

use Data::Validate::Type;
use Test::Exception;
use Test::Most 'bail';

use WebService::DataDog;


eval 'use DataDogConfig';
$@
	? plan( skip_all => 'Local connection information for DataDog required to run tests.' )
	: plan( tests => 6 );

my $config = DataDogConfig->new();

# Create an object to communicate with DataDog
my $datadog = WebService::DataDog->new( %$config );
ok(
	defined( $datadog ),
	'Create a new WebService::DataDog object.',
);


my $dashboard_obj = $datadog->build('Dashboard');
ok(
	defined( $dashboard_obj ),
	'Create a new WebService::DataDog::Dashboard object.',
);
my $response;

lives_ok(
	sub
	{
		$response = $dashboard_obj->get_all_dashboards();
	},
	'Request list of all dashboards - deprecated version.',
);

lives_ok(
	sub
	{
		$response = $dashboard_obj->retrieve_all();
	},
	'Request list of all dashboards.',
);

ok(
	defined( $response ),
	'Response was received.'
);

ok(
	Data::Validate::Type::is_arrayref( $response ),
	'Response is an arrayref.',
);
