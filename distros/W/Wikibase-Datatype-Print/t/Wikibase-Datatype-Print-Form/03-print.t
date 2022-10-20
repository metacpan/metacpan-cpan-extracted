use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 3;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);
use Wikibase::Datatype::Print::Form;
use Wikibase::Datatype::Form;
use Wikibase::Datatype::Snak;
use Wikibase::Datatype::Statement;
use Wikibase::Datatype::Value::Item;
use Wikibase::Datatype::Value::Monolingual;
use Wikibase::Datatype::Value::String;

# Test.
my $obj = Wikibase::Datatype::Form->new(
        'grammatical_features' => [
                # singular
                Wikibase::Datatype::Value::Item->new(
                        'value' => 'Q110786',
                ),
                # nominative case
                Wikibase::Datatype::Value::Item->new(
                        'value' => 'Q131105',
                ),
        ],
        'id' => 'L469-F1',
        'representations' => [
                Wikibase::Datatype::Value::Monolingual->new(
                        'language' => 'cs',
                        'value' => 'pes',
                ),
        ],
        'statements' => [
                Wikibase::Datatype::Statement->new(
                        'snak' => Wikibase::Datatype::Snak->new(
                                'datatype' => 'string',
                                'datavalue' => Wikibase::Datatype::Value::String->new(
                                       'value' => decode_utf8('pɛs'),
                                ),
                                'property' => 'P898',
                        ),
                ),
        ],
);
my $ret = Wikibase::Datatype::Print::Form::print($obj);
my $right_ret = decode_utf8(<<'END');
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
	Wikibase::Datatype::Print::Form::print('bad');
};
is($EVAL_ERROR, "Object isn't 'Wikibase::Datatype::Form'.\n",
	"Object isn't 'Wikibase::Datatype::Form'.");
clean();
