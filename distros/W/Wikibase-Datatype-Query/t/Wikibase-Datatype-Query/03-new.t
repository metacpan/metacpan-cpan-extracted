use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Query;

# Test.
my $obj = Wikibase::Datatype::Query->new;
isa_ok($obj, 'Wikibase::Datatype::Query');
