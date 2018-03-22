use Test2::V0;
use Test2::API 'intercept';

my $events = intercept {
    do "./t/fixtures/after-each.it";
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
        event 'Ok';
        event 'Ok';
        event 'Plan';
        end;
    }, "Subtest $_ should contain four Ok events then a plan";
    for my $subevent (0..3) {
        ok $subevents->[$subevent]->pass, 'Ok event should have passed';
    }
}

done_testing;
