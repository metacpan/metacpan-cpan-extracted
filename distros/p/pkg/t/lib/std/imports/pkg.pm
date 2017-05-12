#!perl

use strict;
use warnings;

use Test::More;
use Test::Trap;

use A;

{

    package TestA;

    use strict;
    use warnings;

    my @r;

    # test that implicit export works
    @r = ::trap { ::PKG->import() };
    $::trap->did_return("$::PKG\->import(): returned");

    @r = ::trap { tattle() };
    $::trap->return_is( 0, ::PKG, "implicit import of $::PKG\::tattle" );

    ::trap { tattle_ok() };
    $::trap->die_like( qr/undefined subroutine/i,
        "no implicit import of $::PKG\::tattle_ok" );

    @r = ::trap { ::PKG->tattle_ok() };
    $::trap->did_return("$::PKG\->tattle_ok: returned");
    $::trap->return_like( 0, qr/ok: $::PKG/,
        "$::PKG\->tattle_ok: correct value" );

}

{

    package TestB;

    use strict;
    use warnings;

    use pkg ::PKG => 'tattle_ok';

    ::trap { ::PKG->import('tattle_ok') };
    $::trap->did_return("explicit import of $::PKG\::tattle_ok");

    my @r = ::trap { tattle_ok() };
    $::trap->return_like( 0, qr/ok: $::PKG/,
        "explicit import of $::PKG\::tattle_ok value" );
}

done_testing;

