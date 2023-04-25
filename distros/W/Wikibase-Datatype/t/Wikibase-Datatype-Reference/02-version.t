use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Reference;

# Test.
is($Wikibase::Datatype::Reference::VERSION, 0.29, 'Version.');
