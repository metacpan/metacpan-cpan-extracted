use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Cache::Backend::Basic;

# Test.
my $obj = Wikibase::Cache::Backend::Basic->new;
isa_ok($obj, 'Wikibase::Cache::Backend::Basic');
