use strict;
use Test::More "$]" < 5.011 ? (tests => 7)
                            : (skip_all => 'Not working in blead');

use re::engine::Plugin (
    exec => sub {
        my $re = shift;

        $re->stash( [
            10, 10,
            20, 20,
            30, 30,
            40,
        ]);

        $re->num_captures(
            LENGTH => sub {
                my ($re, $paren) = @_;

                shift @{ $re->stash };
            },
        );

        1;
    },
);

"a" =~ /a/;

is(length $`, 10);
is(length ${^PREMATCH}, 10);
is(length $', 20);
is(length ${^POSTMATCH}, 20);
is(length $&, 30);
is(length ${^MATCH}, 30);
is(length $1, 40);
