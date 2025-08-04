use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 3;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);
use Wikibase::Datatype::Print::Term;
use Wikibase::Datatype::Term;

# Test.
my $obj = Wikibase::Datatype::Term->new(
	'language' => 'cs',
	'value' => decode_utf8('Příklad.'),
);
my $ret = Wikibase::Datatype::Print::Term::print($obj);
is($ret, decode_utf8('Příklad. (cs)'), 'Get printed value.');

# Test.
eval {
	Wikibase::Datatype::Print::Term::print('bad');
};
is($EVAL_ERROR, "Object isn't 'Wikibase::Datatype::Term'.\n",
	"Object isn't 'Wikibase::Datatype::Term' (bad).");
clean();
