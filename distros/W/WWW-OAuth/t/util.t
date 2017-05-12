use strict;
use warnings;
use utf8;
use Scalar::Util 'blessed', 'refaddr';
use Test::More;
use WWW::OAuth::Request::Basic;

use WWW::OAuth::Util 'form_urldecode', 'form_urlencode', 'oauth_request';

is form_urlencode([]), '', 'empty form';
is form_urlencode({}), '', 'empty form';
is form_urlencode([undef, 'foo']), '=foo', 'empty key';
is form_urlencode([foo => undef]), 'foo=', 'empty value';
is_deeply form_urldecode(''), [], 'empty form';
is_deeply form_urldecode('='), ['', ''], 'empty key and value';
is_deeply form_urldecode('=foo'), ['', 'foo'], 'empty key';
is_deeply form_urldecode('foo'), ['foo', ''], 'empty value';
is_deeply form_urldecode('&'), ['', '', '', ''], 'empty keys and values';
is_deeply form_urldecode('foo&=bar&'), ['foo', '', '', 'bar', '', ''], 'weird form';

my ($decoded, $encoded);
$decoded = [foo => ['☃', '❤'], '❤' => 'a b c', baz => 0];
$encoded = form_urlencode $decoded;
is $encoded, 'foo=%E2%98%83&foo=%E2%9D%A4&%E2%9D%A4=a+b+c&baz=0', 'form urlencoded correctly';
$decoded = form_urldecode $encoded;
is_deeply $decoded, ['foo', '☃', 'foo', '❤', '❤', 'a b c', 'baz', '0'], 'form urldecoded correctly';

$decoded = {foo => [2, 1], '❤' => 'a ☃ c', baz => 0};
$encoded = form_urlencode $decoded;
is $encoded, 'baz=0&foo=2&foo=1&%E2%9D%A4=a+%E2%98%83+c', 'form urlencoded correctly';
$decoded = form_urldecode $encoded;
is_deeply $decoded, ['baz', '0', 'foo', '2', 'foo', '1', '❤', 'a ☃ c'], 'form urldecoded correctly';

{package WWW::OAuth::Fake::HTTP::Request;
	sub new { bless {}, shift }
	sub isa { $_[1] eq 'HTTP::Request' ? 1 : 0 }
}
{package WWW::OAuth::Fake::Mojo::Request;
	sub new { bless {}, shift }
	sub isa { $_[1] eq 'Mojo::Message::Request' ? 1 : 0 }
}

my $existing = WWW::OAuth::Request::Basic->new;
my $existing_req = oauth_request($existing);
is refaddr($existing_req), refaddr($existing), 'same container returned';

my $basic_href = {method => 'FOO', url => 'http://example.com', content => 'bar'};
my $basic_req = oauth_request($basic_href);
is blessed($basic_req), 'WWW::OAuth::Request::Basic', 'created Basic request object';
is $basic_req->method, 'FOO', 'method is FOO';
is $basic_req->url, 'http://example.com', 'url is http://example.com';
is $basic_req->content, 'bar', 'content is bar';

$basic_req = oauth_request(Basic => $basic_href);
is blessed($basic_req), 'WWW::OAuth::Request::Basic', 'created Basic request object';
is $basic_req->method, 'FOO', 'method is FOO';
is $basic_req->url, 'http://example.com', 'url is http://example.com';
is $basic_req->content, 'bar', 'content is bar';

my $http_request = WWW::OAuth::Fake::HTTP::Request->new;
my $http_request_req = oauth_request($http_request);
is blessed($http_request_req), 'WWW::OAuth::Request::HTTP_Request', 'created HTTP_Request request object';
is refaddr($http_request_req->request), refaddr($http_request), 'same request object';

$http_request_req = oauth_request(HTTP_Request => $http_request);
is blessed($http_request_req), 'WWW::OAuth::Request::HTTP_Request', 'created HTTP_Request request object';
is refaddr($http_request_req->request), refaddr($http_request), 'same request object';

my $mojo_request = WWW::OAuth::Fake::Mojo::Request->new;
my $mojo_request_req = oauth_request($mojo_request);
is blessed($mojo_request_req), 'WWW::OAuth::Request::Mojo', 'created Mojo request object';
is refaddr($mojo_request_req->request), refaddr($mojo_request), 'same request object';

$mojo_request_req = oauth_request(Mojo => $mojo_request);
is blessed($mojo_request_req), 'WWW::OAuth::Request::Mojo', 'created Mojo request object';
is refaddr($mojo_request_req->request), refaddr($mojo_request), 'same request object';

done_testing;
