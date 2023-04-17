use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 5;
use Test::NoWarnings;
use Wikibase::Cache::Backend::Basic;

# Test.
my $obj = Wikibase::Cache::Backend::Basic->new;
my $ret = $obj->get('label', 'Q11573');
is($ret, 'metre', 'Get label for Q11573 (metre).');

# Test.
$ret = $obj->get('description', 'Q11573');
is($ret, 'SI unit of length', 'Get description for Q11573 (SI unit of length).');

# Test.
$ret = $obj->get('description', 'bad');
is($ret, undef, 'Get description for bad (undef).');

# Test.
eval {
	$obj->get('bad', 'Q11573');
};
is($EVAL_ERROR, "Type 'bad' isn't supported.\n", "Type 'bad' isn't supported.");
clean();
