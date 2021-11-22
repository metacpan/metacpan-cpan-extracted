use 5.012;
use lib 't/lib';
use MyTest;
use Test::More;
use Test::Exception;
use Protocol::HTTP::Request;

variate_catch('[server-misc]', 'ssl');

done_testing();
