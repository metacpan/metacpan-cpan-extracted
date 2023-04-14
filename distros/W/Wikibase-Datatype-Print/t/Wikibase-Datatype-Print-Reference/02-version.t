use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Print::Reference;

# Test.
is($Wikibase::Datatype::Print::Reference::VERSION, 0.04, 'Version.');
