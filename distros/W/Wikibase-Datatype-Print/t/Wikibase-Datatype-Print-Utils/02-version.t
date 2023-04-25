use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Print::Utils;

# Test.
is($Wikibase::Datatype::Print::Utils::VERSION, 0.12, 'Version.');
