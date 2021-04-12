use 5.012;
use warnings;
use lib 't/lib'; use MyTest;

test_catch '[idle]';

my $l = UniEvent::Loop->default_loop;

subtest 'start/stop/reset' => sub {
    my $h = new UniEvent::Idle;
    is $h->type, UniEvent::Idle::TYPE, 'type ok';
    
    my $i = 0;
    $h->start(sub { $i++ });
    ok $l->run_nowait, 'holds loop';
    is $i, 1, 'idle works';
    
    $h->stop;
    ok !$l->run_nowait, 'stopped';
    is $i, 1, 'stop works';
    
    $h->start;
    ok $l->run_nowait;
    is $i, 2, 'started again';

    $h->reset;
    ok !$l->run_nowait;
    is $i, 2, 'reset works';
};

subtest 'runs rarely when loop is high loaded' => sub {
    my $t = new UniEvent::Timer;
    $t->event->add(sub { $l->stop if ++(state $j) % 10 == 0 });
    $t->start(0.001);
    
    my $i = 0;
    my $h = new UniEvent::Idle;
    $h->start(sub { $i++ });
    $l->run;
    
    my $low_loaded_cnt = $i;
    $i = 0;
    
    my @a;
    for (0..10000) {
        my $tt = new UniEvent::Timer;
        push @a, $tt;
        $tt->event->add(sub {});
        $tt->start(0.001);
    }

    $l->run;
    cmp_ok($i, '<', $low_loaded_cnt, "runs rarely");
    my $high_loaded_cnt = $i;
    $i = 0;
    undef @a;
    $l->run;
    
    cmp_ok($i, '>', $high_loaded_cnt, "runs often again");
};

subtest 'call_now' => sub {
    my $h = new UniEvent::Idle;
    my $i = 0;
    $h->event->add(sub { $i++ });
    $h->call_now for 1..5;
    is $i, 5;
};

subtest 'event listener' => sub {
    no warnings 'once';
    my $cnt;
    *MyLst::on_idle = sub { $cnt += 10 };
    my $h = new UE::Idle;
    $h->event_listener(bless {}, 'MyLst');
    $h->callback(sub { $cnt++ });
    
    $h->call_now;
    is $cnt, 11, "listener&event called";
};

subtest 'static ctor' => sub {
    my $i;
    my $h1 = UE::Idle->create(sub {$i++});
    my $h2 = UE::idle sub {$i+=10};
    $l->run_nowait;
    is $i, 11;
};

done_testing();
