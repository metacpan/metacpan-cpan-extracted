use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Struct::Value;

# Test.
is($Wikibase::Datatype::Struct::Value::VERSION, 0.09, 'Version.');
