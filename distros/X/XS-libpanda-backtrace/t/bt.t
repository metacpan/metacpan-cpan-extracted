use 5.012;
use warnings;
use lib 't/lib'; use MyTest;
use Test::More;
use Test::Catch;

SKIP: {
    skip "MacOS X does not support debug info", 1 if $^O eq 'darwin';
    catch_run("[backtrace]");
};

done_testing;
