use strict;
use warnings;
use Test::More;
use MyNote;
use Try::Tiny;

BEGIN {
    require UUID;
    ok 1, 'loaded';

    # :defer with extra args can only be called directly
    try {
        UUID::_defer(1,1);
    }
    catch {
        my $e = $_;
        # Too many arguments for _defer() at t/5defer/extra.t line 13.
        #note $e;
        my $f = __FILE__;
        $f =~ s/\\/\\\\/g; # windows!
        like $e, qr/Too many arguments for _defer\(\) at $f line/, 'correct';
    };

    ok 1, 'began';
}

ok 1, 'done';

done_testing;
