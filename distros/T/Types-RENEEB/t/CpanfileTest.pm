package # private package
    CpanfileTest;

use Moo;
use Types::RENEEB qw(CPANfile);

has cf => ( is => 'ro', isa => CPANfile, coerce => 1 );

1;
