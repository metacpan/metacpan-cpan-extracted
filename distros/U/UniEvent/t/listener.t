use 5.012;
use warnings;
use lib 't/lib'; use MyTest;
use UniEvent::Signal;

{
    package Lst;
    our $cnt;
    our $dcnt = 0;
    sub new { bless {}, shift }
    sub on_check { $cnt++ }
    sub DESTROY { $dcnt++ }
    
    sub reset { $dcnt = 0 }
    
    package Lst2;
    our @ISA = 'Lst';
    sub on_check { $Lst::cnt += 1000 }
}

sub check_dtor (&);

my $l = UniEvent::Loop->default_loop;

subtest 'hold' => sub {
    my $h = new UE::Check;
    $h->event_listener(Lst->new);
    check_call($h);
    check_dtor { undef $h };
};
Lst::reset();

subtest 'get' => sub {
    my $h = new UE::Check;
    is $h->event_listener, undef, "returns undef when no listener";
    my $lst = Lst->new;
    $h->event_listener($lst);
    is $h->event_listener, $lst, "get";
    is $h->event_listener, $lst, "previous call did not set value";
    undef $lst;
    check_call($h);
    check_dtor { undef $h };    
};
Lst::reset();

subtest 'change' => sub {
    my $h = new UE::Check;
    $h->event_listener(Lst->new);
    check_call($h);
    check_dtor { $h->event_listener(Lst2->new) };
    check_call($h, 1000);
};
Lst::reset();

subtest 'remove' => sub {
    my $h = new UE::Check;
    $h->event_listener(Lst->new);
    check_call($h);
    check_dtor { $h->event_listener(undef) };
    check_call($h, 0);
};
Lst::reset();

subtest 'self listener' => sub {
    no warnings 'once';
    subtest 'leak' => sub {
        my $h = new UE::Check;
        $h->event_listener($h);
        $h->start;
        $h = undef;
        ok !$l->run_nowait, "handle not leaked";
    };
    subtest 'without first arg' => sub {
        my @args;
        local *UniEvent::Signal::on_signal = sub { shift; @args = @_ };
        my $h = new UE::Signal;
        $h->event_listener($h);
        $h->call_now(SIGHUP());
        cmp_deeply \@args, [SIGHUP()], "args without object";
    } unless win32();
};

subtest 'weak' => sub {
    my $h = new UE::Check;
    check_dtor { $h->event_listener(Lst->new, 1) };
    $h->start;
    dies_ok { $l->run_nowait };
    $h->event_listener(undef);
    $l->run_nowait;
    check_call($h, 0);
};

sub check_dtor (&) {
    my $cb = shift;
    is $Lst::dcnt, 0, "check_dtor before";
    $cb->();
    is $Lst::dcnt, 1, "check_dtor after";
    Lst::reset();
}

sub check_call {
    my ($h, $num) = @_;
    $num //= 1;
    my $cnt = 0;
    $Lst::cnt = 0;
    $h->start;
    $h->callback(sub { ++$cnt });
    $h->loop->run_nowait;
    is $Lst::cnt, $num, "check call 1";
    is $cnt, 1, "check call 2";
}

done_testing();
