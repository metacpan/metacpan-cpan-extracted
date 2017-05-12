use v5.14;
use warnings;
use Test::More;
use t::Builder;

subtest 'urls' => sub {
    my $tweet = {
        'entities' => {
            'user_mentions' => [],
            'hashtags'      => [],
            'urls'          => [
                {   'display_url'  => 'google.com',
                    'expanded_url' => 'http://www.google.co.jp/',
                    'url'          => 'http://t.co/tYSEO8de',
                    'indices'      => [ 5, 25 ]
                },
                {   'display_url'  => 'yahoo.com',
                    'expanded_url' => 'http://www.yahoo.com/',
                    'url'          => 'http://t.co/rtd3JeP5',
                    'indices'      => [ 26, 46 ]
                }
            ]
        },
    };
    my $entry = ontweet($tweet);
    my @urls  = $entry->urls;
    is_deeply \@urls,
        [ 'http://www.google.co.jp/', 'http://www.yahoo.com/', ];
};

done_testing;
