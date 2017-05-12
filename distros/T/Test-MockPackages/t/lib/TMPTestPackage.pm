package TMPTestPackage;
use strict;
use warnings;
use utf8;

use English qw(-no_match_vars);

sub subroutine {
    my ( $arg1, $arg2 ) = @ARG;

    return "subroutine return: $arg1, $arg2";
}

sub empty_prototype() {
    return 'empty_prototype';
}

sub scalar_prototype($) {
    return 'scalar_prototype ' . $ARG[ 0 ];
}

1;
