use Test2::V0;
use Test2::API 'intercept';

my $events = intercept {
    do './t/fixtures/no-new-method.it';
};

is $events, array {
    event 'Subtest';
    event 'Subtest';
    event 'Plan';
    end;
}, 'Events should contain two subtests then a plan';

for (0..1) {
    is $events->[$_]->subevents, array {
        event 'Ok';
        event 'Plan';
        end;
    }, "Subtest $_ should contain one Ok event then a plan";
    ok $events->[$_]->subevents->[0]->pass, "Assertion should pass";
}

done_testing;
