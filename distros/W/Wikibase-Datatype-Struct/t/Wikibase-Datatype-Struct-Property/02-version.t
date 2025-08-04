use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Struct::Property;

# Test.
is($Wikibase::Datatype::Struct::Property::VERSION, 0.15, 'Version.');
