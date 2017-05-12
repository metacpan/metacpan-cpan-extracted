#!perl -T

use strict;
use warnings;

use Test::Most 'bail', tests => 1;

SKIP:
{
	skip( 'Temporary tag host id file does not exist.', 1 )
		if ! -e 'webservice-datadog-tag-host.tmp';

	ok(
		unlink( 'webservice-datadog-tag-host.tmp' ),
		'Remove temporary host id file.',
	);
}

