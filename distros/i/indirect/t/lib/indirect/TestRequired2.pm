package indirect::TestRequired2;

no indirect;

BEGIN { delete $INC{'indirect/TestRequired1.pm'} }

use lib 't/lib';
use indirect::TestRequired1;

eval {
 my $y = new Baz;
};

eval 'my $z = new Blech';

1;
