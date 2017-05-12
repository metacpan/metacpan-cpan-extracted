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

my $comment_obj = $datadog->build('Comment');
ok(
	defined( $comment_obj ),
	'Create a new WebService::DataDog::Comment object.',
);

my $response;

throws_ok(
	sub
	{
		$response = $comment_obj->delete();
	},
	qr/Argument.*required/,
	'Dies without required argument "comment_id"',
);


ok(
	open( FILE, 'webservice-datadog-comment-commentid.tmp'),
	'Open temp file to read comment id'
);

my $comment_id;

ok(
	$comment_id = do { local $/; <FILE> },
	'Read in comment id'
);

ok(
	close FILE,
	'Close temp file'
);

lives_ok(
	sub
	{
		$response = $comment_obj->delete( comment_id => $comment_id );
	},
	'Delete existing comment.',
)|| diag explain $response;

