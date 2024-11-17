use 5.036;
use utf8;

use Encode 'encode';
use HTTP::Response;
use Test2::V0 -target => 'UserAgent::Any::JSON::Response';

my @raw_headers = ('Content-Type' => 'application/json');
my $raw_content = '{"Foo":"Bar"}';
my $raw_response = HTTP::Response->new(200, 'success', \@raw_headers, $raw_content);

my $r = CLASS()->new($raw_response);

isa_ok($r, 'UserAgent::Any::JSON::Response');

is($r->res, exact_ref($raw_response), 'res');
is($r->status_code, 200, 'status_code');
is($r->status_text, 'success', 'status_text');
is($r->success, T(), 'success');
is($r->raw_content, $raw_content, 'raw_content');
is($r->content, $raw_content, 'content');
is($r->data, {Foo => 'Bar'}, 'data');

done_testing;
