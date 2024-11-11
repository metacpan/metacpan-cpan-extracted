use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Struct::Mediainfo;

# Test.
is($Wikibase::Datatype::Struct::Mediainfo::VERSION, 0.13, 'Version.');
