use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Sitelink;

# Test.
is($Wikibase::Datatype::Sitelink::VERSION, 0.29, 'Version.');
