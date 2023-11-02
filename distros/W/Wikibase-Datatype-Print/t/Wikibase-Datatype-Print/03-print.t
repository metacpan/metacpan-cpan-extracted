use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 6;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog;
use Test::Shared::Fixture::Wikibase::Datatype::Lexeme::Wikidata::DogCzechNoun;
use Test::Shared::Fixture::Wikibase::Datatype::Mediainfo::Commons::ImageOfHuman;
use Test::Shared::Fixture::Wikibase::Datatype::Property::Wikidata::InstanceOf;
use Unicode::UTF8 qw(decode_utf8);
use Wikibase::Datatype::Print;

# Test.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog->new;
my $ret = Wikibase::Datatype::Print::print($obj);
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
is($ret, $right_ret, 'Get printed value (item).');

# Test.
$obj = Test::Shared::Fixture::Wikibase::Datatype::Lexeme::Wikidata::DogCzechNoun->new;
$ret = Wikibase::Datatype::Print::Lexeme::print($obj);
$right_ret = decode_utf8(<<'END');
Title: Lexeme:L469
Lemmas: pes (cs)
Language: Q9056
Lexical category: Q1084
Statements:
  P5185: Q499327 (normal)
  References:
    {
      P248: Q53919
      P214: 113230702
      P813: 7 December 2013 (Q1985727)
    }
Senses:
  Id: L469-S1
  Glosses:
    domesticated mammal related to the wolf (en)
    psovitá šelma chovaná jako domácí zvíře (cs)
  Statements:
    P18: Canadian Inuit Dog.jpg (normal)
    P5137: Q144 (normal)
Forms:
  Id: L469-F1
  Representation: pes (cs)
  Grammatical features: Q110786, Q131105
  Statements:
    P898: pɛs (normal)
END
chomp $right_ret;
is($ret, $right_ret, 'Get printed value (lexeme).');

# Test.
$obj = Test::Shared::Fixture::Wikibase::Datatype::Mediainfo::Commons::ImageOfHuman->new;
$ret = Wikibase::Datatype::Print::Mediainfo::print($obj);
$right_ret = <<'END';
Id: M10031710
Title: File:Douglas adams portrait cropped.jpg
NS: 6
Last revision id: 617544224
Date of modification: 2021-12-30T08:38:29Z
Label: Portrait of Douglas Adams (en)
Statements:
  P180: Q42 (normal)
END
chomp $right_ret;
is($ret, $right_ret, 'Get printed value (mediainfo).');

# Test.
$obj = Test::Shared::Fixture::Wikibase::Datatype::Property::Wikidata::InstanceOf->new;
$ret = Wikibase::Datatype::Print::Property::print($obj);
$right_ret = decode_utf8(<<'END');
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
is($ret, $right_ret, 'Get printed value (property).');

# Test.
eval {
	Wikibase::Datatype::Print::print('bad');
};
is($EVAL_ERROR, "Unsupported Wikibase::Datatype object.\n",
	"Unsupported Wikibase::Datatype object.");
clean();
