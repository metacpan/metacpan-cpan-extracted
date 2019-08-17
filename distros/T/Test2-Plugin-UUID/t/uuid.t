use Test2::Plugin::UUID;
use Test2::V0;
use Test2::API qw/intercept context/;

my $events = intercept {
    sub { ok(1) }->();
};

my $uuidrx = qr/^[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}$/;

like(
    $events->[0],
    hash {
        field uuid  => $uuidrx;
        field trace => {uuid => $uuidrx, huuid => $uuidrx};
        field hubs  => [{uuid => $uuidrx}];
        etc;
    },
    "Used uuids"
);

done_testing;
