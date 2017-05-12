use 5.010;
use strict;
use warnings;
use lib 'tlib';

use Test::More;
plan tests => 5;


# Module should die when loaded with a non-cooperative source file...

ok !eval q{ use Test::Subunits 'NoSubunitsLoud'; 1; }
    => 'Module successfully interdicted';

like $@, qr/\ANo subunits for you!/ => 'Correct error message';

ok not('main'->can('subunit')) => 'No subunit extracted';


# A source file can also be silently non-cooperative...

ok eval q{ use Test::Subunits 'NoSubunitsQuiet'; 1; }
    => 'Module loaded silently';

ok not('main'->can('subunit')) => 'No subunit extracted';

done_testing();


