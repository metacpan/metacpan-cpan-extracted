use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Value::Sense;

# Test.
is($Wikibase::Datatype::Value::Sense::VERSION, 0.34, 'Version.');
