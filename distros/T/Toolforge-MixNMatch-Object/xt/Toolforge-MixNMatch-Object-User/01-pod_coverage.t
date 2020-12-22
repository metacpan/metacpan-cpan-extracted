use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Toolforge::MixNMatch::Object::User',
	{ 'also_private' => ['BUILD'] },
	'Toolforge::MixNMatch::Object::User is covered.');
