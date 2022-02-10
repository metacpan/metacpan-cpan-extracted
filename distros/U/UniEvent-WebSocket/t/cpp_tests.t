use 5.012;
use warnings;
use lib 't/lib'; use MyTest;
use Test::More;
use Test::Catch;

$SIG{PIPE} = 'IGNORE';

test_catch('[uews]');

done_testing();
