package # private package
    CpanfileTest2;

use Moo;
use Types::Dist qw(CPANfile);

has cf => ( is => 'ro', isa => CPANfile, coerce => 1 );

1;
