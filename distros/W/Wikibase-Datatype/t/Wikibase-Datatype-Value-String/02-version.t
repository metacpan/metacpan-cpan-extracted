use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Value::String;

# Test.
is($Wikibase::Datatype::Value::String::VERSION, 0.07, 'Version.');
