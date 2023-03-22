package  # private package
    OPMFileTest;

use Moo;
use Types::OPM qw(OPMFile);

has file => ( is => 'ro', isa => OPMFile, coerce => 1 );

1;
