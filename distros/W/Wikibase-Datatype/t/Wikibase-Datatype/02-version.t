use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype;

# Test.
is($Wikibase::Datatype::VERSION, 0.08, 'Version.');
