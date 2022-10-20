use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Print::Value::String;

# Test.
is($Wikibase::Datatype::Print::Value::String::VERSION, 0.01, 'Version.');
