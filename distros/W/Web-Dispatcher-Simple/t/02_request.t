use Plack::Test;
use HTTP::Request;
use Test::More;

use Web::Dispatcher::Simple;
my $app = router {
    get '/relative' => sub {
        my $req = shift;
        my $abs_url = $req->uri_for('/relative');
        my $res = $req->new_response(200);
        $res->body($abs_url->as_string);
        $res;
    },
};

test_psgi $app, sub {
    my $cb  = shift;
    my $req = HTTP::Request->new( GET => q{http://localhost/relative} );
    my $res = $cb->($req);

    is $res->code,    200;
    is $res->content, "http://localhost/relative";
};

done_testing;
