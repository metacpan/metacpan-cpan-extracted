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


my $graph_obj = $datadog->build('Graph');
ok(
	defined( $graph_obj ),
	'Create a new WebService::DataDog::Graph object.',
);

my $response;

throws_ok(
	sub
	{
		$response = $graph_obj->snapshot();
	},
	qr/Argument.*required/,
	'Dies without required arguments',
);


throws_ok(
	sub
	{
		$response = $graph_obj->snapshot(
			metric_query     => "system.load.1{*}",
			start            => "abcd",
			end              => 12345
		);
	},
	qr/'start' must be an integer/,
	'Dies on invalid start time',
);


throws_ok(
	sub
	{
		$response = $graph_obj->snapshot(
			metric_query     => "system.load.1{*}",
			start            => 12345,
			end              => "abcd"
		);
	},
	qr/'end' must be an integer/,
	'Dies on invalid end time',
);


lives_ok(
	sub
	{
		my $now_ish = time() - 10000;
		
		$response = $graph_obj->snapshot(
			metric_query     => "system.load.1{*}",
			start            => $now_ish - 86400,
			end              => $now_ish
		);
	},
	'Create snapshot.',
)|| diag explain $response;

ok(
	Data::Validate::Type::is_string( $response ),
	'Response is a string.',
);


