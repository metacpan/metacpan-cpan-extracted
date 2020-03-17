use 5.012;
use warnings;
use lib 't/lib'; use MyTest;
use UniEvent;

my $loop = UniEvent::Loop->default_loop;

*spair = \&UniEvent::Tcp::pair;

subtest 'basic' => sub {
    test_pair(spair(), $loop);
};

subtest 'custom loop' => sub {
    my $loop = UE::Loop->new;
    test_pair(spair({loop => $loop}), $loop);
    test_pair(spair($loop), $loop);
};

subtest 'custom handles' => sub {
    subtest 'one' => sub {
        my $_h1 = UE::Tcp->new;
        my ($h1, $h2) = spair({handle1 => $_h1});
        is $h1, $_h1;
        test_pair($h1, $h2, $loop);
    };
    subtest 'both' => sub {
        my $_h1 = UE::Tcp->new;
        my $_h2 = UE::Tcp->new;
        my ($h1, $h2) = spair({handle1 => $_h1, handle2 => $_h2});
        is $h1, $_h1;
        is $h2, $_h2;
        test_pair($h1, $h2, $loop);
    };
};

subtest 'error' => sub {
    subtest 'wrong domain' => sub {
        dies_ok { spair({domain => AF_INET}) };
    };
};

sub test_pair {
    my ($h1, $h2, $loop) = @_;
    my $cnt;
    
    $h1->read_callback(sub {
        my ($self, $buf, $err) = @_;
        ok !$err;
        $self->write("epta") if $buf eq 'suka';
        $cnt++;
    });
    $h2->read_callback(sub {
        my ($self, $buf, $err) = @_;
        ok !$err;
        is $buf, "epta";
        $loop->stop;
        $cnt++;
    });
    $h2->write("suka");
    $loop->run;
    is $cnt, 2;

    SKIP: {
        skip "shutdown() doesn't trigger EOF on socketpair in Windows WSL" if winWSL();
        $cnt = 0;
        $h1->shutdown;
        $h2->eof_callback(sub { $cnt++; shift->shutdown });
        $h1->eof_callback(sub { $cnt++; $loop->stop });
        $loop->run;
        is $cnt, 2;
    }
}

done_testing();
