use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 3;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::MediainfoSnak::Commons::Depicts::Human;
use Wikibase::Datatype::Print::MediainfoSnak;

# Test.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::MediainfoSnak::Commons::Depicts::Human->new;
my $ret = Wikibase::Datatype::Print::MediainfoSnak::print($obj);
is($ret, 'P180: Q42', 'Get snak value (depicts: human fixture).');

# Test.
eval {
	Wikibase::Datatype::Print::MediainfoSnak::print('bad');
};
is($EVAL_ERROR, "Object isn't 'Wikibase::Datatype::MediainfoSnak'.\n",
	"Object isn't 'Wikibase::Datatype::MediainfoSnak'.");
clean();
