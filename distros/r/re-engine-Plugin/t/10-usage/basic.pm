package basic;
use strict;

# Note the (), doesn't call ->import
use re::engine::Plugin ();

sub import {
    # Populates %^H with re::engine::Plugin hooks
    re::engine::Plugin->import(
        exec => \&exec,
    );
}

*unimport = \&re::engine::Plugin::unimport;

sub exec
{
    my ($re, $str) = @_;

    $re->num_captures(
        FETCH => sub {
            my ($re, $paren) = @_;

            $str . "_" . $paren;
        }
    );

    1;
}

1;
