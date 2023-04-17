use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Print::Property;

# Test.
is($Wikibase::Datatype::Print::Property::VERSION, 0.07, 'Version.');
