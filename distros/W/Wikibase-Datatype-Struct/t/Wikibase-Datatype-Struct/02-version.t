use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Struct;

# Test.
is($Wikibase::Datatype::Struct::VERSION, 0.04, 'Version.');
