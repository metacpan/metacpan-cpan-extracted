use Test::Modern;
use t::lib::Common qw(skip_unless_has_secret stripe);

skip_unless_has_secret;

subtest 'get events' => sub {
    my $events = stripe->get_events;
    cmp_deeply $events => TD->superhashof({
        data   => TD->supersetof(),
        object => 'list',
        url    => '/v1/events',
    });
};

done_testing;
