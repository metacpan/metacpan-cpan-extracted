use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikibase::Datatype::MediainfoStatement;

# Test.
is($Wikibase::Datatype::MediainfoStatement::VERSION, 0.33, 'Version.');
