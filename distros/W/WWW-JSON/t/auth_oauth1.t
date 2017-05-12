use strict;
use warnings;
use Test::More;
use Test::Mock::LWP::Dispatch;
use HTTP::Response;
use WWW::JSON;
use JSON::XS;
use URI;
use URI::QueryParam;
use MIME::Base64;
use Net::OAuth;
my $oauth_creds = {
    consumer_key    => 'consumer',
    consumer_secret => 'consumersecret',
    token           => 'token',
    token_secret    => 'tokensecret'
};

my $json    = JSON::XS->new;
my $fake_ua = LWP::UserAgent->new;
$fake_ua->map(
    'http://localhost/get/request?abc=123',
    sub {
        my $req = shift;
        my $oauth_request =
          Net::OAuth->request("protected resource")->from_authorization_header(
            $req->header('Authorization'),
            request_url     => 'http://localhost/get/request',
            request_method  => 'GET',
            token_secret    => $oauth_creds->{token_secret},
            consumer_secret => $oauth_creds->{consumer_secret},
            extra_params    => { abc => '123', },
          );
        ok $oauth_request->verify, 'get oauth credentials correct';

        return HTTP::Response->new( 200, 'OK', undef,
            $json->encode( { success => 'get request working' } ) );
    }
);
$fake_ua->map(
    'http://localhost/post/request',
    sub {
        my $req = shift;
        my $oauth_request =
          Net::OAuth->request("protected resource")->from_authorization_header(
            $req->header('Authorization'),
            request_url     => 'http://localhost/post/request',
            request_method  => 'POST',
            token_secret    => $oauth_creds->{token_secret},
            consumer_secret => $oauth_creds->{consumer_secret},
            extra_params    => { a => 'b', x => 'y' },
          );
        ok $oauth_request->verify, 'post oauth credentials correct';

        return HTTP::Response->new( 200, 'OK', undef,
            $json->encode( { success => 'post request working' } ) );
    }
);

ok my $wj = WWW::JSON->new(
    ua             => $fake_ua,
    base_url       => 'http://localhost/',
    authentication => {
        OAuth1 => $oauth_creds,
    },
  ),
  'initialized www json with oauth creds';
ok my $get = $wj->get( '/get/request', { 'abc' => 123 } ),
  'made oauth get request';
is $get->res->{success}, 'get request working', 'get request response correct';
ok my $post = $wj->post( '/post/request', { a => 'b', x => 'y' } ),
  'made oauth post request';
is $post->res->{success}, 'post request working',
  'post request response correct';
done_testing;
