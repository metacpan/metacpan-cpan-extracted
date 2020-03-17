use 5.012;
use warnings;
use lib 't/lib'; use MyTest;

catch_run('[check]');

my $l = UniEvent::Loop->default_loop;

subtest 'start/stop/reset' => sub {
    my $h = new UniEvent::Check;
    is $h->type, UniEvent::Check::TYPE, 'type ok';
    
    my $i = 0;
    $h->event->add(sub { $i++ });
    $h->start;
    ok $l->run_nowait, 'holds loop';
    is $i, 1, 'check works';
    
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

subtest 'runs after prepare' => sub {
    my $i = 0;
    my $p = new UniEvent::Prepare;
    $p->start(sub { $i++ });
    my $c = new UniEvent::Check;
    $c->start(sub {
        is $i, 1, 'after prepare';
        $i += 10;
    });
    $l->run_nowait;
    is $i, 11, 'called';
};

subtest 'call_now' => sub {
    my $h = new UniEvent::Check;
    my $i = 0;
    $h->event->add(sub { $i++ });
    $h->call_now for 1..5;
    is $i, 5;
};

subtest 'event listener' => sub {
    no warnings 'once';
    my $cnt;
    *MyLst::on_check = sub { $cnt += 10 };
    my $h = new UE::Check;
    $h->event_listener(bless {}, 'MyLst');
    $h->callback(sub { $cnt++ });
    
    $h->call_now;
    is $cnt, 11, "listener&event called";
};

done_testing();
