use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::MediainfoSnak::Commons::Depicts::Human;

# Test.
is($Test::Shared::Fixture::Wikibase::Datatype::MediainfoSnak::Commons::Depicts::Human::VERSION, 0.36, 'Version.');
