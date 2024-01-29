use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use WWW::Search;

# Test.
my $obj = WWW::Search->new('ValentinskaCZ');
isa_ok($obj, 'WWW::Search');
