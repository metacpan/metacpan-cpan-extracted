use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Struct::Form;

# Test.
is($Wikibase::Datatype::Struct::Form::VERSION, 0.08, 'Version.');
