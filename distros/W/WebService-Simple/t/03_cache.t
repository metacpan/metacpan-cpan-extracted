use strict;
use Test::More;
use URI;
use URI::QueryParam;
use WebService::Simple;

subtest 'request_url has stable parameters order' => sub
{
    my $ws = WebService::Simple->new(
        base_url => 'http://example.com/',
	params   => { a => 1, b => 2 },
    );

    my $req;
    $ws->add_handler(request_send => sub {
        $req = shift;
        HTTP::Response->new(200, 'OK');
    });

    $ws->get();
    is($req->uri->as_string, 'http://example.com/?a=1&b=2');
    $ws->get({ c => 3 });
    is($req->uri->as_string, 'http://example.com/?a=1&b=2&c=3');
    $ws->get({ c => 3, d => 4 });
    is($req->uri->as_string, 'http://example.com/?a=1&b=2&c=3&d=4');
};

done_testing();
