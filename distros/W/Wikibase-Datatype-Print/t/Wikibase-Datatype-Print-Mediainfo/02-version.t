use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Print::Mediainfo;

# Test.
is($Wikibase::Datatype::Print::Mediainfo::VERSION, 0.19, 'Version.');
