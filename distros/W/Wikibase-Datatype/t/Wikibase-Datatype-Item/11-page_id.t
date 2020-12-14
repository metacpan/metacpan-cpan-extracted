use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 4;
use Test::NoWarnings;
use Wikibase::Datatype::Item;

# Test.
my $obj = Wikibase::Datatype::Item->new;
my $ret = $obj->page_id;
is($ret, undef, 'Default page id.');

# Test.
$obj = Wikibase::Datatype::Item->new(
	'page_id' => 123,
);
$ret = $obj->page_id;
is($ret, 123, 'Explicit page id.');

# Test.
eval {
	Wikibase::Datatype::Item->new(
		'page_id' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'page_id' must be a number.\n",
	"Parameter 'page_id' must be a number.");
clean();
