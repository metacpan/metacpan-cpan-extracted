#!perl -T

use strict;
use warnings;

use Data::Dumper;

use Data::Validate::Type;
use Test::Exception;
use Test::Most ;

use WebService::DataDog;


eval 'use DataDogConfig';
$@
	? plan( skip_all => 'Local connection information for DataDog required to run tests.' )
	: plan( tests => 3 );

my $config = DataDogConfig->new();

# Create an object to communicate with DataDog
my $datadog = WebService::DataDog->new( %$config );
ok(
	defined( $datadog ),
	'Create a new WebService::DataDog object.',
);


my $alert_obj = $datadog->build('Alert');
ok(
	defined( $alert_obj ),
	'Create a new WebService::DataDog::Alert object.',
);

my $response;
lives_ok(
	sub
	{
		$response = $alert_obj->unmute_all();
	},
	'Request all alerts be unmuted.',
);

