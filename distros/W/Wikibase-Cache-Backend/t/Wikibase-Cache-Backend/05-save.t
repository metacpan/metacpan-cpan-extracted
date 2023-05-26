use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 4;
use Test::NoWarnings;
use Wikibase::Cache::Backend;

# Test.
my $obj = Wikibase::Cache::Backend->new;
eval {
	$obj->save;
};
is($EVAL_ERROR, "Type must be defined.\n",
	"Type must be defined.");
clean();

# Test.
$obj = Wikibase::Cache::Backend->new;
eval {
	$obj->save('bad_type', 'key', 'value');
};
is($EVAL_ERROR, "Type 'bad_type' isn't supported.\n",
	"Type 'bad_type' isn't supported.");
clean();

# Test.
$obj = Wikibase::Cache::Backend->new;
eval {
	$obj->save('label', 'key', 'value');
};
is($EVAL_ERROR, "This is abstract class. You need to implement '_save' method.\n",
	"This is abstract class. You need to implement '_save' method.");
clean();
