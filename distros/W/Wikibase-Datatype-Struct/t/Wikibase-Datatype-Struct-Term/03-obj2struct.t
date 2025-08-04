use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 4;
use Test::NoWarnings;
use Wikibase::Datatype::Struct::Term;
use Wikibase::Datatype::Term;

# Test.
my $obj = Wikibase::Datatype::Term->new(
	'language' => 'en',
	'value' => 'English text',
);
my $ret_hr = Wikibase::Datatype::Struct::Term::obj2struct($obj);
is_deeply(
	$ret_hr,
	{
		'language' => 'en',
		'value' => 'English text',
	},
	'Output of obj2struct() subroutine.',
);

# Test.
eval {
	Wikibase::Datatype::Struct::Term::obj2struct('bad');
};
is($EVAL_ERROR, "Object isn't 'Wikibase::Datatype::Term'.\n",
	"Object isn't 'Wikibase::Datatype::Term'.");
clean();

# Test.
eval {
	Wikibase::Datatype::Struct::Term::obj2struct();
};
is($EVAL_ERROR, "Object doesn't exist.\n", "Object doesn't exist.");
clean();
