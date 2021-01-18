use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Struct::Utils;

# Test.
is($Wikibase::Datatype::Struct::Utils::VERSION, 0.06, 'Version.');
