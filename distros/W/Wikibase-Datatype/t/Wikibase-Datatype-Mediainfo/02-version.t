use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Mediainfo;

# Test.
is($Wikibase::Datatype::Mediainfo::VERSION, 0.36, 'Version.');
