use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 4;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);
use Wikibase::Datatype::Term;

# Test.
my $obj = Wikibase::Datatype::Term->new(
	'language' => 'cs',
	'value' => decode_utf8('Příklad'),
);
isa_ok($obj, 'Wikibase::Datatype::Term');

# Test.
eval {
	Wikibase::Datatype::Term->new(
		'language' => 'und',
	);
};
is($EVAL_ERROR, "Language code 'und' isn't code supported for terms by Wikibase.\n",
	"Language code 'und' isn't code supported for terms by Wikibase.");
clean();

# Test.
eval {
	Wikibase::Datatype::Term->new;
};
is($EVAL_ERROR, "Parameter 'value' is required.\n",
	"Parameter 'value' is required.");
clean();
