package HasSigDie;

use strict;
use warnings;

BEGIN {
    $SIG{__DIE__} = sub { return 'whee!' };
}

1;
