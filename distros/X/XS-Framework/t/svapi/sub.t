use 5.012;
use lib 't';
use MyTest;
use Test::Catch;

catch_run('[Sub]');

eval {
    MyTest::call_me(sub {die "1\n"});
};
is ($@, "1\n", 'correct rethrow');

done_testing();
