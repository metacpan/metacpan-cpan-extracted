use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Print::Item;

# Test.
is($Wikibase::Datatype::Print::Item::VERSION, 0.16, 'Version.');
