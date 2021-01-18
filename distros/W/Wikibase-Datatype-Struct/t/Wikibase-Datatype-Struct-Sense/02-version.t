use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Struct::Sense;

# Test.
is($Wikibase::Datatype::Struct::Sense::VERSION, 0.06, 'Version.');
