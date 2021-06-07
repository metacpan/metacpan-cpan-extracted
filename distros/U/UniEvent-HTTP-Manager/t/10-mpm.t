use 5.012;
use warnings;
use Test::Catch;
use lib 't/lib'; use MyTest;
use Test::More;

catch_run('[mpm]');

done_testing();
