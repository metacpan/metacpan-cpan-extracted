use 5.012;
use lib 't/lib';
use MyTest;
use Test::More;

variate_catch('[client-sync]', 'ssl');

done_testing();