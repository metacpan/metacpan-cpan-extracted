use strict;
use warnings;
use utf8;
use Test::More;
use Test::Needs 'HTTP::Request';
use WWW::OAuth::Util 'form_urlencode';

use WWW::OAuth::Request::HTTP_Request;

my $http_request = HTTP::Request->new(GET => 'http://example.com');
my $req = WWW::OAuth::Request::HTTP_Request->new(request => $http_request);

is $req->method, 'GET', 'method is GET';
$req->method('POST');
is $req->method, 'POST', 'method is POST';

is $req->url, 'http://example.com', 'url is set';
$req->url('https://example.com?foo=bar');
is $req->url, 'https://example.com?foo=bar', 'url is changed';

is $req->content, '', 'content is not set';
$req->content('foo=bar&baz=1');
is $req->content, 'foo=bar&baz=1', 'content is set';

is $req->header('FooBar'), undef, 'header FooBar is not set';
$req->header(FooBar => '☃');
is $req->header('FooBar'), '☃', 'header FooBar is set';
is $req->header('FOOBAR'), '☃', 'header FOOBAR is set';
is $req->header('foobar'), '☃', 'header foobar is set';

ok !$req->content_is_form, 'content is not a form';
$req->header('content-type' => 'application/x-www-form-urlencoded');
ok $req->content_is_form, 'content is a form';
$req->header('content-type' => 'application/not-a-form');
ok !$req->content_is_form, 'content is not a form';
$req->header('Content-Type' => 'application/x-www-form-urlencoded');
ok $req->content_is_form, 'content is a form';
$req->request->parts(HTTP::Message->new, HTTP::Message->new);
ok !$req->content_is_form, 'content is not a form';

is $req->header('MultiFoo'), undef, 'header MultiFoo is not set';
$req->header(MultiFoo => ['a', 'b', 'c']);
is $req->header('MultiFoo'), 'a, b, c', 'header MultiFoo has multiple values';
$req->header(MultiFoo => 'abc');
is $req->header('MultiFoo'), 'abc', 'header MultiFoo has one value';

$req->url('http://example.com');
$req->content('');
is_deeply $req->query_pairs, [], 'no query parameters';
is_deeply $req->body_pairs, [], 'no body parameters';

$req->url('http://example.com?' . form_urlencode [foo => ['☃', '❤'], '❤' => 'a b c', baz => 0, bar => '☃']);
is_deeply $req->query_pairs, ['foo', '☃', 'foo', '❤', '❤', 'a b c', 'baz', '0', 'bar', '☃'], 'URL has query parameters';

$req->content(form_urlencode [foo => ['☃', '❤'], '❤' => 'a b c', baz => 0, bar => '☃']);
is_deeply $req->body_pairs, ['foo', '☃', 'foo', '❤', '❤', 'a b c', 'baz', '0', 'bar', '☃'], 'Request has body parameters';

done_testing;
