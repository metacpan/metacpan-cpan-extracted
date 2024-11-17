use 5.036;
use utf8;

use Encode 'encode';
use Test2::V0 -target => 'UserAgent::Any::JSON';

sub gen_get { &UserAgent::Any::JSON::_generate_get_request }
sub gen_post { &UserAgent::Any::JSON::_generate_post_request }

my @HDRS = (Accept => 'application/json', 'Content-Type' => 'application/json');

is([gen_get(undef, "http://example.com")], ['http://example.com', @HDRS], 'get no args');
like(dies { gen_get(undef, "http://example.com", 'Foo') }, qr/Invalid number of arguments/, 'get odd number of args');
is([gen_get(undef, "http://example.com", Foo => 'Bar')], ['http://example.com', @HDRS, Foo => 'Bar'], 'get no args');

is([gen_post(undef, "http://example.com")], ['http://example.com', @HDRS], 'post no args body');
is([gen_post(undef, "http://example.com", 'Foo')], ['http://example.com', @HDRS, '"Foo"'], 'post only body');
is([gen_post(undef, "http://example.com", Foo => 'Bar')], ['http://example.com', @HDRS, Foo => 'Bar'], 'post no body');
is([gen_post(undef, "http://example.com", Foo => 'Bar', 'Baz')], ['http://example.com', @HDRS, Foo => 'Bar', '"Baz"'], 'post args and body');

is([gen_post(undef, "http://example.com", { Foo => 'Bar' })], ['http://example.com', @HDRS, '{"Foo":"Bar"}'], 'post with JSON');

done_testing;
