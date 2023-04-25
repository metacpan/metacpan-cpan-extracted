use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Struct::Value::String;

# Test.
is($Wikibase::Datatype::Struct::Value::String::VERSION, 0.11, 'Version.');
