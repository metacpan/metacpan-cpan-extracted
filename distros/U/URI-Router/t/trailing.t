use 5.012;
use warnings;
use Test::More;
use Test::Catch;
use lib 't/lib'; use MyTest;

catch_run('[trailing]');

subtest "basic" => sub {
    my $r = URI::Router->new(
        "/jopa/..." => 1,
        "/hello/world" => 2,
    );

    is $r->route("/jopa/"), 1;
    is $r->route("/jopa/abc"), 1;
    is $r->route("/jopa/abc/def"), 1;
    is $r->route("/jopa/abc/def/xyz"), 1;
    is $r->route("/a"), undef;
    is $r->route("/hello/world"), 2;
};

done_testing();
