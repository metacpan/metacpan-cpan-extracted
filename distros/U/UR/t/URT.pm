use strict;
use warnings;

package URT;

use UR;

class URT {
    is => ['UR::Namespace'],
    has_constant => [
        allow_sloppy_primitives => { value => 1 },
    ],
    doc => 'A dummy namespace used by the UR test suite.',
};

1;
#$Header
