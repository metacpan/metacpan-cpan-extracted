#!perl -T

use 5.006;
use strict;
use warnings FATAL => 'all';

use Test::More tests => 2;

use WWW::Foursquare::Response;
use LWP::UserAgent;

diag("Testing response");

# response is OK
my $ua = LWP::UserAgent->new();
mock_response($ua, 200, 'OK', '{"response":"OK"}');
my $res = $ua->get('http://foursquare.com');
my $response = WWW::Foursquare::Response->new();

my $get_result = $response->process($res);
ok($get_result eq 'OK', 'Process right response');

# response is FAIL
mock_response($ua, 400, 'Bad Request', '{"meta":{"errorType":"param_error"},"error":"invalid_grant"}');
$res = $ua->get('http://foursquare.com');
eval { $get_result = $response->process($res); };
ok($@ =~ /param_error/, 'Process wrong response');

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
