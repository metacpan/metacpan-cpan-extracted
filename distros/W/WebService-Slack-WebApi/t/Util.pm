package t::Util;
use strict;
use warnings;
use utf8;
use feature qw/state/;

use Test::Mock::Furl;

use JSON::XS;
use Furl::Response;
use Exporter qw/ import /;

use WebService::Slack::WebApi;

our @EXPORT_OK = qw/ slack set_mock_response set_any_mock_response /;

sub slack { WebService::Slack::WebApi->new(token => 'a') }

sub set_mock_response {
    my ($content, $is_success) = @_;

    $Mock_furl->mock(request => sub { Furl::Response->new });
    $Mock_furl_res->mock(content    => sub { encode_json $content });
    $Mock_furl_res->mock(is_success => sub { $is_success // 1 });
}

sub set_any_mock_response { set_mock_response +{hoge => 'fuga'} }

1;

