use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Struct::Statement;

# Test.
is($Wikibase::Datatype::Struct::Statement::VERSION, 0.13, 'Version.');
