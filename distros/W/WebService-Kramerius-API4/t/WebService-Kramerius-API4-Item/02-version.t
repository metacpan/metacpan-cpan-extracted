use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use WebService::Kramerius::API4::Item;

# Test.
is($WebService::Kramerius::API4::Item::VERSION, 0.02, 'Version.');
