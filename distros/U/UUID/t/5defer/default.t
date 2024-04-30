use strict;
use warnings;
use Test::More;
use MyNote;
use Try::Tiny;

BEGIN {
    require UUID;
    ok 1, 'loaded';
    try {
        UUID->import(':defer');
        ok 1, 'deferred';
    }
    catch {
        my $e = $_;
        # Non-numeric :defer argument at t/5defer/nonum.t line 11.
        note $e;
        ok 0, 'deferred';
    };
    ok 1, 'began';
}

is sprintf('%.3f', UUID::_defer()), 0.001, 'default';

ok 1, 'done';

done_testing;
