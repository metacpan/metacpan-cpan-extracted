use strict;
use warnings;
use Test::More;
use MyNote;
use Try::Tiny;

BEGIN {
    require UUID;
    ok 1, 'loaded';
    try {
        UUID->import(':defer=');
    }
    catch {
        my $e = $_;
        # Non-numeric :defer argument at t/5defer/nonum.t line 11.
        #note $e;
        my $f = __FILE__;
        $f =~ s/\\/\\\\/g; # windows!
        like $e, qr/Usage:/, 'correct';
    };
    ok 1, 'began';
}

ok 1, 'done';

done_testing;
