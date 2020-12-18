use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Struct::Value::Time;

# Test.
is($Wikibase::Datatype::Struct::Value::Time::VERSION, 0.04, 'Version.');
