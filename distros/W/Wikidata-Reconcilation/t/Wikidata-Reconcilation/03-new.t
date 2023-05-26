use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Wikidata::Reconcilation;

# Test.
my $obj = Wikidata::Reconcilation->new;
isa_ok($obj, 'Wikidata::Reconcilation');
