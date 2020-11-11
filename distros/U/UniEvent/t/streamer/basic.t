use 5.012;
use lib 't/lib'; use MyTest;
use lib 't/streamer'; use TestStreamer;

subtest 'normal' => sub {
    my $test = UE::Test::Async->new(1);
    my $i = TestInput->new(20, 1);
    my $o = TestOutput->new(2);
    my $s = UE::Streamer->new($i, $o, 5, $test->loop);
    $s->start();
    $s->finish_callback(sub {
        my $err = shift;
        is $err, undef;
        $test->happens;
    });
    $test->run();
    is $i->{stop_reading_cnt}, 0;
    is @{$o->{bufs}}, 0;
};


subtest 'pause input' => sub {
    my $test = UE::Test::Async->new(1);
    my $i = TestInput->new(100, 20);
    my $o = TestOutput->new(1);
    my $s = UE::Streamer->new($i, $o, 30, $test->loop);
    $s->start();
    $s->finish_callback(sub {
        my $err = shift;
        is $err, undef;
        $test->happens;
    });
    $test->run();
    cmp_ok $i->{stop_reading_cnt}, '>', 0;
    is @{$o->{bufs}}, 0;
};

subtest 'stop' => sub {
    my $test = UE::Test::Async->new(1);
    my $i = TestInput->new(300, 4);
    my $o = TestOutput->new(2);
    my $s = UE::Streamer->new($i, $o, 0, $test->loop);
    $s->start();
    $s->finish_callback(sub {
        my $err = shift;
        is $err, XS::STL::errc::operation_canceled;
        $test->happens;
    });
    $s->stop();
    $test->run();
};

done_testing();



