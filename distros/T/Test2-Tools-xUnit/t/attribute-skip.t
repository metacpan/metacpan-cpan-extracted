use Test2::V0;
use Test2::API 'intercept';

my $events = intercept {
    do "./t/fixtures/attribute-skip.t";
};

is $events, array {
    event 'Skip';
    event 'Skip';
    event 'Skip';
    event 'Plan';
    end;
}, 'Events should contain three skipped tests then a plan';

done_testing;
