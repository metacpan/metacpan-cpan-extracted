use v5.14;
use warnings;
use Test::More;
use t::Builder;

subtest 'posts' => sub {
    my $entity = onevent(
        {   target_object => {
                text   => 'hehehe',
                user   => { screen_name => 'foo', },
                id_str => '1',
            }
        }
    );

    my @posts = $entity->posts;
    is_deeply \@posts,
        [
        {   url         => 'https://twitter.com/#!/foo/status/1',
            tags        => 'favorite,via:tweet2delicious',
            description => 'hehehe',
            replace     => 1,
        }
        ];

};

done_testing;

