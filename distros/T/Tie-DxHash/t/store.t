package Tie::DxHash::Child;

use strict;
use vars qw(@ISA);

use Test;
BEGIN { plan tests => 2 }

use Tie::DxHash;
@ISA = qw(Tie::DxHash);

my (%obj);

tie %obj, 'Tie::DxHash::Child';
%obj = ( r => 'red', g => 'green', g => 'greenish', b => 'blue' );

ok(1);
ok( join( '', keys %obj ), 'rggb' );
