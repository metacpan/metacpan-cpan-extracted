use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::API;

# Test.
is($Wikibase::API::VERSION, 0.07, 'Version.');
