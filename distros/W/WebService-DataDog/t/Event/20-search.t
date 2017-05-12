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
	: plan( tests => 13 );

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
		$response = $event_obj->search();
	},
	qr/Argument.*required/,
	'Dies on missing "start" argument.',
);

throws_ok(
	sub
	{
		$response = $event_obj->search( start => "abc" );
	},
	qr/nvalid.*start/,
	'Dies on invalid start time.',
);

throws_ok(
	sub
	{
		$response = $event_obj->search(
			start => time(),
			end   => "abc",
		);
	},
	qr/nvalid.*end/,
	'Dies on invalid end time.',
);


throws_ok(
	sub
	{
		$response = $event_obj->search(
			start    => time(),
			priority => "nuclear",
		);
	},
	qr/nvalid.*priority/,
	'Dies on invalid priority.',
);

throws_ok(
	sub
	{
		$response = $event_obj->search(
			start => time(),
			tags  => "tags_go_here",
		);
	},
	qr/nvalid 'tags'.*arrayref/,
	'Dies on invalid tag list.',
);

throws_ok(
	sub
	{
		$response = $event_obj->search(
			start   => time(),
			sources => "sources_go_here",
		);
	},
	qr/nvalid 'sources'.*arrayref/,
	'Dies on invalid sources list.',
);


lives_ok(
	sub
	{
		$response = $event_obj->search( start => time() - ( 10 * 24 * 60 * 60 ) );
	},
	'Search events for last 10 days.',
);

ok(
	defined( $response ),
	'Response was received.'
);

ok(
	Data::Validate::Type::is_arrayref( $response ),
	'Response is an arrayref.',
);


ok(
	open( FILE, '>', 'webservice-datadog-events-eventid.tmp'),
	'Open temp file to store event id'
);

# Print first ID number to a text file, to use in other tests
my $first_event_id = defined $response->[0] && $response->[0]->{'id'}
 ? $response->[0]->{'id'}
 : '';
print FILE $first_event_id;

ok(
	close FILE,
	'Close temp file'
);
