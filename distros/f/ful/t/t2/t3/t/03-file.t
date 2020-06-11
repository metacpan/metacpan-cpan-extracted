use Test::Most 'die', tests => 2;

use ful {
    file => '02-relative.t',
    libdirs => [qw/lib vendor/],
};

use_ok('Proof03_1');
use_ok('Proof03_2');

done_testing;