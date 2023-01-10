use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Mediainfo::Commons::ImageOfHuman;

# Test.
is($Test::Shared::Fixture::Wikibase::Datatype::Mediainfo::Commons::ImageOfHuman::VERSION, 0.24, 'Version.');
