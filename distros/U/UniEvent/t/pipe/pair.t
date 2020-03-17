use 5.012;
use warnings;
use lib 't/lib'; use MyTest;
use UniEvent;

my $loop = UniEvent::Loop->default_loop;

*ppair = \&UniEvent::Pipe::pair;

subtest 'basic' => sub {
    test_pair(ppair(), $loop);
};

subtest 'custom loop' => sub {
    my $loop = UE::Loop->new;
    test_pair(ppair($loop), $loop);
};

subtest 'custom handles' => sub {
    subtest 'one' => sub {
        my $_r = UE::Pipe->new;
        my ($r, $w) = ppair($_r, undef);
        is $r, $_r;
        test_pair($r, $w, $loop);
    };
    subtest 'both' => sub {
        my $_r = UE::Pipe->new;
        my $_w = UE::Pipe->new;
        my ($r, $w) = ppair($_r, $_w);
        is $r, $_r;
        is $w, $_w;
        test_pair($r, $w, $loop);
    };
};

subtest 'error' => sub {
    subtest 'ipc' => sub {
        my $h = UE::Pipe->new(undef, 1);
        dies_ok { ppair($h, undef) };
    };
};

sub test_pair {
    my ($reader, $writer, $loop) = @_;
    my $cnt;
    
    $reader->read_callback(sub {
        my ($self, $buf, $err) = @_;
        ok !$err;
        $loop->stop;
        $cnt++;
    });
    $writer->write("suka");
    $writer->write_callback(sub { ok !$_[1] });
    $loop->run;
    is $cnt, 1;
}

done_testing();
