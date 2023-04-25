use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::Struct::MediainfoStatement;

# Test.
is($Wikibase::Datatype::Struct::MediainfoStatement::VERSION, 0.11, 'Version.');
