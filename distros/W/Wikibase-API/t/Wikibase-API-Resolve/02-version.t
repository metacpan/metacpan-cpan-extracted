use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::API::Resolve;

# Test.
is($Wikibase::API::Resolve::VERSION, 0.05, 'Version.');
