#!perl -T

use 5.006;
use strict;
use warnings FATAL => 'all';

use Test::More tests => 4;

use WWW::Foursquare;

# Create fs object
my $fs = WWW::Foursquare->new(
    client_id     => 'client_id',
    client_secret => 'client_secret',
    redirect_uri  => 'redirect_uri',
);

diag('Testing oauth');

# 01 get_auth_url
my $reg_auth_url = qr{^https://foursquare\.com/oauth2/authenticate\?client_id=.*?&redirect_uri=.*?&response_type=.*?$};
ok($fs->get_auth_url() =~ $reg_auth_url, "get auth url");

# 02 invalid grant
mock_response($fs->_ua(), 400, 'Bad Request', '{"error":"invalid_grant"}');
eval { my $token = $fs->get_access_token('test.code'); };
ok($@, 'check oauth with invalid grant');

# 03 get_access_token (need mock)
mock_response($fs->_ua(), 200, 'OK', '{"access_token":"12J1QZUPO5H3ZMIX1GS0RVNWTFMU1IP4HVC02DRFCIZP3OIV"}');
my $token = $fs->get_access_token('test.code');
ok($token eq '12J1QZUPO5H3ZMIX1GS0RVNWTFMU1IP4HVC02DRFCIZP3OIV', 'get token from fs server');

# 04 set_acesss_token
$fs->set_access_token($token);
ok($fs->{request}->{access_token} eq $token, 'set access token');

sub mock_response {
    my ($ua, $http_code, $http_status, $content) = @_;

    $ua->remove_handler('request_send');
    $ua->add_handler(request_send => sub {
        my ($request, $ua, $h) = @_;
 
        my $http_response = HTTP::Response->new($http_code, $http_status);
        $http_response->request($request);
        $http_response->content($content);

        return $http_response;
    });
}
