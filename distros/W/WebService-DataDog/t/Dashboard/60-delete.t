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
		$response = $dashboard_obj->delete( id => "abc" );
	},
	qr/id must be a number/,
	'Dies on invalid dash id.',
);

throws_ok(
	sub
	{
		$response = $dashboard_obj->delete( id => "123" );
	},
	qr/Error 404/,
	'Dies on unknown dash id.',
);

ok(
	open( FILE, 'webservice-datadog-dashboard-dashid-deprecated.tmp'),
	'Open temp file to read dashboard id - deprecated'
);

my $dash_id;

ok(
	$dash_id = do { local $/; <FILE> },
	'Read in dashboard id - deprecated'
);

ok(
	close FILE,
	'Close temp file - deprecated version'
);


lives_ok(
	sub
	{
		$dashboard_obj->delete_dashboard( id => $dash_id );
	},
	'Delete specified dashboard - deprecated version'
);

ok(                                                                             
  open( FILE, 'webservice-datadog-dashboard-dashid.tmp'),                       
  'Open temp file to read dashboard id'                                         
);

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
    $dashboard_obj->delete( id => $dash_id );                                   
  },                                                                            
  'Delete specified dashboard'                                                  
);
