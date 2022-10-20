use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Languages;

# Test.
is($Wikibase::Datatype::Languages::VERSION, 0.22, 'Version.');
