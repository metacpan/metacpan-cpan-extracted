use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::MediainfoSnak::Commons::Depicts::Human;

# Test.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::MediainfoSnak::Commons::Depicts::Human->new;
isa_ok($obj, 'Test::Shared::Fixture::Wikibase::Datatype::MediainfoSnak::Commons::Depicts::Human');
