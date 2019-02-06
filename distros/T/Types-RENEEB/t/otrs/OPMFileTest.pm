package  # private package
    OPMFileTest;

use Moo;
use Types::OTRS qw(OPMFile);

has file => ( is => 'ro', isa => OPMFile, coerce => 1 );

1;
