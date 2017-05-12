package Tie::DxHash::Child;

use strict;
use warnings;
use base qw(Tie::DxHash);

use Test::More;
BEGIN { plan tests => 4 }

tie my %obj, 'Tie::DxHash::Child';
%obj = ( r => 'red', g => 'green', g => 'greenish', b => 'blue' );

my $element = delete $obj{x};
is_deeply( $element, [ ], 'non-existent key');

$element  = delete $obj{r};
is_deeply( $element, [ 'red' ], 'scalar return value');

my @elements = delete @obj{ qw(g b x) };
is( keys %obj, 0, 'all hash elements removed' );
is_deeply( \@elements, [ [ qw(green greenish) ], [ 'blue' ], [ ] ], 'list return value correctly defined');
