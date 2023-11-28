use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('WebService::Kramerius::API4::AsyncPDF', 'WebService::Kramerius::API4::AsyncPDF is covered.');
