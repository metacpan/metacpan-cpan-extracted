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


my $user_obj = $datadog->build('User');
ok(
	defined( $user_obj ),
	'Create a new WebService::DataDog::User object.',
);
my $response;


throws_ok(
	sub
	{
		$response = $user_obj->invite();
	},
	qr/Argument.*required/,
	'Dies on missing required argument.',
);

throws_ok(
	sub
	{
		$response = $user_obj->invite( emails => 'user@email.com' );
	},
	qr/emails.*Must be an arrayref/,
	'Dies on invalid invite list (non arrayref).',
);

lives_ok(
	sub
	{
		$response = $user_obj->invite( emails => [ 'user@email.com', 'user2@email.com' ] );
	},
	'Invite test users.',
);

ok(
	defined( $response ),
	'Response was received.'
);

ok(
	Data::Validate::Type::is_hashref( $response ),
	'Response is an hashref.',
) || diag explain $response;
