package Tie::DxHash::Child;

use strict;
use vars qw(@ISA);

use Test;
BEGIN { plan tests => 5 }

use Tie::DxHash;
@ISA = qw(Tie::DxHash);

my (%obj);

tie %obj, 'Tie::DxHash::Child';
%obj = ( r => 'red', g => 'green', g => 'greenish', b => 'blue' );

ok(1);
ok( $obj{r}, 'red' );
ok( $obj{g}, 'green' );
ok( $obj{g}, 'greenish' );
ok( $obj{g}, 'green' );
