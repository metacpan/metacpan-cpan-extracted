use 5.016;
use warnings;
use lib 't/lib'; use MyTest;

test_catch '[loop]';

subtest 'basic' => sub {
    my $loop = UniEvent::Loop->new();
    is ref $loop, 'UniEvent::Loop';
    ok !$loop->alive, 'no handles yet in loop';
    ok !$loop->is_default, 'this loop is not default';
    ok !$loop->is_global, 'this loop is not global';
};

subtest 'now/update_time' => sub {
    my $loop = UniEvent::Loop->new();
    my $now = $loop->now;
    select undef, undef, undef, 0.01;
    is $now, $loop->now, 'now isnt changed until update_time';
    $loop->update_time;
    isnt $now, $loop->now, 'now changes after update_time';
};

subtest 'default loop' => sub {
    my $loop = UniEvent::Loop->default;
    is(ref $loop, 'UniEvent::Loop');
    ok $loop->is_default, 'this loop is default';
    ok $loop->is_global, 'this loop is global';
    is(UniEvent::Loop->default, UniEvent::Loop->default, "default loop returns the same");
    is(UniEvent::Loop->global, UniEvent::Loop->global, "global loop returns the same");
    is(UniEvent::Loop->global, UniEvent::Loop->default, "global loop is the same as default loop in main thread");
    
    ok(UE::Check->new()->loop->is_default, "no loop in handle ctor is default loop");
    ok(UE::Check->new(undef)->loop->is_default, "undef loop in handle ctor is default loop");
};

my $loop = UniEvent::Loop->default;

subtest 'handles' => sub {
    my $loop = new UniEvent::Loop;
    cmp_deeply $loop->handles, [], "no handles in fresh loop";
    
    my @h = map { new UniEvent::Prepare($loop) } 1..3;
    is scalar @{$loop->handles}, 3, "handles count ok";
    foreach my $h (@{$loop->handles}) {
        is ref($h), 'UniEvent::Prepare', 'handle class ok';
    }
    undef @h;
    
    cmp_deeply $loop->handles, [], "no handles left";
};

subtest 'run/stop' => sub {
    alarm(1);
    ok !$loop->run_once, 'run_once';
    ok !$loop->run, 'run';
    ok !$loop->run_nowait, 'run_nowait';
    
    my $h = new UniEvent::Prepare;
    $h->start(sub {
        ok $loop->alive;
        $loop->stop;
    });
    ok $loop->run;
    alarm(0);
};

subtest 'delay' => sub {
    subtest 'simple' => sub {
        my $i = 0;
        $loop->delay(sub { $i++ });
        $loop->run_nowait for 1..3;
        is $i, 1, 'called once';
    };
    subtest 'recursive' => sub {
        my $i = 0;
        $loop->delay(sub { $i++ });
        $loop->run_nowait for 1..3;
        $loop->delay(sub {
            $i += 10;
            $loop->delay(sub { $i += 100 });
        });
        $loop->run_nowait for 1..3;
        is $i, 111, 'called';
    };
    subtest 'cancel delay' => sub {
        my $i = 0;
        my $mark = $loop->delay(sub { $i++ });
        $loop->cancel_delay($mark) for 1..2;
        $loop->run_nowait for 1..3;
        is $i, 0, 'delay canceled';
        
        $loop->cancel_delay($mark);
        undef $mark;
    };
    subtest 'autocancel delay' => sub {
        my $i = 0;
        my $mark = $loop->delay(sub { $i++ });
        undef $mark;
        $loop->run_nowait for 1..3;
        is $i, 0, 'delay autocanceled';
    };
    subtest 'mark survives the loop' => sub {
        my $loop = UE::Loop->new;
        my $i = 0;
        my $mark = $loop->delay(sub { $i++ });
        undef $loop;
        is $i, 0, 'delay autocanceled';
        undef $mark; # ignore
    };
};

subtest 'CLONE_SKIP' => sub {
    is UniEvent::Loop::CLONE_SKIP(), 1;
};

subtest 'kill mortals after loop iteration' => sub {
    {
        package MyMortal;
        our $dcnt = 0;
        sub DESTROY { ++$dcnt }
    }
    
    my $test = sub {
        my $loop = shift;
        my $cnt = $MyMortal::dcnt = 0;
        my $cb = sub {
            if (++$cnt >= 10) {
                cmp_ok $MyMortal::dcnt, '>=', $cnt-1;
                return;
            }
            MyTest::set_loop_callback_with_mortal($loop, __SUB__);
        };
        
        MyTest::set_loop_callback_with_mortal($loop, $cb);
        $loop->run;
    };
    
    subtest "default loop" => $test, UE::Loop->default_loop;
    subtest "global loop"  => $test, UE::Loop->global_loop;
};

done_testing();
