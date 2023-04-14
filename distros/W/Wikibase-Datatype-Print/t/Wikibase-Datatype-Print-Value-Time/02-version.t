use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Print::Value::Time;

# Test.
is($Wikibase::Datatype::Print::Value::Time::VERSION, 0.04, 'Version.');
