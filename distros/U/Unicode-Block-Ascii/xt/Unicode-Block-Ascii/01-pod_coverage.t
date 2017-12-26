use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Unicode::Block::Ascii', 'Unicode::Block::Ascii is covered.');
