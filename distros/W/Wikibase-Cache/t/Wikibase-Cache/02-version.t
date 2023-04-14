use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Cache;

# Test.
is($Wikibase::Cache::VERSION, 0.03, 'Version.');
