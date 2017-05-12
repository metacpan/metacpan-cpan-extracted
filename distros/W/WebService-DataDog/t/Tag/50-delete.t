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
	plan tests => 7;
}

my $config = DataDogConfig->new();

# Update an object to communicate with DataDog
my $datadog = WebService::DataDog->new( %$config );
ok(
	defined( $datadog ),
	'Update a new WebService::DataDog object.',
);


my $tag_obj = $datadog->build('Tag');
ok(
	defined( $tag_obj ),
	'Update a new WebService::DataDog::Tag object.',
);



my $host;
ok(
	open( FILE, 'webservice-datadog-tag-host.tmp'),
	'Open temp file to read host.'
);

ok(
	$host = do { local $/; <FILE> },
	'Read in host name/id.'
);

ok(
	close FILE,
	'Close temp file.'
);

my $response;

throws_ok(
	sub
	{
		$response = $tag_obj->delete();
	},
	qr/Argument.*required/,
	'Dies without required arguments',
);

lives_ok(
	sub
	{
		$response = $tag_obj->delete(
			host => $host,
		);
	},
	'Remove all tags from the specified host.',
)|| diag explain $response;
