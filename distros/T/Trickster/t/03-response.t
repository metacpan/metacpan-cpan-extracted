use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use JSON::PP;

use_ok('Trickster');
use_ok('Trickster::Response');

my $app = Trickster->new;

$app->get('/json', sub {
    my ($req, $res) = @_;
    $res = Trickster::Response->new;
    return $res->json({ message => 'Hello' });
});

$app->get('/text', sub {
    my ($req, $res) = @_;
    $res = Trickster::Response->new;
    return $res->text('Plain text');
});

$app->get('/redirect', sub {
    my ($req, $res) = @_;
    $res = Trickster::Response->new;
    return $res->redirect('/new-location');
});

my $test = test_psgi $app->to_app, sub {
    my $cb = shift;
    
    # Test JSON response
    my $res = $cb->(GET '/json');
    is $res->code, 200, 'JSON response returns 200';
    like $res->header('Content-Type'), qr{application/json}, 'JSON content type';
    my $data = decode_json($res->content);
    is $data->{message}, 'Hello', 'JSON data is correct';
    
    # Test text response
    $res = $cb->(GET '/text');
    is $res->code, 200, 'Text response returns 200';
    like $res->header('Content-Type'), qr{text/plain}, 'Text content type';
    is $res->content, 'Plain text', 'Text content is correct';
    
    # Test redirect
    $res = $cb->(GET '/redirect');
    is $res->code, 302, 'Redirect returns 302';
    is $res->header('Location'), '/new-location', 'Redirect location is correct';
};

done_testing;
