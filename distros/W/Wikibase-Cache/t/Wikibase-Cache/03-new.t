use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use File::Object;
use Test::More 'tests' => 5;
use Test::NoWarnings;
use Wikibase::Cache;

unshift @INC, File::Object->new->up->dir('lib')->s;

# Test.
my $obj = Wikibase::Cache->new;
isa_ok($obj, 'Wikibase::Cache');

# Test.
eval {
	Wikibase::Cache->new(
		'backend' => 'Bad',
	);
};
is($EVAL_ERROR, "Cannot load module 'Wikibase::Cache::Backend::Bad'.\n",
	"Cannot load module 'Wikibase::Cache::Backend::Bad'.");
clean();

# Test.
$obj = Wikibase::Cache->new(
	'backend' => 'Foo',
);
isa_ok($obj, 'Wikibase::Cache');

# Test.
eval {
	Wikibase::Cache->new(
		'backend' => 'Bad2',
	);
};
is($EVAL_ERROR, "Backend must inherit 'Wikibase::Cache::Backend' abstract class.\n",
	"Backend must inherit 'Wikibase::Cache::Backend' abstract class.");
clean();
