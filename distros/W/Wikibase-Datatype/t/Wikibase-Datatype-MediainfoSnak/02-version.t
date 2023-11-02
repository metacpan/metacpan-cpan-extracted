use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::MediainfoSnak;

# Test.
is($Wikibase::Datatype::MediainfoSnak::VERSION, 0.33, 'Version.');
