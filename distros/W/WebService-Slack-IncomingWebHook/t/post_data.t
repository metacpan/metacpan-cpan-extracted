use strict;
use warnings;

use Test::More;
use WebService::Slack::IncomingWebHook;

my $host = 'http://example.com/';
subtest 'no default parameter' => sub {
    is_deeply(
        WebService::Slack::IncomingWebHook->new(webhook_url => $host)->_make_post_data(
            text       => 'hoge',
        ) => +{
            text       => 'hoge',
            icon_emoji => undef,
            icon_url   => undef,
            username   => undef,
            channel    => undef,
        }
    );
    is_deeply(
        WebService::Slack::IncomingWebHook->new(webhook_url => $host)->_make_post_data(
            text       => 'hoge',
            icon_emoji => ':sushi:',
            username   => 'user',
        ) => +{
            text       => 'hoge',
            icon_emoji => ':sushi:',
            icon_url   => undef,
            username   => 'user',
            channel    => undef,
        }
    );
    is_deeply(
        WebService::Slack::IncomingWebHook->new(webhook_url => $host)->_make_post_data(
            text       => 'hoge',
            icon_emoji => ':sushi:',
            username   => 'user',
            icon_url   => 'http://example.com/hoge.jpg',
            username   => 'user',
            channel    => '@user',
        ) => +{
            text       => 'hoge',
            icon_emoji => ':sushi:',
            icon_url   => 'http://example.com/hoge.jpg',
            username   => 'user',
            channel    => '@user',
        }
    );
};

subtest 'with default parameter' => sub {
    is_deeply(
        WebService::Slack::IncomingWebHook->new(
            webhook_url => $host,
            icon_emoji => ':beer:',
            channel    => '#channel',
        )->_make_post_data(
            text       => 'hoge',
        ) => +{
            text       => 'hoge',
            icon_emoji => ':beer:',
            icon_url   => undef,
            username   => undef,
            channel    => '#channel',
        }
    );
    is_deeply(
        WebService::Slack::IncomingWebHook->new(
            webhook_url => $host,
            icon_emoji => ':beer:',
            channel    => '#channel',
        )->_make_post_data(
            text       => 'hoge',
            icon_emoji => ':sushi:',
            username   => 'user',
        ) => +{
            text       => 'hoge',
            icon_emoji => ':sushi:',
            icon_url   => undef,
            username   => 'user',
            channel    => '#channel',
        }
    );
    is_deeply(
        WebService::Slack::IncomingWebHook->new(
            webhook_url => $host,
            icon_emoji => ':beer:',
            username   => 'user_2',
            icon_url   => 'http://example.jp/hoge.jpg',
            channel    => '#channel',
        )->_make_post_data(
            text       => 'hoge',
            icon_emoji => ':sushi:',
            username   => 'user',
            icon_url   => 'http://example.com/hoge.jpg',
            channel    => '@user',
        ) => +{
            text       => 'hoge',
            icon_emoji => ':sushi:',
            icon_url   => 'http://example.com/hoge.jpg',
            username   => 'user',
            channel    => '@user',
        }
    );
};

done_testing;
