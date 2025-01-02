use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Property;

# Test.
is($Wikibase::Datatype::Property::VERSION, 0.36, 'Version.');
