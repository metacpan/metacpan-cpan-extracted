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
		$response = $comment_obj->create();
	},
	qr/Argument.*required/,
	'Dies without required arguments',
);


throws_ok(
	sub
	{
		$response = $comment_obj->create(
			message          => "testing comment 1 2 3",
			related_event_id => "abcd",
		);
	},
	qr/'related_event_id' must be an integer/,
	'Dies on invalid related event id',
);



lives_ok(
	sub
	{
		$response = $comment_obj->create(
			message          => "Unit test for WebService::DataDog -- Message goes here",
		);
	},
	'Create new comment - no related event.',
)|| diag explain $response;

ok(
	Data::Validate::Type::is_hashref( $response ),
	'Response is a hashref.',
);

my $event_id = $response->{'id'};

# Sometimes DataDog has a slight delay in recognizing new comments, and as a result
# it will fail to add a comment to a thread because it does not believe that the
# parent comment exists yet.  So we pause here before trying to create a thread.

sleep 2;

lives_ok(
	sub
	{
		$response = $comment_obj->create(
			message          => "Unit test for WebService::DataDog -- thread message goes here",
			related_event_id => $event_id,
		);
	},
	'Create new comment - specifying related event.',
)|| diag explain $response;


is(
	$response->{'related_event_id'},
	$event_id,
	'Comment added to existing thread.'
);


# Store id for use in upcoming tests

ok(
	open( FILE, '>', 'webservice-datadog-comment-commentid.tmp'),
	'Open temp file to store new comment URL'
);

print FILE $response->{'id'};

ok(
	close FILE,
	'Close temp file'
);
