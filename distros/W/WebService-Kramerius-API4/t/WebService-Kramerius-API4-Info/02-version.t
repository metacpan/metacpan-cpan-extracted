use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use WebService::Kramerius::API4::Info;

# Test.
is($WebService::Kramerius::API4::Info::VERSION, 0.02, 'Version.');
