use strict;
use warnings;

use WebService::Kramerius::API4;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($WebService::Kramerius::API4::VERSION, 0.01, 'Version.');
