use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common qw(GET POST PUT PATCH DELETE);

use_ok('Trickster');

my $app = Trickster->new;

$app->get('/resource', sub { return "GET" });
$app->post('/resource', sub { return "POST" });
$app->put('/resource', sub { return "PUT" });
$app->patch('/resource', sub { return "PATCH" });
$app->delete('/resource', sub { return "DELETE" });

my $test = test_psgi $app->to_app, sub {
    my $cb = shift;
    
    my $res = $cb->(GET '/resource');
    is $res->content, 'GET', 'GET method works';
    
    $res = $cb->(POST '/resource');
    is $res->content, 'POST', 'POST method works';
    
    $res = $cb->(PUT '/resource');
    is $res->content, 'PUT', 'PUT method works';
    
    $res = $cb->(PATCH '/resource');
    is $res->content, 'PATCH', 'PATCH method works';
    
    $res = $cb->(DELETE '/resource');
    is $res->content, 'DELETE', 'DELETE method works';
};

done_testing;
