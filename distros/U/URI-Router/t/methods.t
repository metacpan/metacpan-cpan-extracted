use 5.012;
use warnings;
use Test::More;
use Test::Catch;
use URI::Router;
use lib 't/lib'; use MyTest;

catch_run('[methods]');

subtest "method configure in path" => sub {
    my $r = URI::Router->new(
        "OPTIONS/path1" => 11,
        "GET/path2"     => 22,
        "HEAD/path3"    => 33,
        "POST/path4"    => 44,
        "PUT/path5"     => 55,
        "DELETE/path6"  => 66,
        "TRACE/path7"   => 77,
        "CONNECT/path8" => 88,
    );

    is $r->route("/path1", METHOD_OPTIONS), 11;
    is $r->route("/path1", METHOD_GET), undef;

    is $r->route("/path2", METHOD_GET), 22;
    is $r->route("/path2", METHOD_HEAD), undef;

    is $r->route("/path3", METHOD_HEAD), 33;
    is $r->route("/path3", METHOD_POST), undef;

    is $r->route("/path4", METHOD_POST), 44;
    is $r->route("/path4", METHOD_PUT), undef;

    is $r->route("/path5", METHOD_PUT), 55;
    is $r->route("/path5", METHOD_DELETE), undef;

    is $r->route("/path6", METHOD_DELETE), 66;
    is $r->route("/path6", METHOD_TRACE), undef;

    is $r->route("/path7", METHOD_TRACE), 77;
    is $r->route("/path7", METHOD_CONNECT), undef;

    is $r->route("/path8", METHOD_CONNECT), 88;
    is $r->route("/path8", METHOD_OPTIONS), undef;
};

done_testing();
