use Test2::V0;
use Test2::API 'intercept';

my $events = intercept {
    do "./t/fixtures/before-each.it";
};

is $events, array {
    event 'Subtest';
    event 'Subtest';
    event 'Plan';
    end;
}, 'Events should contain two subtests then a plan';

for (0..1) {
    my $subevents = $events->[$_]->subevents;
    is $subevents, array {
        event 'Ok';
        event 'Ok';
        event 'Plan';
        end;
    }, "Subtest $_ should contain two Ok events then a plan";
    ok $subevents->[0]->pass, "First test should pass";
    ok $subevents->[1]->pass, "Second test should pass";
}

done_testing;
