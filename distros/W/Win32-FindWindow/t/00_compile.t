use strict;
use Test::More tests => 1;

BEGIN {
    if ($^O eq 'MSWin32') {
        use_ok 'Win32::FindWindow';
    }
    else {
        ok("skip unless MSWin32");
    }
}
