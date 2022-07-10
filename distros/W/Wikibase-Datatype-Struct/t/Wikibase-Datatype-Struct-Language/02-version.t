use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Struct::Language;

# Test.
is($Wikibase::Datatype::Struct::Language::VERSION, 0.09, 'Version.');
