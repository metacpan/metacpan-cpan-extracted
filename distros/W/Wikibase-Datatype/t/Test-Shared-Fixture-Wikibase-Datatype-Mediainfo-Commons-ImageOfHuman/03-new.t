use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Mediainfo::Commons::ImageOfHuman;

# Test.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::Mediainfo::Commons::ImageOfHuman->new;
isa_ok($obj, 'Test::Shared::Fixture::Wikibase::Datatype::Mediainfo::Commons::ImageOfHuman');
