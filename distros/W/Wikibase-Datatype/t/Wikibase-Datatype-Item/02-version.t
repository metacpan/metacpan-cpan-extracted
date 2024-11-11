use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Item;

# Test.
is($Wikibase::Datatype::Item::VERSION, 0.34, 'Version.');
