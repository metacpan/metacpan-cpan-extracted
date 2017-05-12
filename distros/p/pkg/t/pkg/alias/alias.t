#! perl

use strict;
use warnings;

use Test::Lib;
use Test::More;


use A ();

BEGIN {

    use pkg -alias => 'A::C::E';

    is E->tattle_ok, 'ok: A::C::E', 'alias A::C::E => E';

}

BEGIN {

    use pkg 'A::C::E' => -as => 'ACE';

    is ACE->tattle_ok, 'ok: A::C::E', 'alias A::C::E => E';

}

done_testing;
