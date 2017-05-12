use strict;
use Test::More tests => 7;


my %rx_idx;
BEGIN {
    %rx_idx = (
        q[$`] => -2,
        q[$'] => -1,
        q[$&] => 0,
    );
    if ("$]" >= 5.017_004) {
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

        $re->num_captures(
            FETCH => sub {
                my ($re, $paren) = @_;

                my %exp = (
                    q[$`]            => 10,
                    q[${^PREMATCH}]  => 10,
                    q[$']            => 20,
                    q[${^POSTMATCH}] => 20,
                    q[$&]            => 30,
                    q[${^MATCH}]     => 30,
                    1                => 40,
                );

                my %ret;
                for (keys %exp) {
                    if (exists $rx_idx{$_}) {
                        $ret{$rx_idx{$_}} = $exp{$_};
                    } else {
                        $ret{$_}          = $exp{$_};
                    }
                }

                $ret{$paren};
            }
        );

        1;
    },
);

"a" =~ /a/;

is($`,            10, '$`');
is(${^PREMATCH},  10, '${^PREMATCH}');
is($',            20, q($'));
is(${^POSTMATCH}, 20, '${^POSTMATCH}');
is($&,            30, '$&');
is(${^MATCH},     30, '${^MATCH}');
is($1,            40, '$1');
