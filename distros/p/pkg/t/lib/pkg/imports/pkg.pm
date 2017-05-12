#!perl

use strict;
use warnings;

use Test::More;
use Test::Trap;

use pkg 'A';

{

    package TestA;

    use strict;
    use warnings;

    use pkg ::PKG;

    my @r;

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

    my @r = ::trap { tattle_ok() };
    $::trap->return_like( 0, qr/ok: $::PKG/,
        "explicit import of $::PKG\::tattle_ok value" );
}

done_testing;
