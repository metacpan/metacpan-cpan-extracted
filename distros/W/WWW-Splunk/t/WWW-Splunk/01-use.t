use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('WWW::Splunk');
}

# Test.
require_ok('WWW::Splunk');
