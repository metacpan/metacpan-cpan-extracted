#!perl -T

use strict;
use warnings;

use Data::Dumper;

use Test::Exception;
use Test::Most 'bail';

use WebService::DataDog;


eval 'use DataDogConfig';
$@
	? plan( skip_all => 'Local connection information for DataDog required to run tests.' )
	: plan( tests => 16 );

my $config = DataDogConfig->new();

# Create an object to communicate with DataDog
my $datadog = WebService::DataDog->new( %$config );
ok(
	defined( $datadog ),
	'Create a new WebService::DataDog object.',
);


my $event_obj = $datadog->build('Event');
ok(
	defined( $event_obj ),
	'Create a new WebService::DataDog::Event object.',
);
my $response;


throws_ok(
	sub
	{
		$response = $event_obj->create();
	},
	qr/Argument.*required/,
	'Dies on missing arguments.',
);

throws_ok(
	sub
	{
		$response = $event_obj->create( title => "abc" );
	},
	qr/Argument.*text.*required/,
	'Dies on blank/missing "text" argument.',
);

throws_ok(
	sub
	{
		$response = $event_obj->create(
			text => "yadda yadda",
			title => "",
		);
	},
	qr/Argument.*title.*required/,
	'Dies on blank/missing "title" argument.',
);

throws_ok(
	sub
	{
		$response = $event_obj->create(
			title => "yadda",
			text  => "",
		);
	},
	qr/Argument.*text.*required/,
	'Dies on blank/missing "text" argument.',
);

throws_ok(
	sub
	{
		$response = $event_obj->create(
			text  => "Something something something",
			title => "TESTTITLETESTTITLETESTTITLETESTTITLETESTTITLE-ABCDEFGHIJKLMNOPQRSTUVWXYZ-ABCDEFGHIJKLMNOPQRSTUVWXYZ123",
		);
	},
	qr/nvalid 'title'.*100/,
	'Dies on title > 100 chars',
);

throws_ok(
	sub
	{
		$response = $event_obj->create(
			title           => "title goes here",
			text            => "Text goes here",
			date_happened   => "abc",
		);
	},
	qr/nvalid 'date_happened'.*POSIX/,
	'Dies on invalid "date_happened".',
);


throws_ok(
	sub
	{
		$response = $event_obj->create(
			title    => "title goes here",
			text     => "Text goes here",
			priority => "nuclear",
		);
	},
	qr/nvalid.*'priority'/,
	'Dies on invalid priority.',
);

throws_ok(
	sub
	{
		$response = $event_obj->create(
			title            => "title goes here",
			text             => "Text goes here",
			related_event_id => "abc",
		);
	},
	qr/nvalid 'related_event_id'/,
	'Dies on invalid related_event_id.',
);

throws_ok(
	sub
	{
		$response = $event_obj->create(
			title => "title goes here",
			text  => "Text goes here",
			tags  => "tags_go_here",
		);
	},
	qr/nvalid 'tags'.*arrayref/,
	'Dies on invalid tag list.',
);

throws_ok(
	sub
	{
		$response = $event_obj->create(
			title      => "title goes here(" . time() . ")",
			text       => "Text goes here",
			alert_type => "kabooom",
		);
	},
	qr/nvalid 'alert_type'/,
	'Dies on invalid alert_type.',
);

throws_ok(
	sub
	{
		$response = $event_obj->create(
			title            => "title goes here(" . time() . ")",
			text             => "Text goes here",
			source_type_name => "Portal 2",
		);
	},
	qr/nvalid 'source_type_name'/,
	'Dies on invalid source_type_name.',
);


lives_ok(
	sub
	{
		$response = $event_obj->post_event(
			title      => "title goes here(" . time() . ")",
			text       => "Text goes here",
		);
	},
	'Post valid event to stream - deprecated version.',
);

lives_ok(
	sub
	{
		$response = $event_obj->create(
			title      => "title goes here(" . time() . ")",
			text       => "Text goes here",
		);
	},
	'Post valid event to stream - [ title, text ].',
);

lives_ok(
	sub
	{
		$response = $event_obj->create(
			title            => "Unit test for WebService::DataDog::Event -- title goes here(" . time() . ")",
			text             => "Text goes here",
			date_happened    => '1370663582',
			priority         => 'low',
			source_type_name => 'jenkins',
			alert_type       => 'info',
		);
	},
	'Post valid event to stream - [ title, text, date_happened, priority, source_rtype_name, alert_type ].',
);


