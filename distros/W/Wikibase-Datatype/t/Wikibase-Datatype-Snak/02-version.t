use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Snak;

# Test.
is($Wikibase::Datatype::Snak::VERSION, 0.1, 'Version.');
