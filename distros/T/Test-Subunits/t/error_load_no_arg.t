use 5.010;
use strict;
use warnings;

use Test::More;
plan tests => 3;


# Module should die when loaded without an argument...

ok !eval q{ use Test::Subunits; 1; }
    => 'Detected missing argument when loading';

like $@, qr/\ANo argument supplied/ => 'Correct error message';


# ...unless you switch off its import() behaviours completely...

ok eval q{ use Test::Subunits (); 1; }
    => 'Load without using works';

done_testing();

