package import;
use strict;

sub exec;
use re::engine::Plugin ':import';

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
