use v5.14;
use warnings;
use Test::More;
use t::Builder;

subtest 'tags' => sub {
    my $entity = ontweet(
        {   'favorited' => 0,
            'entities'  => {
                'hashtags' => [{ 'text' => 'test1' }, { 'text' => 'test2'} ],
                'urls'     => [
                    { 'expanded_url' => 'http://www.google.com', },
                    { 'expanded_url' => 'http://www.yahoo.com/', }
                ]
            },
            'text' =>
                '[blog][test] test http://t.co/tYSEO8de http://t.co/rtd3JeP5',
            'user'                    => { 'screen_name' => 'aloelight', },
            'in_reply_to_screen_name' => undef
        }
    );
    my @tags = $entity->tags;
    is_deeply \@tags, [qw/test1 test2 blog test/] or diag explain \@tags;
};

subtest 'uniq' => sub {
    my $entity = ontweet(
        {   'favorited' => 0,
            'entities'  => {
                'hashtags' => [{ 'text' => 'test' }, { 'text' => 'test'} ],
                'urls'     => [
                    { 'expanded_url' => 'http://www.google.com', },
                    { 'expanded_url' => 'http://www.yahoo.com/', }
                ]
            },
            'text' =>
                '[blog][test] test http://t.co/tYSEO8de http://t.co/rtd3JeP5',
            'user'                    => { 'screen_name' => 'aloelight', },
            'in_reply_to_screen_name' => undef
        }
    );
    my @tags = $entity->tags;
    is_deeply \@tags, [qw/test blog/] or diag explain \@tags;
};

done_testing;
