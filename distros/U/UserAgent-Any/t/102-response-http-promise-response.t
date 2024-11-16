use strict;
use warnings;
use utf8;

use Encode 'encode';
use Test2::V0 -target => 'UserAgent::Any::Response';

BEGIN {
  eval 'use HTTP::Promise::Response';  ## no critic (ProhibitStringyEval, RequireCheckingReturnValueOfEval)
  skip_all('HTTP::Promise::Response is not installed') if $@;
}

my @raw_headers = ('Content-Type' => 'text/plain; charset=utf-8', 'Foo' => 'Bar', 'Baz' => 'bin', 'Foo' => 'Bar2');
my $utf8_content = 'Héllö!';
my $raw_content = encode('UTF-8', $utf8_content);
my $raw_response = HTTP::Promise::Response->new(200, 'success', \@raw_headers, $raw_content);

my $r = CLASS()->new($raw_response);

isa_ok($r, 'UserAgent::Any::Response::Impl::HttpPromiseResponse');
DOES_ok($r, 'UserAgent::Any::Response');

is($r->res, exact_ref($raw_response), 'res');
is($r->status_code, 200, 'status_code');
is($r->status_text, 'success', 'status_text');
is($r->success, T(), 'success');
is($r->raw_content, $raw_content, 'raw_content');
is($r->content, $utf8_content, 'content');
is($r->header('Baz'), 'bin', 'header1');
is($r->header('Foo'), 'Bar, Bar2', 'header2scalar');
is([$r->header('Foo')], ['Bar', 'Bar2'], 'header2list');

done_testing;
