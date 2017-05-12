#! perl

use strict;
use warnings;

use Test::Lib;
use Test::More;
use Test::Exception;
use Test::Trap;

use A ();

# all of the methods in the packages in A.pm are created upon import
# define both A::C and A::C::E methods, but do it in different
# packages to avoid warnings about main::tattle_ok being redefined

{
    package a1;
    use pkg 'A::C';

    # just to be sure A::C is really substantiated
    my @rs = ::trap { A::C->tattle_ok() };
}

{
    package a2;
    use pkg 'A::C::E';

    # just to be sure A::C::E is really substantiated
    ::lives_ok { A::C::E->tattle_ok() };
}

{

    package test_a;

    use pkg -alias => -noalias => 'A::C';

    $::trap->return_like( 0, qr/ok: A::C/, 'method generated' );

    ::dies_ok { C->tattle_ok } '-alias -noalias';

}

{

    package test_b;

    no warnings 'redefine';

    use pkg
      -alias   => ['A::C'],
      -noalias => ['A::C::E'];

    ::is C->tattle_ok, 'ok: A::C', q(-alias ['A::C']);

    ::throws_ok { E->tattle_ok } qr/can't locate object method .* package "E"/i,
      q(-alias [...] -noalias ['A:C:E']);
}

done_testing;
