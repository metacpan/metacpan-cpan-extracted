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
    'http://localhost/post/request',
    sub {
        my $req = shift;
        my $uri = $req->uri;
        is $req->method => 'POST', 'Method is POST';
        is $req->content => 'some_post_param=yes',
          'Successfully sent POST param';
        isnt $uri->query_param('some_post_param'), 'yes',
          'POST doesnt include param in uri';

        return HTTP::Response->new( 200, 'OK', undef,
            $json->encode( { success => 'POST is working' } ) );
    }
);

$fake_ua->map(
    'http://localhost/post/query_form_test?some_query_param=hi',
    sub {
        my $req = shift;
        my $uri = $req->uri;
        is $req->method => 'POST', 'Method is POST';
        is $req->content => 'some_post_param=yes',
          'Successfully sent POST param';
        is $uri->query_param('some_query_param'), 'hi',
          'POST includes query_param some_query_param';

        return HTTP::Response->new( 200, 'OK', undef,
            $json->encode( { success => 'POST is working' } ) );
    }
);

$fake_ua->map(
    'http://localhost/json_post_request',
    sub {
        my $req = shift;
        my $uri = $req->uri;
        is $req->method => 'POST', 'Method is POST';
        is $req->header('Content-Type'), 'application/json', 'json content type';
        ok $req->content, 'got json post body';
        my $decoded = $json->decode($req->content);
        is $decoded->{json_param}, '555', 'decoded json value received';

        return HTTP::Response->new( 200, 'OK', undef,
            $json->encode( { success => 'JSON POST is working' } ) );
    }
);
ok my $wj = WWW::JSON->new( ua => $fake_ua, base_url => 'http://localhost' );

ok my $post = $wj->post( '/post/request', { some_post_param => 'yes' } );
ok $post->success, 'post successful';
is $post->code => 200, 'post 200 OK';
ok $post->res->{success} eq 'POST is working';

ok my $query_form = $wj->post(
    '/post/query_form_test',
    { some_post_param => 'yes' },
    { query_params    => { some_query_param => 'hi' } }
);
ok $query_form->success, 'query_form_test post successful';
is $query_form->code => 200, 'post 200 OK';
ok $query_form->res->{success} eq 'POST is working';

ok $wj->post_body_format('JSON');
ok my $json_post_body = $wj->post('/json_post_request', {json_param => 555 });
is $json_post_body->res->{success}, 'JSON POST is working';

done_testing;
