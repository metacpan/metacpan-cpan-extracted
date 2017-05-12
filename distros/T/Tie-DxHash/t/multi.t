package Tie::DxHash::Child;

use strict;
use vars qw(@ISA);

use Test;
BEGIN { plan tests => 2 }

use Tie::DxHash;
@ISA = qw(Tie::DxHash);

my ( $key1, $key2, %obj1, %obj2, @out );

tie %obj1, 'Tie::DxHash::Child';
tie %obj2, 'Tie::DxHash::Child';
%obj1 = ( r => 'red',    g => 'green',   g => 'greenish',  b => 'blue' );
%obj2 = ( m => 'monday', t => 'tuesday', w => 'wednesday', w => 'wednesday' );

OUTER:
while ( $key1 = each %obj1 ) {
    push @out, $key1;

INNER:
    while ( $key2 = each %obj2 ) {
        push @out, $key2;
        next OUTER;
    }
}

ok(1);
ok( join( '', @out ), 'rmgtgwbw' );
