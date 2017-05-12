#! perl

use strict;
use warnings;

use Test::Lib;
use Test::More;
use Test::Exception;
use Test::Trap;


use A ();

BEGIN {

    use pkg -strip => 'A::' => 'A::C::E';

    is CE->tattle_ok, 'ok: A::C::E', 'alias A::C::E => CE';

}

BEGIN {

    use pkg -strip => { pfx => 'A::', sep => '_' } => 'A::C::E';

    is C_E->tattle_ok, 'ok: A::C::E', 'alias A::C::E => C_E';

}

BEGIN {

    use pkg -strip => { pfx => 'A::', sep => 'x' } => -noalias, 'A::C::E';

    dies_ok { CxE->tattle_ok } '-strip -noalias';

}

done_testing;
