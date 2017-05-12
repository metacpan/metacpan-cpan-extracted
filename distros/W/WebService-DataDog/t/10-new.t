#!perl -T

use strict;
use warnings;

use Test::More tests => 1;

use WebService::DataDog;


# Create an object to communicate with DataDog.
my $datadog = WebService::DataDog->new(
		api_key         => 'XXXXXXXX',
		application_key => 'XXXXXXXXXXXXXXXXXXXXXXXXX',
);

isa_ok(
	$datadog, 'WebService::DataDog',
	'Return value of WebService::DataDog->new()',
) || diag( explain( $datadog ) );

