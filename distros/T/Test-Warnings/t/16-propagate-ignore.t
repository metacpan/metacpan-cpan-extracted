use strict;
use warnings;

use Test::More 0.88;

sub IGNORE {
    die 'IGNORE sub called; this is wrong!';
}

BEGIN {
    $SIG{__WARN__} = 'IGNORE';
}

use Test::Warnings qw(:all :no_end_test);
use if "$]" >= '5.008', lib => 't/lib';
use if "$]" >= '5.008', 'SilenceStderr';

warn 'this warning is not expected to be caught';

SKIP: {
    skip 'PadWalker required for this test', 1
        if not eval { require PadWalker; 1 };
    is(
        ${ PadWalker::closed_over(\&Test::Warnings::had_no_warnings)->{'$forbidden_warnings_found'} },
        1,
        'Test::Warnings saw the warning, and allowed it to go by',
    );
}

done_testing;
