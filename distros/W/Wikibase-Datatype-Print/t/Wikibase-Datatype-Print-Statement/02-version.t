use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Print::Statement;

# Test.
is($Wikibase::Datatype::Print::Statement::VERSION, 0.08, 'Version.');
