use strict;
use warnings;
use utf8;
use Test::More;

use Text::MatchedPosition;

{
    eval {
        Text::MatchedPosition->new("", 1);
    };
    my $e = $@;

    like $e, qr!^The 2nd arg requires 'Regexp': !;
}

done_testing;
