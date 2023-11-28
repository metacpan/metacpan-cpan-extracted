use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use WebService::Kramerius::API4::Rights;

# Test.
is($WebService::Kramerius::API4::Rights::VERSION, 0.02, 'Version.');
