use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Cache::Backend;

# Test.
my $obj = Wikibase::Cache::Backend->new;
isa_ok($obj, 'Wikibase::Cache::Backend');
