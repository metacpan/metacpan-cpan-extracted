use strict;
use warnings;
use utf8;
use 5.10.0;

use Data::Dumper;
use WebService::Slack::WebApi;

my $slack = WebService::Slack::WebApi->new(token => 'access token');
my $posted_message = $slack->chat->post_message(
    channel     => '#sandbox',
    # text        => 'test',  # not required if attachments exists
    as_user     => 1,
    attachments => [
        {
            fallback    => 'Required plain-text summary of the attachment.',
            color       => '#36a64f',
            pretext     => 'Optional text that appears above the attachment block',
            author_name => 'Bobby Tables',
            author_link => 'http://flickr.com/bobby/',
            author_icon => 'http://flickr.com/icons/bobby.jpg',
            title       => 'Slack API Documentation',
            title_link  => 'https://api.slack.com/',
            text        => 'Optional text that appears within the attachment',
            fields => [
                {
                    title => 'Priority',
                    value => 'Hight',
                    short => 0,
                },
            ],
        },
    ],
);

say Dumper $posted_message;

