use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('WWW::Splunk::API', 'WWW::Splunk::API is covered.');
