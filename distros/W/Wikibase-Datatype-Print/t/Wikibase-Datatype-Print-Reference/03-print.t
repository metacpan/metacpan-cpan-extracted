use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 3;
use Test::NoWarnings;
use Wikibase::Datatype::Print::Reference;
use Wikibase::Datatype::Reference;
use Wikibase::Datatype::Snak;
use Wikibase::Datatype::Value::String;

# Test.
my $obj = Wikibase::Datatype::Reference->new(
	'snaks' => [
		Wikibase::Datatype::Snak->new(
			'datatype' => 'string',
			'datavalue' => Wikibase::Datatype::Value::String->new(
				'value' => 'text',
			),
			'property' => 'P11',
		),
	],
);
my $ret = Wikibase::Datatype::Print::Reference::print($obj);
my $right_ret = <<'END';
{
  P11: text
}
END
chomp $right_ret;
is($ret, $right_ret, 'Get printed value.');

# Test.
eval {
	Wikibase::Datatype::Print::Reference::print('bad');
};
is($EVAL_ERROR, "Object isn't 'Wikibase::Datatype::Reference'.\n",
	"Object isn't 'Wikibase::Datatype::Reference'.");
clean();
