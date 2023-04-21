use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Form;

# Test.
is($Wikibase::Datatype::Form::VERSION, 0.26, 'Version.');
