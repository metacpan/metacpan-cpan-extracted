use 5.012;
use warnings;
use Test::More;
use Test::Catch;
use lib 't/lib'; use MyTest;

catch_run('[captures]');

subtest "basic" => sub {
    my $r = URI::Router->new(
        "/1"                  => 1,
        "/2/*"                => 2,
        "/3/*/foo/*"          => 3,
        "/4/..."              => 4,
        "/5/*/foo/..."        => 5,
        qr#/6/(.+)#           => 6,
        qr#/7/(?:[^/]+)/(.+)# => 7,
    );
    
    is_deeply [$r->route("/1")], [1];
    is_deeply [$r->route("/2/hello")], [2, "hello"];
    is_deeply [$r->route("/3/hello/foo/world")], [3, "hello", "world"];
    is_deeply [$r->route("/4/hello")], [4, "hello"];
    is_deeply [$r->route("/4/hello/world")], [4, "hello", "world"];
    is_deeply [$r->route("/5/hello/foo/world")], [5, "hello", "world"];
    is_deeply [$r->route("/5/hello/foo/world/epta")], [5, "hello", "world", "epta"];
    is_deeply [$r->route("/6/foo")], [6, "foo"];
    is_deeply [$r->route("/6/foo/bar")], [6, "foo/bar"];
    is_deeply [$r->route("/7/foo/bar")], [7, "bar"];
    is_deeply [$r->route("/7/foo/bar/baz")], [7, "bar/baz"];
};

done_testing();
