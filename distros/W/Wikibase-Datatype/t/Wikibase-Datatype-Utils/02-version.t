use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Utils;

# Test.
is($Wikibase::Datatype::Utils::VERSION, 0.21, 'Version.');
