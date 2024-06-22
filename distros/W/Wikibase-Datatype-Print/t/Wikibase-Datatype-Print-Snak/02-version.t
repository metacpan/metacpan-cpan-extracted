use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Print::Snak;

# Test.
is($Wikibase::Datatype::Print::Snak::VERSION, 0.17, 'Version.');
