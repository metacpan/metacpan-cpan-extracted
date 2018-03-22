use Test2::V0;
use Test2::API 'intercept';

my $events = intercept {
    do "./t/fixtures/attribute-todo.it";
};

is $events, array {
    event 'Subtest';
    event 'Subtest';
    event 'Subtest';
    event 'Subtest';
    event 'Plan';
    end;
}, 'Events should contain four subtests then a plan';

subtest 'Failing Todo' => sub {
    my $subevents = $events->[0]->subevents;
    is $subevents, array {
        event 'Ok';
        event 'Note';
        event 'Plan';
        end;
    }, 'Failing todo should produce appropriate events';
    is $subevents->[0]->pass,           0, "Ok event should not have passed";
    is $subevents->[0]->effective_pass, 1, "Ok event should effectively pass";
};

subtest 'With no Test attribute' => sub {
    my $subevents = $events->[1]->subevents;
    is $subevents, array {
        event 'Ok';
        event 'Plan';
        end;
    }, 'Todo with no :Test should produce appropriate events';
    is $subevents->[0]->pass,           1, "Ok event should have passed";
    is $subevents->[0]->effective_pass, 1, "Ok event should effectively pass";
};

subtest 'With no reason' => sub {
    my $subevents = $events->[2]->subevents;
    is $subevents, array {
        event 'Ok';
        event 'Plan';
        end;
    }, 'Todo with no reason should produce appropriate events';
    is $subevents->[0]->pass,           1, "Ok event should have passed";
    is $subevents->[0]->effective_pass, 1, "Ok event should effectively pass";
    is $subevents->[0]->todo, 'todo_with_no_reason',
        "Todo reason should default to name of the method";
};

subtest 'With reason' => sub {
    my $subevents = $events->[3]->subevents;
    is $subevents, array {
        event 'Ok';
        event 'Plan';
        end;
    }, 'Should produce appropriate events';
    is $subevents->[0]->pass,           1, "Ok event should have passed";
    is $subevents->[0]->effective_pass, 1, "Ok event should effectively pass";
    is $subevents->[0]->todo, 'some reason',
        "Todo reason should be as given in the attribute";
};

done_testing;
