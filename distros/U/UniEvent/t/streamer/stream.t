use 5.012;
use lib 't/lib'; use MyTest;
use lib 't/streamer'; use TestStreamer;

test_catch '[streamer-stream]';

subtest 'normal input' => sub {
    my $test = UE::Test::Async->new(1);
    my $p = make_pair($test->loop, 10, 10);
    my $i = UE::Streamer::StreamInput->new($p->{sconn});
    my $o = TestOutput->new(20000);
    my $s = UE::Streamer->new($i, $o, 100000, $test->loop);
    $s->start();
    $s->finish_callback(sub {
        my $err = shift;
        is $err, undef;
        $test->happens();
        $test->loop->stop();
    });
    $test->run();
};

subtest 'normal output' => sub {
    my $test = UE::Test::Async->new(2);
    my $p2 = MyTest::make_p2p($test->loop);
    my $p1 = make_pair($test->loop, 10000, 20);
    my $i = UE::Streamer::StreamInput->new($p1->{sconn});
    my $o = UE::Streamer::StreamOutput->new($p2->{sconn});
    my $s = UE::Streamer->new($i, $o, 50000, $test->loop);
    $s->start();
    $s->finish_callback(sub {
        my $err = shift;
        is $err, undef;
        $test->happens();
        $p2->{sconn}->disconnect();
    });

    my $res;
    $p2->{client}->read_callback(sub {
        die $_[2] if $_[2];
        $res .= $_[1];
    });
    $p2->{client}->eof_callback(sub {
        $test->happens();
        $test->loop->stop();
    });
    $test->run();

    is $res, 'x' x 200000;
};

done_testing();

sub make_pair {
    my ($loop, $amount, $count) = @_;
    my $p = MyTest::make_p2p($loop);
    my $cnt = 0;
    my $t = UE::Timer->new($loop);
    $t->callback(sub {
        $p->{client}->write('x' x $amount);
        if (++$cnt == $count) {
            $t = undef;
            $p->{client}->disconnect();
        }
    });
    $t->start(0.001);
    return $p;
}
