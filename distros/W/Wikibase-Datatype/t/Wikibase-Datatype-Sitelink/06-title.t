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
my $ret = $obj->title;
is_deeply($ret, 'Title', 'Get title() method.');
