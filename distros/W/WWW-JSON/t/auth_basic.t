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

my $json    = JSON::XS->new;
my $fake_ua = LWP::UserAgent->new;
$fake_ua->map(
    'http://localhost/get/request',
    sub {
        my $req = shift;
        my $auth = 'antipasta:hunter2';
        is scalar($req->authorization_basic),$auth, 'Got correct auth string';
        is $req->header('Authorization'),'Basic ' . encode_base64($auth,''),'Got correct encoded auth header';

        return HTTP::Response->new( 200, 'OK', undef,
            $json->encode( { success => 'this is working' } ) );
    }
);

ok my $wj = WWW::JSON->new(
    ua       => $fake_ua,
    base_url => 'http://localhost',
    authentication => { Basic => { username => 'antipasta', password => 'hunter2'}},
);
ok my $get = $wj->post('/get/request', { a => 'b'});
ok $get->success, 'Got Success';
done_testing;
