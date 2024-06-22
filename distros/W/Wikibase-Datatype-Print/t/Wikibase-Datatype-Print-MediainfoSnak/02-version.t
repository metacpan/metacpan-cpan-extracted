use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Print::MediainfoSnak;

# Test.
is($Wikibase::Datatype::Print::MediainfoSnak::VERSION, 0.17, 'Version.');
