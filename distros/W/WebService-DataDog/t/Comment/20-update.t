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
	: plan( tests => 10 );

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
		$response = $comment_obj->update();
	},
	qr/Argument.*required/,
	'Dies without required arguments',
);


throws_ok(
	sub
	{
		$response = $comment_obj->update( message => 'test message' );
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
		$response = $comment_obj->update(
			message    => "Unit test for WebService::DataDog -- My edited message goes here",
			comment_id => $comment_id,
		);
	},
	'Test: Edit existing comment.',
)|| diag explain $response;

ok(
	Data::Validate::Type::is_hashref( $response ),
	'Response is a hashref.',
);

is(
	$response->{'id'},
	$comment_id,
	'Edited correct message.'
);


# Cannot get this test to work, even with known good comment id and alt_handle
# Returns "500 Internal Server Error"
#**    [CommentBlockStart     (April 11, 2015 8:42:38 PM EDT, jpinkham)
#**+----------------------------------------------------------------------
#**|my $config = DataDogConfig->new();
#**|my $alt_handle = $config->{'alt_handle'};
#**|lives_ok(
#**|	sub
#**|	{
#**|		$response = $comment_obj->update(
#**|			message    => "My edited, again, message goes here",
#**|			comment_id => $comment_id,
#**|			handle     => $alt_handle
#**|		);
#**|		
#**|	},
#**|	'Edit existing comment. Changing handle.',
#**|)|| diag explain $response;
#**+----------------------------------------------------------------------
#**    CommentBlockEnd]       (April 11, 2015 8:42:38 PM EDT, jpinkham)

