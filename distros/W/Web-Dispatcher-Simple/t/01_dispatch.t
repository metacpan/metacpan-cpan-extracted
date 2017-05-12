use Plack::Test;
use HTTP::Request;
use Test::More;

use Web::Dispatcher::Simple;
my $app = router {
    get '/get' => sub {
        my $req = shift;
        my $res = $req->new_response(200);
        $res->body('get');
        $res;
    },
    post '/post/{id}' => sub {
        my ( $req, $args ) = @_;
        my $id  = $args->{id};
        my $res = $req->new_response(200);
        $res->body('post');
        $res;
    },
    any [ 'GET', 'POST' ] => '/any1' => sub {
        my ( $req, $args ) = @_;
        my $res = $req->new_response(200);
        $res->body('any1');
        $res;
    },
    any [ 'POST' ] => '/any2' => sub {
        my ( $req, $args ) = @_;
        my $res = $req->new_response(200);
        $res->body('any2');
        $res;
    },
    any '/anyall' => sub {
        my ( $req, $args ) = @_;
        my $res = $req->new_response(200);
        $res->body('anyall');
        $res;
    },
    get '/server_error' => sub {
        my ( $req, $args ) = @_;
        die 'ooops'; 
    },
};

test_psgi $app, sub {
    my $cb  = shift;
    my $req = HTTP::Request->new( GET => q{http://localhost/get} );
    my $res = $cb->($req);

    is $res->code,    200;
    is $res->content, "get";
};

test_psgi $app, sub {
    my $cb  = shift;
    my $req = HTTP::Request->new( POST => q{http://localhost/post/1} );
    my $res = $cb->($req);

    is $res->code,    200;
    is $res->content, "post";
};

test_psgi $app, sub {
    my $cb  = shift;
    my $req = HTTP::Request->new( GET => q{http://localhost/any1} );
    my $res = $cb->($req);

    is $res->code,    200;
    is $res->content, "any1";
};

test_psgi $app, sub {
    my $cb  = shift;
    my $req = HTTP::Request->new( POST => q{http://localhost/any2} );
    my $res = $cb->($req);

    is $res->code,    200;
    is $res->content, "any2";
};

test_psgi $app, sub {
    my $cb  = shift;
    my $req = HTTP::Request->new( POST => q{http://localhost/anyall} );
    my $res = $cb->($req);

    is $res->code,    200;
    is $res->content, "anyall";
};

test_psgi $app, sub {
    my $cb  = shift;
    my $req = HTTP::Request->new( GET => q{http://localhost/not_found} );
    my $res = $cb->($req);

    is $res->code,    404;
    is $res->content, 'Not Found';
};

test_psgi $app, sub {
    my $cb  = shift;
    my $req = HTTP::Request->new( GET => q{http://localhost/server_error} );
    my $res = $cb->($req);

    is $res->code,    500;
    is $res->content, 'Internal Server Error';
};

done_testing;
