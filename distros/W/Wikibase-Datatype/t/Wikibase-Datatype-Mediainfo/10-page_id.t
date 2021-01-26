use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 4;
use Test::NoWarnings;
use Wikibase::Datatype::Mediainfo;

# Test.
my $obj = Wikibase::Datatype::Mediainfo->new;
my $ret = $obj->page_id;
is($ret, undef, 'Default page id.');

# Test.
$obj = Wikibase::Datatype::Mediainfo->new(
	'page_id' => 123,
);
$ret = $obj->page_id;
is($ret, 123, 'Explicit page id.');

# Test.
eval {
	Wikibase::Datatype::Mediainfo->new(
		'page_id' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'page_id' must be a number.\n",
	"Parameter 'page_id' must be a number.");
clean();
