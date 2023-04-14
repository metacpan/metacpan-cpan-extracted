use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Print::Sitelink;

# Test.
is($Wikibase::Datatype::Print::Sitelink::VERSION, 0.04, 'Version.');
