use strict;
use warnings;
use Test::More;
use Test::Mock::LWP::Dispatch;
use HTTP::Response;
use WWW::JSON;
use JSON::XS;
use URI;
use URI::QueryParam;

my $json    = JSON::XS->new;
my $fake_ua = LWP::UserAgent->new;

$fake_ua->map(
    'http://localhost/get/request',
    sub {
        my $req = shift;
        is $req->method => 'GET', 'Method is GET';
        my $uri = $req->uri;

        return HTTP::Response->new( 200, 'OK', undef,
            $json->encode( { success => 'this is working' } ) );
    }
);

$fake_ua->map(
    'http://localhost/get/request_query_param?some_query_param=yes',
    sub {
        my $req = shift;
        my $uri = $req->uri;
        is $req->method => 'GET', 'Method is GET';
        is $uri->query_param('some_query_param'), 'yes', 'Query param matches';

        return HTTP::Response->new( 200, 'OK', undef,
            $json->encode( { success => 'this is also working' } ) );
    }
);

ok my $wj = WWW::JSON->new( ua => $fake_ua, base_url => 'http://localhost' );
ok my $get = $wj->get('/get/request');
ok $get->success, 'Got Success';
is $get->code => 200, 'Got 200 OK';
ok $get->res->{success} eq 'this is working';

ok my $get_404 = $wj->get('/404');
isnt $get_404->success,   'Got no success';
is $get_404->code    => 404, 'Got code 404';

ok my $get_query_param =
  $wj->get( '/get/request_query_param', { some_query_param => 'yes' } );
ok $get_query_param->success, 'Got Success';
is $get_query_param->code => 200, 'Got 200';
ok $get_query_param->res->{success} eq 'this is also working', 'Got get response';


done_testing;
