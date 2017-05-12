#! perl

use strict;
use warnings;

use Test::Lib;
use Test::More;
use Test::Trap;

BEGIN {

    use pkg -norequire => 'A';

    my @rs = trap { A->required };
    $trap->die_like( qr/forgot to load/, '-norequire' );

}

BEGIN {

    use pkg -norequire => 'A' => '-require';

    my @rs = trap { A->required };
    $trap->return_is( 0, 1, q[-norequire => 'A' => -require] );

}

done_testing;
