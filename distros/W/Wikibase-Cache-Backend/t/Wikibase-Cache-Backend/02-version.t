use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Cache::Backend;

# Test.
is($Wikibase::Cache::Backend::VERSION, 0.03, 'Version.');
