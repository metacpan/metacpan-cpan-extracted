use strict;
use Test::More;
use Test::STF::MockServer;

BEGIN {
    eval {
        require LWP::UserAgent;
    };
    if ($@) {
        plan(skip_all => "LWP::UserAgent is not avaiable");
    }
}

{
    my $server = Test::STF::MockServer->new(
        plack_args => [ '-E' => 'test' ], # surpresses access log
    );
    my $bucket = $server->url_for("/test");
    my $url    = $server->url_for("/test/test.tx");
    note $url;

    my $ua = LWP::UserAgent->new;

    my $res;

    note "Creating bucket $bucket";
    $res = $ua->put($bucket);
    if (! is $res->code, 201) {
        diag $res->as_string;
    }

    note "Retrieve object $url (should fail)";
    $res = $ua->get($url);
    if (! is $res->code, 404) {
        diag $res->as_string;
    }

    note "Create object $url";
    $res = $ua->put($url, Content => "Hello, World!");
    if (! is $res->code, 201) {
        diag $res->as_string;
    }

    note "Retrieve object $url";
    $res = $ua->get($url);
    if (! is $res->code, 200) {
        diag $res->as_string;
    }
    is $res->content, "Hello, World!";

    note "Delete object $url";
    $res = $ua->delete($url);
    if (! is $res->code, 204) {
        diag $res->as_string;
    }

    note "Retrieve object $url (should fail)";
    $res = $ua->get($url);
    if (! is $res->code, 404) {
        diag $res->as_string;
    }

}

done_testing;