#!perl -T

use strict;
use warnings;

use Data::Dumper;

use Data::Validate::Type;
use Scalar::Util qw();
use Storable qw();
use Test::Exception;
use Test::Most;

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

ok(
	defined(
		my $datadog_copy = Storable::dclone( $datadog )
	),
	'Copy the datadog object for later comparison.',
);

my $dashboard_obj;
lives_ok(
	sub
	{
		$dashboard_obj = $datadog->build('Dashboard');
		
		die 'build() returned undef'
			if !defined( $dashboard_obj );
	},
	'Build WebService::DataDog::Dashboard object.',
);

isa_ok(
	$dashboard_obj,
	'WebService::DataDog::Dashboard',
	'The object returned by build()',
) || diag( explain( $dashboard_obj ) );

isnt(
	Scalar::Util::refaddr( $datadog ),
	Scalar::Util::refaddr( $dashboard_obj ),
	'The datadog object and the dashboard object are distinct objects.',
);

is_deeply(
	$datadog,
	$datadog_copy,
	'The datadog object was unaffected by build().',
) || diag( explain( $datadog ) );

