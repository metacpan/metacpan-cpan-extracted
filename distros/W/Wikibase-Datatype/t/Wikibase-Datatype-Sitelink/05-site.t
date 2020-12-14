use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Sitelink;

# Test.
my $obj = Wikibase::Datatype::Sitelink->new(
	'site' => 'enwiki',
	'title' => 'Title',
);
my $ret = $obj->site;
is_deeply($ret, 'enwiki', 'Get site() method.');
