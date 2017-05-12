use strict;
use Test::More tests => 14;

my %rx_idx;
BEGIN {
    %rx_idx = (
        q[$`] => -2,
        q[$'] => -1,
        q[$&] => 0,
    );
    if ("$]" >= 5.019_004) {
        # This should be the case since 5.17.4 but there's a bug in perl that
        # was fixed in 5.19.4 which caused the FETCH callback to get the old
        # indices.
        $rx_idx{q[${^PREMATCH}]}  = -5;
        $rx_idx{q[${^POSTMATCH}]} = -4;
        $rx_idx{q[${^MATCH}]}     = -3;
    } else {
        $rx_idx{q[${^PREMATCH}]}  = $rx_idx{q[$`]};
        $rx_idx{q[${^POSTMATCH}]} = $rx_idx{q[$']};
        $rx_idx{q[${^MATCH}]}     = $rx_idx{q[$&]};
    }
}

use re::engine::Plugin (
    exec => sub {
        my $re = shift;

        if ("$]" >= 5.017_004) {
            my %full_name_map = (
                -2 => -5,
                -1 => -4,
                 0 => -3,
            );
        }

        $re->stash( [
            [ q[$`],            "a" ],
            [ q[${^PREMATCH}],  "a" ],
            [ q[$'],            "o" ],
            [ q[${^POSTMATCH}], "o" ],
            [ q[$&],            "e" ],
            [ q[${^MATCH}],     "e" ],
            [ \1,               "u" ],
        ]);

        $re->num_captures(
            STORE => sub {
                my ($re, $paren, $sv) = @_;
                my $test = shift @{ $re->stash };

                my $desc;
                my $idx = $test->[0];
                if (ref $idx) {
                    $idx  = $$idx;
                    $desc = "STORE \$$idx";
                } else {
                    $desc = "STORE $idx";
                    $idx  = $rx_idx{$idx};
                }

                is($paren, $idx,       "$desc (index)");
                is($sv,    $test->[1], "$desc (value)");
            },
        );

        1;
    },
);

"a" =~ /a/;

$` = "a";
${^PREMATCH} = "a";
$' = "o";
${^POSTMATCH} = "o";
$& = "e";
${^MATCH} = "e";
$1 = "u";
