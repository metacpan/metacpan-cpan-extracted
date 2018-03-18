use Test2::V0;
use Test2::API 'intercept';

my $events = intercept {
    do "./t/fixtures/before-after-all.t";
};

is $events, array {
    event 'Ok';
    event 'Subtest';
    event 'Subtest';
    event 'Ok';
    event 'Plan';
    end;
}, 'Events should have two Ok events at start and end';

subtest 'BeforeAll' => sub {
    my $event = $events->[0];
    ok $event->pass, 'Event should have passed';
    is $event->name, 'BeforeAll should be called as class method',
        'Event should have expected name';
};

subtest 'AfterAll' => sub {
    my $event = $events->[3];
    ok $event->pass, 'Event should have passed';
    is $event->name, 'AfterAll should be called as class method',
        'Event should have expected name';
};

done_testing;
