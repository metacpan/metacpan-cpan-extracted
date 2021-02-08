package t::Util;
use strict;
use warnings;
use utf8;
use feature qw/state/;

use JSON;
use Exporter qw/ import /;

use WebService::Slack::WebApi;

our @EXPORT_OK = qw/ mocked_slack any_mocked_slack mocked_slack_without_token /;

sub mocked_slack {
    my ($content, $is_success, $no_token) = @_;

    # mock ua for HTTP::AnyUA
    # don't use with real HTTP::Tiny
    my $ua = bless +{
        content => encode_json $content,
        success => $is_success,
    }, 'HTTP::Tiny';
    sub HTTP::Tiny::request { shift }

    if(defined $no_token && $no_token) {
        return WebService::Slack::WebApi->new(ua => $ua);
    }
    return WebService::Slack::WebApi->new(token => 'a', ua => $ua);
}

sub any_mocked_slack { mocked_slack +{hoge => 'fuga'}, 1 }
sub mocked_slack_without_token { mocked_slack +{hoge => 'fuga'}, 1, 1 }

1;

