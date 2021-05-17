use 5.012;
use lib 't/lib';
use MyTest;
use Test::More;

variate_catch('[server-pipeline]', 'ssl');

done_testing();
