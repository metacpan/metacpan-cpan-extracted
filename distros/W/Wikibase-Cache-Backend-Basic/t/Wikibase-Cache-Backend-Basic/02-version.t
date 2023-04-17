use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Cache::Backend::Basic;

# Test.
is($Wikibase::Cache::Backend::Basic::VERSION, 0.03, 'Version.');
