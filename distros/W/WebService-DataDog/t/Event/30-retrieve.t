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
	: plan( tests => 12 );

my $config = DataDogConfig->new();

# Create an object to communicate with DataDog
my $datadog = WebService::DataDog->new( %$config );
ok(
	defined( $datadog ),
	'Create a new WebService::DataDog object.',
);


my $event_obj = $datadog->build('Event');
ok(
	defined( $event_obj ),
	'Create a new WebService::DataDog::Event object.',
);
my $response;


throws_ok(
	sub
	{
		$response = $event_obj->retrieve( );
	},
	qr/Argument.*required/,
	'Dies on missing event id argument.',
);

throws_ok(
	sub
	{
		$response = $event_obj->retrieve( id => "abc" );
	},
	qr/id must be a number/,
	'Dies on invalid event id.',
);

throws_ok(
	sub
	{
		$response = $event_obj->retrieve( id => "123" );
	},
	qr/404 Not Found/,
	'Dies on unknown event id.',
);


ok(
	open( FILE, 'webservice-datadog-events-eventid.tmp'),
	'Open temp file to read event id'
);

my $event_id;

ok(
	$event_id = do { local $/; <FILE> },
	'Read in event id'
);

ok(
	close FILE,
	'Close temp file'
);

lives_ok(
	sub
	{
		$response = $event_obj->get_event( id => $event_id );
	},
	'Request info on specific event - deprecated version.',
	);

lives_ok(
	sub
	{
		$response = $event_obj->retrieve( id => $event_id );
	},
	'Request info on specific event.',
);

ok(
	defined( $response ),
	'Response was received.'
);

ok(
	Data::Validate::Type::is_hashref( $response ),
	'Response is a hashref.',
);

