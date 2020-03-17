use 5.012;
use warnings;
use lib 't/lib'; use MyTest;

catch_run('[prepare]');

my $l = UniEvent::Loop->default_loop;

subtest 'start/stop/reset' => sub {
    my $h = new UniEvent::Prepare;
    is $h->type, UniEvent::Prepare::TYPE, 'type ok';
    
    my $i = 0;
    $h->start(sub { $i++ });
    ok $l->run_nowait, 'holds loop';
    is $i, 1, 'prepare works';
    
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

subtest 'call_now' => sub {
    my $h = new UniEvent::Prepare;
    my $i = 0;
    $h->event->add(sub { $i++ });
    $h->call_now for 1..5;
    is $i, 5;
};

subtest 'event listener' => sub {
    no warnings 'once';
    my $cnt;
    *MyLst::on_prepare = sub { $cnt += 10 };
    my $h = new UniEvent::Prepare;
    $h->event_listener(bless {}, 'MyLst');
    $h->callback(sub { $cnt++ });
    
    $h->call_now;
    is $cnt, 11, "listener&event called";
};

done_testing();
