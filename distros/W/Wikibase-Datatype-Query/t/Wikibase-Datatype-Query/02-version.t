use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Query;

# Test.
is($Wikibase::Datatype::Query::VERSION, 0.03, 'Version.');
