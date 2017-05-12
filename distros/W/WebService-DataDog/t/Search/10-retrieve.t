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
	: plan( tests => 7 );

my $config = DataDogConfig->new();

# Create an object to communicate with DataDog
my $datadog = WebService::DataDog->new( %$config );
ok(
	defined( $datadog ),
	'Create a new WebService::DataDog object.',
);


my $search_obj = $datadog->build('Search');
ok(
	defined( $search_obj ),
	'Create a new WebService::DataDog::Search object.',
);
my $response;


throws_ok(
	sub
	{
		$response = $search_obj->retrieve();
	},
	qr/Argument.*required/,
	'Dies on missing required argument.',
);

throws_ok(
	sub
	{
		$response = $search_obj->retrieve( term => 'web', facet => "abc123" );
	},
	qr/Invalid facet type/,
	'Dies on invalid search facet.',
);

lives_ok(
	sub
	{
		$response = $search_obj->retrieve( term => 'test' );
	},
	'Search for a term without a facet.',
);

ok(
	defined( $response ),
	'Response was received.'
);

ok(
	Data::Validate::Type::is_hashref( $response ),
	'Response is an hashref.',
) || diag explain $response;

