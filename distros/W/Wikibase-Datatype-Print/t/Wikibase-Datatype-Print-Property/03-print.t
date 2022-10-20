use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 3;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Property::Wikidata::InstanceOf;
use Unicode::UTF8 qw(decode_utf8);
use Wikibase::Datatype::Print::Property;

# Test.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::Property::Wikidata::InstanceOf->new;
my $ret = Wikibase::Datatype::Print::Property::print($obj);
my $right_ret = decode_utf8(<<'END');
Data type: wikibase-item
Label: instance of (en)
Description: that class of which this subject is a particular example and member (en)
Aliases:
  is a (en)
  is an (en)
Statements:
  P31: Q32753077 (normal)
END
chomp $right_ret;
is($ret, $right_ret, 'Get printed value.');

# Test.
eval {
	Wikibase::Datatype::Print::Property::print('bad');
};
is($EVAL_ERROR, "Object isn't 'Wikibase::Datatype::Property'.\n",
	"Object isn't 'Wikibase::Datatype::Property'.");
clean();
