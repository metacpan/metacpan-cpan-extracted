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
    'http://localhost/get/request/123/test',
    sub {
        my $req = shift;
        is $req->method => 'GET', 'Method is GET';
        my $uri = $req->uri;

        return HTTP::Response->new( 200, 'OK', undef,
            $json->encode( { success => 'this is working' } ) );
    }
);

$fake_ua->map(
    'http://localhost/get/123/request_query_param?some_query_param=yes',
    sub {
        my $req = shift;
        my $uri = $req->uri;
        is $req->method => 'GET', 'Method is GET';
        is $uri->query_param('some_query_param'), 'yes', 'Query param matches';

        return HTTP::Response->new( 200, 'OK', undef,
            $json->encode( { success => 'this is also working' } ) );
    }
);

$fake_ua->map(
    'http://localhost/post/123/a/456',
    sub {
        my $req = shift;
        my $uri = $req->uri;
        is $req->method => 'POST', 'Method is POST';

        return HTTP::Response->new( 200, 'OK', undef,
            $json->encode( { success => 'this is also working' } ) );
    }
);

ok my $wj = WWW::JSON->new( ua => $fake_ua, base_url => 'http://localhost' );
ok my $get = $wj->get( '/get/request/[% template_var %]/test',
    { -template_var => 123 } );
ok $get->success, 'Got Success';
is $get->code => 200, 'Got 200 OK';
ok $get->res->{success} eq 'this is working';

ok my $get_query_param = $wj->get(
    '/get/[% template_var %]/request_query_param',
    { some_query_param => 'yes', -template_var => 123 }
);
ok $get_query_param->success, 'Got Success';
is $get_query_param->code => 200, 'Got 200';
ok $get_query_param->res->{success} eq 'this is also working',
  'Got get response';

ok my $post = $wj->post(
    '/post/[% template_var1 %]/a/[% template_var2 %]',
    {
        some_query_param => 'yes',
        -template_var1   => 123,
        -template_var2   => 456
    }
);
ok $post->success, 'Got Success';
is $post->code => 200, 'Got 200';
ok $post->res->{success} eq 'this is also working', 'Got get response';

done_testing;
