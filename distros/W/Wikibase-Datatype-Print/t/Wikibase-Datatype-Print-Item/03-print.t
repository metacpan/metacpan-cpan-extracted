use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 3;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog;
use Unicode::UTF8 qw(decode_utf8);
use Wikibase::Datatype::Print::Item;

# Test.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog->new;
my $ret = Wikibase::Datatype::Print::Item::print($obj);
my $right_ret = decode_utf8(<<'END');
Label: dog (en)
Description: domestic animal (en)
Aliases:
  domestic dog (en)
  Canis lupus familiaris (en)
  Canis familiaris (en)
  dogs (en)
  🐶 (en)
  🐕 (en)
Sitelinks:
  Dog (enwiki)
Statements:
  P31: Q55983715 (normal)
   P642: Q20717272
   P642: Q26972265
END
chomp $right_ret;
is($ret, $right_ret, 'Get printed value.');

# Test.
eval {
	Wikibase::Datatype::Print::Item::print('bad');
};
is($EVAL_ERROR, "Object isn't 'Wikibase::Datatype::Item'.\n",
	"Object isn't 'Wikibase::Datatype::Item'.");
clean();
