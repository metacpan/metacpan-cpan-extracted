use Test2::V0;
use Test2::API 'intercept';

my $events = intercept {
    do './t/fixtures/instance-lifecycle.t';
};

is $events, array {
    event 'Subtest';
    event 'Subtest';
    event 'Subtest';
    event 'Plan';
    end;
}, 'Events should contain three subtests then a plan';

# The fact that all three tests pass shows that we are creating a separate
# instance per test method.
for (0..2) {
    is $events->[$_]->subevents, array {
        event 'Ok';
        event 'Plan';
        end;
    }, "Subtest $_ should contain one Ok event then a plan";
    ok $events->[$_]->subevents->[0]->pass, "Assertion should pass";
}

done_testing;
