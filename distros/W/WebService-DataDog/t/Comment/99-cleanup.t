#!perl -T

use strict;
use warnings;

use Test::Most 'bail', tests => 1;

SKIP:
{
	skip( 'Temporary comment id file does not exist.', 1 )
		if ! -e 'webservice-datadog-comment-commentid.tmp';

	ok(
		unlink( 'webservice-datadog-comment-commentid.tmp' ),
		'Remove temporary comment id file.',
	);
}

