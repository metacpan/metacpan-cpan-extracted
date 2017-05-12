#!/usr/bin/perl

use strict;
use warnings;

use WebService::DataDog;

my $datadog = WebService::DataDog->new(
	api_key         => 'YOUR_API_KEY',
	application_key => 'YOUR_APP_KEY',
#	verbose         => 1,
);

my $comment = $datadog->build('Comment');

# Create new comment/Start new comment thread
$comment->create(
	message => 'Message text goes here.'
);

# Create a new comment, in reply to an existing comment
$comment->create(
	message          => 'Message reply goes here.',
	related_event_id => 1234567890,
);

# Update an existing comment
$comment->update(
	message    => 'Updated message goes here.',
	comment_id => 1234567890,
);

# Remove existing comment
$comment->delete(
	comment_id => 1234567890,
);
