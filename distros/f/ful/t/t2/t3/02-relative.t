use Test::Most 'die', tests => 2;

use ful qw/lib vendor/;

require_ok('Proof02_1');
require_ok('Proof02_2');

done_testing;