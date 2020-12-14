package t::Util;
use strict;
use warnings;
use utf8;
use feature qw/state/;

use JSON;
use Exporter qw/ import /;

use WebService::Slack::WebApi;

our @EXPORT_OK = qw/ mocked_slack any_mocked_slack /;

sub mocked_slack {
    my ($content, $is_success) = @_;

    # mock ua for HTTP::AnyUA
    # don't use with real HTTP::Tiny
    my $ua = bless +{
        content => encode_json $content,
        success => $is_success,
    }, 'HTTP::Tiny';
    sub HTTP::Tiny::request { shift }

    return WebService::Slack::WebApi->new(token => 'a', ua => $ua);
}

sub any_mocked_slack { mocked_slack +{hoge => 'fuga'}, 1 }

1;

