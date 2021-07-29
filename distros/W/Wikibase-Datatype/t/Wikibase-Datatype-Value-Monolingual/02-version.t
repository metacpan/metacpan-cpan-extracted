use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Value::Monolingual;

# Test.
is($Wikibase::Datatype::Value::Monolingual::VERSION, 0.1, 'Version.');
