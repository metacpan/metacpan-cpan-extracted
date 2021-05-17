use 5.012;
use lib 't/lib';
use MyTest;
use Test::More;

variate_catch('[server-keep-alive]', 'ssl');

subtest "idle timeout" => sub {
    my $test = new UE::Test::Async();
    time_mark();
    $test->loop->update_time;
    my $p    = new MyTest::ServerPair($test->loop, {idle_timeout => 0.01});
    ok $p->wait_eof(1), "got eof";
    cmp_ok time_elapsed(), '>=', 0.01, "disconnected after idle_timeout";
};

done_testing();
