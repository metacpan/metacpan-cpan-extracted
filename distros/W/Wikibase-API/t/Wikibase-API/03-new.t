use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::MockObject;
use Test::More 'tests' => 5;
use Test::NoWarnings;
use Wikibase::API;

# Test.
my $obj = Wikibase::API->new;
isa_ok($obj, 'Wikibase::API');

# Test.
eval {
	Wikibase::API->new(
		'mediawiki_api' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'mediawiki_api' must be a 'MediaWiki::API' instance.\n",
	"Parameter 'mediawiki_api' must be a 'MediaWiki::API' instance (scalar).");
clean();

# Test.
my $mock = Test::MockObject->new;
eval {
	Wikibase::API->new(
		'mediawiki_api' => $mock,
	);
};
is($EVAL_ERROR, "Parameter 'mediawiki_api' must be a 'MediaWiki::API' instance.\n",
	"Parameter 'mediawiki_api' must be a 'MediaWiki::API' instance (mock object).");
clean();

# Test.
eval {
	Wikibase::API->new(
		'bad' => 'bar',
	);
};
is($EVAL_ERROR, "Unknown parameter 'bad'.\n",
	"Unknown parameter 'bad'.");
clean();
