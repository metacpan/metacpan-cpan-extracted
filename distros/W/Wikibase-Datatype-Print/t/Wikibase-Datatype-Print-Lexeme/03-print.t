use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 3;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::Lexeme::Wikidata::DogCzechNoun;
use Unicode::UTF8 qw(decode_utf8);
use Wikibase::Datatype::Lexeme;
use Wikibase::Datatype::Form;
use Wikibase::Datatype::Print::Lexeme;
use Wikibase::Datatype::Reference;
use Wikibase::Datatype::Sense;
use Wikibase::Datatype::Snak;
use Wikibase::Datatype::Statement;
use Wikibase::Datatype::Value::Item;
use Wikibase::Datatype::Value::Monolingual;
use Wikibase::Datatype::Value::String;
use Wikibase::Datatype::Value::Time;

# Test.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::Lexeme::Wikidata::DogCzechNoun->new;
my $ret = Wikibase::Datatype::Print::Lexeme::print($obj);
my $right_ret = decode_utf8(<<'END');
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
is($ret, $right_ret, 'Get printed value.');

# Test.
eval {
	Wikibase::Datatype::Print::Lexeme::print('bad');
};
is($EVAL_ERROR, "Object isn't 'Wikibase::Datatype::Lexeme'.\n",
	"Object isn't 'Wikibase::Datatype::Lexeme'.");
clean();
