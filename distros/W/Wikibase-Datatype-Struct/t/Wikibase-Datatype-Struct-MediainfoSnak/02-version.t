use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Struct::MediainfoSnak;

# Test.
is($Wikibase::Datatype::Struct::MediainfoSnak::VERSION, 0.08, 'Version.');
