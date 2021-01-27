use strict;
use warnings;

use Text::DSV;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Text::DSV->new;
isa_ok($obj, 'Text::DSV');
