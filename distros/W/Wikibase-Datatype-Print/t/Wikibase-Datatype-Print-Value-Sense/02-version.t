use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Print::Value::Sense;

# Test.
is($Wikibase::Datatype::Print::Value::Sense::VERSION, 0.13, 'Version.');
