use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;
use Wikibase::Cache::Backend::Basic;

# Test.
my $obj = Wikibase::Cache::Backend::Basic->new;
my $ret = $obj->get('label', 'Q11573');
is($ret, 'metre', 'Get label for Q11573 (metre).');

# Test.
$ret = $obj->get('description', 'Q11573');
is($ret, 'SI unit of length', 'Get description for Q11573 (SI unit of length).');
