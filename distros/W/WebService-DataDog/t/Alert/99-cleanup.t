#!perl -T

use strict;
use warnings;

use Test::Most tests => 1;

SKIP:
{
	skip( 'Temporary alert id file does not exist.', 1 )
		if ! -e 'webservice-datadog-alert-alertid.tmp';

	ok(
		unlink( 'webservice-datadog-alert-alertid.tmp' ),
		'Remove temporary alert id file.',
	);
}

