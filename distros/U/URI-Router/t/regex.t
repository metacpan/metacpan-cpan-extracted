use 5.012;
use warnings;
use Test::More;
use Test::Catch;
use lib 't/lib'; use MyTest;

catch_run('[regex]');

subtest "basic" => sub {
    my $r = URI::Router->new(
        qr#/user/\d+#i => 1,
        qr#/user/\d+a?# => 2,
    );

    is $r->route("/user/1"), 1;
    is $r->route("/user/1111"), 1;
    is $r->route("/user"), undef;
    is $r->route("/user/"), undef;
    is $r->route("/user/a"), undef;
    is $r->route("/user/123a"), 2;
    is $r->route("/user/123/a"), undef;
};

done_testing();
