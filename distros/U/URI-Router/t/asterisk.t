use 5.012;
use warnings;
use Test::More;
use Test::Catch;
use lib 't/lib'; use MyTest;

catch_run('[asterisk]');

subtest "basic" => sub {
    my $r = URI::Router->new(
        "/jopa/*" => 1,
        "/hello/world" => 2,
    );

    is $r->route("/jopa/abc"), 1;
    is $r->route("/jopa/def"), 1;
    is $r->route("/a"), undef;
    is $r->route("/jopa"), undef;
    is $r->route("/hello/world"), 2;
};

done_testing();
