use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Sense;

# Test.
is($Wikibase::Datatype::Sense::VERSION, 0.11, 'Version.');
