use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Value::Time;

# Test.
is($Wikibase::Datatype::Value::Time::VERSION, 0.08, 'Version.');
