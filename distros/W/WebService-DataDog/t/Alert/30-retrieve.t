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
	: plan( tests => 10 );

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


throws_ok(
	sub
	{
		$response = $alert_obj->retrieve();
	},
	qr/Argument.*required/,
	'Dies on missing alert id argument.',
);

throws_ok(
	sub
	{
		$response = $alert_obj->retrieve( id => "abc" );
	},
	qr/id must be a number/,
	'Dies on invalid alert id.',
);

ok(
	open( FILE, 'webservice-datadog-alert-alertid.tmp'),
	'Open temp file to read alert id'
);

my $alert_id;

ok(
	$alert_id = do { local $/; <FILE> },
	'Read in alert id'
);

ok(
	close FILE,
	'Close temp file'
);

lives_ok(
	sub
	{
		$response = $alert_obj->retrieve( id => $alert_id );
	},
	'Request info on specific alert.',
);

ok(
	defined( $response ),
	'Response was received.'
);

ok(
	Data::Validate::Type::is_hashref( $response ),
	'Response is a hashref.',
);

