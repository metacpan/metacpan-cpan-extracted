use strict;
use warnings;
use Test::More;
use Test::Mock::LWP::Dispatch;
use HTTP::Response;
use WWW::JSON;
use JSON::XS;

my $json    = JSON::XS->new;
my $fake_ua = LWP::UserAgent->new;
$fake_ua->map(
    'http://some_alt_url/something',
    sub {
        my $req = shift;
        my $uri = $req->uri;

        return HTTP::Response->new( 200, 'OK', undef,
            $json->encode( { msg => 'non base response' } ) );
    }
);

$fake_ua->map(
    'http://localhost/failed_json_parse',
    sub {
        my $req = shift;
        return HTTP::Response->new( 200, 'OK', undef, 'THIS IS NOT JSON' );
    }
);

$fake_ua->map(
    'http://localhost/test/transform',
    sub {
        my $req = shift;
        my $uri = $req->uri;
        is $req->method => 'POST', 'Method is POST';
        return HTTP::Response->new( 200, 'OK', undef,
            $json->encode( { data => { result => [ 'item 1', 'item 2' ] } } ) );
    }
);
ok my $wj = WWW::JSON->new( ua => $fake_ua, base_url => 'http://localhost' );


ok my $fail = $wj->post('/failed_json_parse');
ok $fail->http_response->is_success, 'HTTP request success';
is $fail->code    => 200, 'HTTP code 200';
isnt $fail->success,   'JSON parse failed';
ok $fail->error,   'Got json parse error';
ok !defined( $fail->res ), 'No decoded json response';
is $fail->content => 'THIS IS NOT JSON';

ok my $req_non_base =
  $wj->post( 'http://some_alt_url/something', { param => 456 } );
ok $req_non_base->success, 'json success';
is $req_non_base->res->{msg} => 'non base response',
  'got back response from non base url';

ok my $transform =
  $wj->default_response_transform( sub { shift->{data}{result} } );
ok my $req_transform = $wj->post('/test/transform');
is_deeply $req_transform->res, [ 'item 1', 'item 2' ],
  'response_transform works';

ok $wj->clear_default_response_transform;
ok my $clear_transform = $wj->post('/test/transform');
is_deeply $clear_transform->res->{data}->{result}, [ 'item 1', 'item 2' ],
  'clear_response_transform works';
$wj->clear_default_response_transform;


done_testing;
