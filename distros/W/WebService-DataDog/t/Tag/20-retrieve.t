#!perl -T

use strict;
use warnings;

use Data::Dumper;

use Data::Validate::Type;
use Test::Exception;
use Test::Most 'bail';

use WebService::DataDog;

my $skip_condition = 0;
my $skip_reason;

eval 'use DataDogConfig';
if ( $@ )
{
	$skip_reason = 'Local connection information for DataDog required to run tests.';
}

if ( ! -e 'webservice-datadog-tag-host.tmp' )
{
	$skip_condition = 1;
	$skip_reason = 'No tags found for the configured account.';
}

if ($skip_condition)
{
	plan skip_all => $skip_reason;
}
else {
	plan tests => 10;
}

my $config = DataDogConfig->new();

# Create an object to communicate with DataDog
my $datadog = WebService::DataDog->new( %$config );
ok(
	defined( $datadog ),
	'Create a new WebService::DataDog object.',
);


my $tag_obj = $datadog->build('Tag');
ok(
	defined( $tag_obj ),
	'Create a new WebService::DataDog::Tag object.',
);
my $response;


throws_ok(
	sub
	{
		$response = $tag_obj->retrieve();
	},
	qr/Argument.*required/,
	'Dies on missing required argument.',
);

dies_ok(
	sub
	{
		$response = $tag_obj->retrieve( host => "abc123" );
	},
	'Dies on invalid host.',
);

ok(
	open( FILE, 'webservice-datadog-tag-host.tmp'),
	'Open temp file containing a hostname.'
);

my $host_id;
ok(
	$host_id = do { local $/; <FILE> },
	'Read in host id.'
);

ok(
	close FILE,
	'Close temp file.'
);

lives_ok(
	sub
	{
		$response = $tag_obj->retrieve( host => $host_id );
	},
	'Request list of tags for a specific host.',
);

ok(
	defined( $response ),
	'Response was received.'
);

ok(
	Data::Validate::Type::is_arrayref( $response ),
	'Response is an arrayref.',
) || diag explain $response;

