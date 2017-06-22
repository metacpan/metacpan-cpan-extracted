use Test2::V0;
use Test2::API qw/intercept/;
use Test2::Plugin::SourceDiag;

my $events = intercept {
    Test2::Plugin::SourceDiag->import(show_source => 0, inject_name => 1);

    ok(0);
};

is($events->[0]->name, "ok(0);", "Got the name");

$events = intercept {
    Test2::Plugin::SourceDiag->import(show_source => 0, inject_name => 1);

    ok(
        0
    );
};

is($events->[0]->name, "ok(\n        0\n    );", "Got the multi-line name");

done_testing;
