use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Print::Sense;

# Test.
is($Wikibase::Datatype::Print::Sense::VERSION, 0.08, 'Version.');
