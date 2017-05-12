# Pragmas.
use strict;
use warnings;

# Modules.
use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('WWW::Search::Antikvariat11CZ', 'WWW::Search::Antikvariat11CZ is covered.');
