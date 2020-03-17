use 5.012;
use warnings;
use lib 't/lib'; use MyTest;

catch_run('[handle]');

subtest 'CLONE_SKIP' => sub {
    ok(UniEvent::Handle::CLONE_SKIP());
    ok(UniEvent::Handle->CLONE_SKIP());
};

subtest 'loop()' => sub {
    my $l = new UniEvent::Loop();
    my $t = new UniEvent::Timer($l);
    is($t->loop, $l, "handle belongs to another loop and refs are the same as XSBackref is in effect");
    $l = UniEvent::Loop->default;
    $t = new UniEvent::Timer;
    ok($t->loop->is_default, "handle belongs to default loop");
};

subtest 'type' => sub {
    my $t = new UniEvent::Timer;
    is($t->type, UniEvent::Timer::TYPE, "type works");
};

subtest 'active' => sub {
    my $l = new UniEvent::Loop;
    my $t = new UniEvent::Timer($l);
    $t->event->add(sub {shift->stop});
    ok(!$t->active, "not started handle is non-active");
    $t->start(0.01);
    ok($t->active, "started handle is active");
    $l->run; # timer stops himself on callback
    ok(!$t->active, "stopped handle is not active");
};

subtest 'weak' => sub {
    my $l = new UniEvent::Loop;
    my $h = new UniEvent::Prepare($l);
    my $i = 0;
    $h->event->add(sub {shift->loop->stop; ++$i});
    ok !$h->weak, "by default, handle is non-weak";
    $h->start;
    $l->run;
    is $i, 1, "non-weak handle doesn't allow loop to bail out";
    $h->weak(1);
    ok $h->weak, "handle is now weak";
    $h->start;
    $l->run;
    is $i, 1, "loop without any non-weak handles, bails out immediately";
};

done_testing();
