use 5.012;
use warnings;
use lib 't/lib'; use MyTest;
use Test::More;
use Test::Catch;

$SIG{PIPE} = 'IGNORE';

variate_catch('[server-misc]', 'ssl');

done_testing();
