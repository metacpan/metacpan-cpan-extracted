#!perl -T

use strict;
use warnings;

use Data::Dumper;

use Test::Exception;
use Test::Most 'bail';

use WebService::DataDog;


eval 'use DataDogConfig';
$@
	? plan( skip_all => 'Local connection information for DataDog required to run tests.' )
	: plan( tests => 20 );

my $config = DataDogConfig->new();

# Create an object to communicate with DataDog
my $datadog = WebService::DataDog->new( %$config );
ok(
	defined( $datadog ),
	'Create a new WebService::DataDog object.',
);

my $metric_obj = $datadog->build('Metric');
ok(
	defined( $metric_obj ),
	'Create a new WebService::DataDog::Metric object.',
);

isa_ok(
	$metric_obj,
	'WebService::DataDog::Metric',
	'Validated object instance of WebService::DataDog::Metric.',
)|| diag( explain( $metric_obj ) );


throws_ok(
	sub
	{
		$metric_obj->emit(
		);
	},
	qr/Argument.*is required/,
	'post metric - dies without any required arguments.',
);

throws_ok(
	sub
	{
		$metric_obj->emit(
			name  => 'testmetric.test_gauge',
		);
	},
	qr/for single data points, or argument 'data_points'/,
	'post metric - dies without required argument "value" OR "data_points".',
);

throws_ok(
	sub
	{
		$metric_obj->emit(
			name        => 'testmetric.test_gauge',
			value       => 42,
			data_points => [ [ ( time() - 100 ), 3.41 ] ],
		);
	},
	qr/Both arguments are not allowed/,
	'post metric - dies with argument "value" AND "data_points".',
);

throws_ok(
	sub
	{
		$metric_obj->emit(
			name        => '1testmetric.test_gauge',
			value       => 42,
		);
	},
	qr/nvalid metric name/,
	'post metric - dies with metric name invalid.',
);

throws_ok(
	sub
	{
		$metric_obj->emit(
			name        => 'testmetric.test_gauge',
			value       => "a4b2",
		);
	},
	qr/Value.*is not a number/,
	'post metric - dies with metric value (single datapoint) invalid.',
);

throws_ok(
	sub
	{
		$metric_obj->emit(
			name        => 'testmetric.test_gauge',
			data_points => ( [ time(), "abc" ] ),
		);
	},
	qr/'data_points'.*must be an arrayref/,
	'post metric - dies with invalid "data_points" argument.',
);

throws_ok(
	sub
	{
		$metric_obj->emit(
			name        => 'testmetric.test_gauge',
			data_points => [ [ time(), "abc" ] ],
		);
	},
	qr/invalid value.*in data_points/,
	'post metric - dies with single data point, invalid value.',
);

throws_ok(
	sub
	{
		$metric_obj->emit(
			name        => 'testmetric.test_gauge',
			data_points => [ [ 12345, 3.41 ] ],
		);
	},
	qr/invalid timestamp/,
	'post metric - dies with single data point, invalid timestamp.',
);


# This is a non-standard check, DataDog will allow it, but it will result in confusion and unusual behavior in UI/graphing
throws_ok(
	sub {
		$metric_obj->emit(
			name  => 'testmetric.test_gauge',
			value => 42,
			tags  => [ 'tag:something:value' ],
		);
	},
	qr/Tags should only contain a single colon/,
	'post metric - dies with tag list with invalid item - two colons.',
);


throws_ok(
	sub {
		$metric_obj->emit(
			name  => 'testmetric.test_gauge',
			value => 42,
			tags  => {},
		);
	},
	qr/nvalid 'tags'.*Must be an arrayref/,
	'post metric - dies with invalid tag list, not an arrayref.',
);


throws_ok(
	sub {
		$metric_obj->emit(
			name  => 'testmetric.test_gauge',
			value => 42,
			tags  => [ '1tag:something' ],
		);
	},
	qr/Tags must start with a letter/,
	'post metric - dies with tag list with invalid item - tag starting with number',
);

throws_ok(
	sub {
		$metric_obj->emit(
			name  => 'testmetric.test_gauge',
			value => 42,
			tags  => [ 'tagabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz:value' ],
		);
	},
	qr/Tags must be 200 characters or less/,
	'post metric - dies with tag list with invalid item - tag > 200 characters',
);


lives_ok(
	sub
	{
		$metric_obj->post_metric(
			name  => 'testmetric.test_gauge',
			value => 42
		);
	},
	'post metric - deprecated version - single data point, no timestamp.',
)|| diag( explain( $metric_obj ) );

lives_ok(
	sub
	{
		$metric_obj->emit(
			name  => 'testmetric.test_gauge',
			value => 42
		);
	},
	'post metric - single data point, no timestamp.',
)|| diag( explain( $metric_obj ) );

lives_ok(
	sub
	{
		$metric_obj->emit(
			name        => 'testmetric.test_gauge',
			data_points => [ [ ( time() - 100 ), 3.41 ] ],
		);
	},
	'post metric - single data point, with timestamp in past.',
)|| diag( explain( $metric_obj ) );


lives_ok(
	sub
	{
		$metric_obj->emit(
			name        => 'testmetric.test_gauge',
			data_points => [
				[ ( time() - 100 ), 2.71828 ],
				[ ( time() ), 3.41 ],
				[ ( time() - 50 ), 47 ],
			],
		);
	},
	'post metric - multiple data points.',
)|| diag( explain( $metric_obj ) );

lives_ok(
	sub
	{
		$metric_obj->emit(
			name  => 'testmetric.test_gauge',
			value => 3.41,
			host  => 'test-host',
			tags  => [ 'dev', 'env:testing' ],
		);
	},
	'post metric - single data point, with host and tags.',
)|| diag( explain( $metric_obj ) );

