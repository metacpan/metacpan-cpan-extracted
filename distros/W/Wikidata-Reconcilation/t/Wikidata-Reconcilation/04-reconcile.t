use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikidata::Reconcilation;

# Test.
my $obj = Wikidata::Reconcilation->new;
eval {
	$obj->reconcile;
};
is($EVAL_ERROR, "This is abstract class. You need to implement _reconcile() method.\n",
	"This is abstract class. You need to implement _reconcile() method.");
