use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Print::Texts;

# Test.
is($Wikibase::Datatype::Print::Texts::VERSION, 0.17, 'Version.');
