use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Struct::Item;

# Test.
is($Wikibase::Datatype::Struct::Item::VERSION, 0.11, 'Version.');
