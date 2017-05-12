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


my $dashboard_obj = $datadog->build('Dashboard');
ok(
	defined( $dashboard_obj ),
	'Create a new WebService::DataDog::Dashboard object.',
);
my $response;


throws_ok(
	sub
	{
		$response = $dashboard_obj->retrieve( );
	},
	qr/Argument.*required/,
	'Dies on missing dash id argument.',
);

throws_ok(
	sub
	{
		$response = $dashboard_obj->retrieve( id => "abc" );
	},
	qr/id must be a number/,
	'Dies on invalid dash id.',
);

throws_ok(
	sub
	{
		$response = $dashboard_obj->retrieve( id => "123" );
	},
	qr/Unknown dash/,
	'Dies on unknown dash id.',
);


ok(
	open( FILE, 'webservice-datadog-dashboard-dashid.tmp'),
	'Open temp file to read dashboard id'
);

my $dash_id;

ok(
	$dash_id = do { local $/; <FILE> },
	'Read in dashboard id'
);

ok(
	close FILE,
	'Close temp file'
);

lives_ok(                                                                       
  sub                                                                           
  {                                                                             
    $response = $dashboard_obj->get_dashboard( id => $dash_id );                     
  },                                                                            
  'Request info on specific dashboard - deprecated version.',                                        
);

lives_ok(
	sub
	{
		$response = $dashboard_obj->retrieve( id => $dash_id );
	},
	'Request info on specific dashboard.',
);

ok(
	defined( $response ),
	'Response was received.'
);

ok(
	Data::Validate::Type::is_hashref( $response ),
	'Response is a hashref.',
);

