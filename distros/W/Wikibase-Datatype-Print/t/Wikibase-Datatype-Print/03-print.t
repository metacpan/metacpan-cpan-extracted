use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Readonly;
use Test::More 'tests' => 11;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog 0.36;
use Test::Shared::Fixture::Wikibase::Datatype::Lexeme::Wikidata::DogCzechNoun;
use Test::Shared::Fixture::Wikibase::Datatype::Mediainfo::Commons::ImageOfHuman;
use Test::Shared::Fixture::Wikibase::Datatype::Property::Wikidata::InstanceOf;
use Unicode::UTF8 qw(decode_utf8);
use Wikibase::Datatype::Print;

Readonly::Hash our %EN_TEXTS => (
	'aliases' => 'A l i a s e s',
	'data_type' => 'D a t a   t y p e',
	'date_of_modification' => 'D a t e   o f   m o d i f i c a t i o n',
	'description' => 'D e s c r i p t i o n',
	'forms' => 'F o r m s',
	'glosses' => 'G l o s s e s',
	'grammatical_features' => 'G r a m m a t i c a l   f e a t u r e s',
	'id' => 'I d',
	'label' => 'L a b e l',
	'language' => 'L a n g u a g e',
	'last_revision_id' => 'L a s t   r e v i s i o n   i d',
	'lemmas' => 'L e m m a s',
	'lexical_category' => 'L e x i c a l   c a t e g o r y',
	'ns' => 'N S',
	'page_id' => 'P a g e   i d',
	'rank_normal' => 'n o r m a l',
	'rank_preferred' => 'p r e f e r r e d',
	'rank_deprecated' => 'd e p r e c a t e d',
	'references' => 'R e f e r e n c e s',
	'representation' => 'R e p r e s e n t a t i o n',
	'senses' => 'S e n s e s',
	'sitelinks' => 'S i t e l i n k s',
	'statements' => 'S t a t e m e n t s',
	'title' => 'T i t l e',
	'value_no' => 'n o   v a l u e',
	'value_unknown' => 'u n k n o w n   v a l u e',
);

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
  P123456789: 4 (normal)
END
chomp $right_ret;
is($ret, $right_ret, 'Get printed value (item).');

# Test.
$obj = Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog->new;
$ret = Wikibase::Datatype::Print::print($obj, {
	'texts' => \%EN_TEXTS,
});
$right_ret = decode_utf8(<<'END');
L a b e l: dog (en)
D e s c r i p t i o n: domestic animal (en)
A l i a s e s:
  domestic dog (en)
  Canis lupus familiaris (en)
  Canis familiaris (en)
  dogs (en)
  🐶 (en)
  🐕 (en)
S i t e l i n k s:
  Dog (enwiki)
S t a t e m e n t s:
  P31: Q55983715 (n o r m a l)
   P642: Q20717272
   P642: Q26972265
  P123456789: 4 (n o r m a l)
END
chomp $right_ret;
is($ret, $right_ret, 'Get printed value (item with explicit texts).');

# Test.
$obj = Test::Shared::Fixture::Wikibase::Datatype::Lexeme::Wikidata::DogCzechNoun->new;
$ret = Wikibase::Datatype::Print::print($obj);
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
$obj = Test::Shared::Fixture::Wikibase::Datatype::Lexeme::Wikidata::DogCzechNoun->new;
$ret = Wikibase::Datatype::Print::print($obj, {
	'texts' => \%EN_TEXTS,
});
$right_ret = decode_utf8(<<'END');
T i t l e: Lexeme:L469
L e m m a s: pes (cs)
L a n g u a g e: Q9056
L e x i c a l   c a t e g o r y: Q1084
S t a t e m e n t s:
  P5185: Q499327 (n o r m a l)
  R e f e r e n c e s:
    {
      P248: Q53919
      P214: 113230702
      P813: 7 December 2013 (Q1985727)
    }
S e n s e s:
  I d: L469-S1
  G l o s s e s:
    domesticated mammal related to the wolf (en)
    psovitá šelma chovaná jako domácí zvíře (cs)
  S t a t e m e n t s:
    P18: Canadian Inuit Dog.jpg (n o r m a l)
    P5137: Q144 (n o r m a l)
F o r m s:
  I d: L469-F1
  R e p r e s e n t a t i o n: pes (cs)
  G r a m m a t i c a l   f e a t u r e s: Q110786, Q131105
  S t a t e m e n t s:
    P898: pɛs (n o r m a l)
END
chomp $right_ret;
is($ret, $right_ret, 'Get printed value (lexeme with explicit texts).');

# Test.
$obj = Test::Shared::Fixture::Wikibase::Datatype::Mediainfo::Commons::ImageOfHuman->new;
$ret = Wikibase::Datatype::Print::print($obj);
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
$obj = Test::Shared::Fixture::Wikibase::Datatype::Mediainfo::Commons::ImageOfHuman->new;
$ret = Wikibase::Datatype::Print::print($obj, {
	'texts' => \%EN_TEXTS,
});
$right_ret = <<'END';
I d: M10031710
T i t l e: File:Douglas adams portrait cropped.jpg
N S: 6
L a s t   r e v i s i o n   i d: 617544224
D a t e   o f   m o d i f i c a t i o n: 2021-12-30T08:38:29Z
L a b e l: Portrait of Douglas Adams (en)
S t a t e m e n t s:
  P180: Q42 (n o r m a l)
END
chomp $right_ret;
is($ret, $right_ret, 'Get printed value (mediainfo property with explicit texts).');

# Test.
$obj = Test::Shared::Fixture::Wikibase::Datatype::Property::Wikidata::InstanceOf->new;
$ret = Wikibase::Datatype::Print::print($obj);
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
$obj = Test::Shared::Fixture::Wikibase::Datatype::Property::Wikidata::InstanceOf->new;
$ret = Wikibase::Datatype::Print::print($obj, {
	'texts' => \%EN_TEXTS,
});
$right_ret = decode_utf8(<<'END');
D a t a   t y p e: wikibase-item
L a b e l: instance of (en)
D e s c r i p t i o n: that class of which this subject is a particular example and member (en)
A l i a s e s:
  is a (en)
  is an (en)
S t a t e m e n t s:
  P31: Q32753077 (n o r m a l)
END
chomp $right_ret;
is($ret, $right_ret, 'Get printed value (property with explicit texts).');

# Test.
eval {
	Wikibase::Datatype::Print::print('bad');
};
is($EVAL_ERROR, "Unsupported Wikibase::Datatype object.\n",
	"Unsupported Wikibase::Datatype object.");
clean();

# Test.
$obj = Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog->new;
eval {
	Wikibase::Datatype::Print::print($obj, {
		'texts' => {},
	});
};
is($EVAL_ERROR, "Defined text keys are bad.\n",
	"Defined text keys are bad.");
clean();
