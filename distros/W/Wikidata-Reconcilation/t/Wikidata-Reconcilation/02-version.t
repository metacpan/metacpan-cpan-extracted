use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikidata::Reconcilation;

# Test.
is($Wikidata::Reconcilation::VERSION, 0.02, 'Version.');
