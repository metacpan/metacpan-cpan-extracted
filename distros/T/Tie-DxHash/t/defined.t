package Tie::DxHash::Child;

use strict;
use vars qw(@ISA);

use Test;
BEGIN { plan tests => 4 }

use Tie::DxHash;
@ISA = qw(Tie::DxHash);

my (%obj);

tie %obj, 'Tie::DxHash::Child';
%obj = ( r => 'red', g => 'green', g => undef, b => 'blue' );
delete $obj{b};

ok(1);
ok( defined $obj{g} );
ok( not defined $obj{g} );
ok( not defined $obj{b} );
