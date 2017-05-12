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
	: plan( tests => 9 );

my $config = DataDogConfig->new();

# Update an object to communicate with DataDog
my $datadog = WebService::DataDog->new( %$config );
ok(
	defined( $datadog ),
	'Update a new WebService::DataDog object.',
);


my $alert_obj = $datadog->build('Alert');
ok(
	defined( $alert_obj ),
	'Update a new WebService::DataDog::Alert object.',
);



my $alert_id;
ok(
	open( FILE, 'webservice-datadog-alert-alertid.tmp'),
	'Open temp file to read alert id'
);

ok(
	$alert_id = do { local $/; <FILE> },
	'Read in alert id'
);

ok(
	close FILE,
	'Close temp file'
);

my $response;

throws_ok(
	sub
	{
		$response = $alert_obj->update();
	},
	qr/Argument.*required/,
	'Dies without required arguments',
);


throws_ok(
	sub
	{
		$response = $alert_obj->update(
			id      => $alert_id,
			query   => "sum(last_1d):sum:system.net.bytes_rcvd{host:host0} > 200",
			name    => "ABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZABC",
		);
	},
	qr/invalid 'name'.*80 char/,
	'Dies on name > 80 characters',
)|| diag explain $response;


throws_ok(
	sub
	{
		$response = $alert_obj->update(
			id       => $alert_id,
			query   => "sum(last_1d):sum:system.net.bytes_rcvd{host:host0} > 200",
			silenced => 'yup',
		);
	},
	qr/invalid 'silenced' value/,
	'Dies on non-boolean "silenced" value',
)|| diag explain $response;


lives_ok(
	sub
	{
		$response = $alert_obj->update(
			id       => $alert_id,
			query    => "sum(last_1d):sum:system.net.bytes_rcvd{host:host0} > 100",
			message  => "Unit test for WebService::DataDog -- Updated message goes here",
			silenced => 1,
		);
	},
	'Update existing alert',
)|| diag explain $response;	
