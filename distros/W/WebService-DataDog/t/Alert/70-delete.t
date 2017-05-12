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
	: plan( tests => 8 );

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
		$response = $alert_obj->delete( id => "abc" );
	},
	qr/id must be a number/,
	'Dies on invalid dash id.',
);

throws_ok(
	sub
	{
		$response = $alert_obj->delete( id => "123" );
	},
	qr/Error 404/,
	'Dies on unknown dash id.',
);

ok(
	open( FILE, 'webservice-datadog-alert-alertid.tmp'),
	'Open temp file to read alert id'
);

my $alert_id;

ok(
	$alert_id = do { local $/; <FILE> },
	'Read in alert id.'
);

ok(
	close FILE,
	'Close temp file.'
);


lives_ok(
	sub
	{
		$alert_obj->delete( id => $alert_id );
	},
	'Delete specified alert.'
);

