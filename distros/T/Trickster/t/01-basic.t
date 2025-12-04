use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;

use_ok('Trickster');

my $app = Trickster->new;

$app->get('/', sub {
    my ($req, $res) = @_;
    return "Hello, World!";
});

$app->get('/user/:id', sub {
    my ($req, $res) = @_;
    my $id = $req->env->{'trickster.params'}{id};
    return "User: $id";
});

my $test = test_psgi $app->to_app, sub {
    my $cb = shift;
    
    # Test root route
    my $res = $cb->(GET '/');
    is $res->code, 200, 'GET / returns 200';
    is $res->content, 'Hello, World!', 'GET / returns correct content';
    
    # Test parameterized route
    $res = $cb->(GET '/user/123');
    is $res->code, 200, 'GET /user/123 returns 200';
    is $res->content, 'User: 123', 'GET /user/123 returns correct content';
    
    # Test 404
    $res = $cb->(GET '/nonexistent');
    is $res->code, 404, 'GET /nonexistent returns 404';
};

done_testing;
