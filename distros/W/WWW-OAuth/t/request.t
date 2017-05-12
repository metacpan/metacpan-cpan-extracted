use strict;
use warnings;
use utf8;

{package WWW::OAuth::Request::Test;
	use Class::Tiny::Chained 'method', 'url', 'content';
	use Role::Tiny::With;
	with 'WWW::OAuth::Request';
	
	sub content_is_form { 1 }
	sub header { }
	sub request_with { }
}

use Test::More;
use WWW::OAuth::Util 'form_urlencode';

my $req = WWW::OAuth::Request::Test->new(url => 'http::example.com');
is_deeply $req->query_pairs, [], 'no query parameters';
is_deeply $req->body_pairs, [], 'no body parameters';

$req->url('http://example.com?' . form_urlencode [foo => ['☃', '❤'], '❤' => 'a b c', baz => 0, bar => '☃']);
is_deeply $req->query_pairs, ['foo', '☃', 'foo', '❤', '❤', 'a b c', 'baz', '0', 'bar', '☃'], 'URL has query parameters';

$req->content(form_urlencode [foo => ['☃', '❤'], '❤' => 'a b c', baz => 0, bar => '☃']);
is_deeply $req->body_pairs, ['foo', '☃', 'foo', '❤', '❤', 'a b c', 'baz', '0', 'bar', '☃'], 'Request has body parameters';

done_testing;
