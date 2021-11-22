use 5.012;
use warnings;
use Test::More;
use Test::Catch;
use lib 't/lib'; use MyTest;

catch_run('[static]');

subtest "basic" => sub {
    my $r = URI::Router->new(
        "/my/path"     => 1,
        "/hello/world" => 2,
        "/my/world"    => 3,
        "/"            => 4,
    );

    is $r->route("/my/path"), 1;
    is $r->route("/hello/world"), 2;
    is $r->route("/my/world"), 3;
    is $r->route("/"), 4;
    is $r->route(""), 4;
};

done_testing();
