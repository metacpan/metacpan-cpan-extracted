use strict;
use Test::More;

BEGIN {
    use_ok 'Test::NoLoad';
    Test::NoLoad::dump_modules()
}

load_ok('Test::NoLoad');

check_no_load(qw/
    Moose
/, qr/Acme::.+/);

done_testing;