use 5.012;
use lib 't/lib'; use MyTest;
use lib 't/streamer'; use TestStreamer;

subtest 'normal input' => sub {
    my $test = UE::Test::Async->new(1);
    my $i = UE::Streamer::FileInput->new("t/streamer/file.txt", 10000);
    my $o = TestOutput->new(20000);
    my $s = UE::Streamer->new($i, $o, 100000, $test->loop);
    $s->start();
    $s->finish_callback(sub {
        my $err = shift;
        is $err, undef;
        $test->happens();
    });
    $test->run();
};

subtest 'normal output' => sub {
    UE::Fs::mkpath("t/var/streamer");
    my $test = UE::Test::Async->new(1);
    my $i = UE::Streamer::FileInput->new("t/streamer/file.txt", 10000);
    my $o = UE::Streamer::FileOutput->new("t/var/streamer/fout.txt");
    my $s = UE::Streamer->new($i, $o, 100000, $test->loop);
    $s->start();
    $s->finish_callback(sub {
        my $err = shift;
        is $err, undef;
        $test->happens();
    });
    $test->run();

    my $s1 = read_file("t/streamer/file.txt");
    my $s2 = read_file("t/var/streamer/fout.txt");
    is $s1, $s2;
};

sub read_file {
    my $path = shift;
    my $chunk_size = 1000000;
    my ($ret, $buf);
    my $fd = UE::Fs::open($path, UE::Fs::OPEN_RDONLY);
    do {
        $buf = UE::Fs::read($fd, $chunk_size);
        $ret += $buf;
    } while (length($buf) == $chunk_size);
    return $ret;
}

done_testing();