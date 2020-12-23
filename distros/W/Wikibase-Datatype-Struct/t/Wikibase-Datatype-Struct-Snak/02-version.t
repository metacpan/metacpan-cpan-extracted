use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Struct::Snak;

# Test.
is($Wikibase::Datatype::Struct::Snak::VERSION, 0.05, 'Version.');
