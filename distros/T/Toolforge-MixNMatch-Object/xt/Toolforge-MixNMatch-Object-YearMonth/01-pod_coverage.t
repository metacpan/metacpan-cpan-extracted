use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Toolforge::MixNMatch::Object::YearMonth',
	{ 'also_private' => ['BUILD'] },
	'Toolforge::MixNMatch::Object::YearMonth is covered.');
