use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Cache::Backend::Basic;

# Test.
my $obj = Wikibase::Cache::Backend::Basic->new;
eval {
	$obj->save('label', 'Q11573', 'foo');
};
is($EVAL_ERROR, "Wikibase::Cache::Backend::Basic doesn't implement save() method.\n",
	"Wikibase::Cache::Backend::Basic doesn't implement save() method.");
clean();
