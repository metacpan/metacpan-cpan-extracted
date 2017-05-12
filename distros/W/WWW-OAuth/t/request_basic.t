use strict;
use warnings;
use utf8;
use Test::More;
use WWW::OAuth::Util 'form_urlencode';

use WWW::OAuth::Request::Basic;

my $req = WWW::OAuth::Request::Basic->new;

is_deeply $req->headers, {}, 'no headers';
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

$req->header('Content-Type' => '');
$req->content('');
$req->set_form([foo => 'a b c']);
is $req->content, 'foo=a+b+c', 'Set form content';
ok $req->content_is_form, 'content is a form';

done_testing;
