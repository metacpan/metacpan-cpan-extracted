use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 3;
use Test::NoWarnings;
use Test::Shared::Fixture::Wikibase::Datatype::MediainfoStatement::Commons::Depicts::Human;
use Wikibase::Datatype::Print::MediainfoStatement;

# Test.
my $obj = Test::Shared::Fixture::Wikibase::Datatype::MediainfoStatement::Commons::Depicts::Human->new;
my @ret = Wikibase::Datatype::Print::MediainfoStatement::print($obj);
is_deeply(
	\@ret,
	[
		'P180: Q42 (normal)',
	],
	'Get printed value.',
);

# Test.
eval {
	Wikibase::Datatype::Print::MediainfoStatement::print('bad');
};
is($EVAL_ERROR, "Object isn't 'Wikibase::Datatype::MediainfoStatement'.\n",
	"Object isn't 'Wikibase::Datatype::MediainfoStatement'.");
clean();
