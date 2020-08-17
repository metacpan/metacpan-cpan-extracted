use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Zodiac::Angle;

# Test.
my $obj = Zodiac::Angle->new;
isa_ok($obj, 'Zodiac::Angle');
