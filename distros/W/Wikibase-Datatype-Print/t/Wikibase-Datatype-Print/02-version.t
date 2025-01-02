use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Print;

# Test.
is($Wikibase::Datatype::Print::VERSION, 0.18, 'Version.');
