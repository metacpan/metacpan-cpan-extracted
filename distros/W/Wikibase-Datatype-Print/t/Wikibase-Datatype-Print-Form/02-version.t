use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Print::Form;

# Test.
is($Wikibase::Datatype::Print::Form::VERSION, 0.12, 'Version.');
