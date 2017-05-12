use v5.14;
use warnings;
use Test::More;
use t::Builder;

subtest 'posts' => sub {
    my $entity = ontweet(
        {   'favorited' => 0,
            'entities'  => {
                'hashtags' =>
                    [ { 'text' => 'test1' }, { 'text' => 'test2' } ],
                'urls' => [
                    { 'expanded_url' => 'http://www.google.co.jp', },
                    { 'expanded_url' => 'http://www.yahoo.com/', }
                ]
            },
            'text' =>
                '[blog][test] test http://t.co/tYSEO8de http://t.co/rtd3JeP5',
            'user'                    => { 'screen_name' => 'aloelight', },
            'in_reply_to_screen_name' => undef
        }
    );
    my @posts = $entity->posts;

    is_deeply \@posts,
        [
        {   url  => 'http://www.google.co.jp',
            tags => 'test1,test2,blog,test,via:tweet2delicious',
            description =>
                '[blog][test] test http://t.co/tYSEO8de http://t.co/rtd3JeP5',
            replace => 1,
        },
        {   url  => 'http://www.yahoo.com/',
            tags => 'test1,test2,blog,test,via:tweet2delicious',
            description =>
                '[blog][test] test http://t.co/tYSEO8de http://t.co/rtd3JeP5',
            replace => 1,
        },
        ];
};

subtest 'no links' => sub {
    my $entity = ontweet(
        {   'favorited' => 0,
            'entities'  => {
                'hashtags' =>
                    [ { 'text' => 'test1' }, { 'text' => 'test2' } ],
                'urls' => []
            },
            'text' =>
                '[blog][test] test http://t.co/tYSEO8de http://t.co/rtd3JeP5',
            'user'                    => { 'screen_name' => 'aloelight', },
            'in_reply_to_screen_name' => undef
        }
    );
    my @posts = $entity->posts;
    is_deeply \@posts, [];
};

subtest 'favorited' => sub {
    my $entity = ontweet(
        {   'favorited' => 1,
            'entities'  => {
                'hashtags' =>
                    [ { 'text' => 'test1' }, { 'text' => 'test2' } ],
                'urls' => [
                    { 'expanded_url' => 'http://www.google.co.jp', },
                    { 'expanded_url' => 'http://www.yahoo.com/', }
                ]
            },
            'text' =>
                '[blog][test] test http://t.co/tYSEO8de http://t.co/rtd3JeP5',
            'user'                    => { 'screen_name' => 'aloelight', },
            'in_reply_to_screen_name' => undef
        }
    );
    my @posts = $entity->posts;

    is_deeply \@posts,
        [
        {   url  => 'http://www.google.co.jp',
            tags => 'test1,test2,blog,test,favorite,via:tweet2delicious',
            description =>
                '[blog][test] test http://t.co/tYSEO8de http://t.co/rtd3JeP5',
            replace => 1,
        },
        {   url  => 'http://www.yahoo.com/',
            tags => 'test1,test2,blog,test,favorite,via:tweet2delicious',
            description =>
                '[blog][test] test http://t.co/tYSEO8de http://t.co/rtd3JeP5',
            replace => 1,
        },
        ];
};
done_testing;
