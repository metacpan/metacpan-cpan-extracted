use strict;
use Test::More;
use WebService::Pornhub;

unless ($ENV{WEBSERVICE_PORNHUB_LIVE_TEST}) {
    plan skip_all => '$ENV{WEBSERVICE_PORNHUB_LIVE_TEST} is not set'
}

my $pornhub = WebService::Pornhub->new;

subtest 'search' => sub {
    my $videos = $pornhub->search(
        search    => 'hard',
        'tags[]'  => 'young',
        thumbsize => 'medium'
    );
    ok $videos;
    isa_ok $videos, 'ARRAY';
    ok $videos->[0];
    ok $videos->[0]{title};
    ok $videos->[0]{url};
};

subtest 'get_video_by_id' => sub {
    my $video = $pornhub->get_video( id => '44bc40f3bc04f65b7a35' );
    ok $video;
    isa_ok $video, 'HASH';
    ok $video->{title};
    ok $video->{url};

    my $video_not_found = $pornhub->get_video();
    ok !$video_not_found;
};

subtest 'get_embed_code' => sub {
    my $embed = $pornhub->get_embed_code( id => '44bc40f3bc04f65b7a35' );
    ok $embed;
    isa_ok $embed, 'HASH';
    ok $embed->{code};
};

subtest 'get_deleted_videos' => sub {
    my $videos = $pornhub->get_deleted_videos( page => 1 );
    ok $videos;
    isa_ok $videos, 'ARRAY';
    ok $videos->[0]{deleted_on};
};

subtest 'is_video_active' => sub {
    my $active = $pornhub->is_video_active( id => '44bc40f3bc04f65b7a35' );
    ok $active;
    isa_ok $active, 'HASH';
    is $active->{video_id}, '44bc40f3bc04f65b7a35';
    ok $active->{is_active};
};

subtest 'get_categories' => sub {
    my $categories = $pornhub->get_categories;
    ok $categories;
    isa_ok $categories, 'ARRAY';
    ok $categories->[0];
    ok $categories->[0]{category};
};

subtest 'get_tags' => sub {
    my $tags = $pornhub->get_tags( list => 'z' );
    ok $tags;
    isa_ok $tags, 'ARRAY';
    ok $tags->[0];
    diag $tags->[0];
};

subtest 'get_stars' => sub {
    my $stars = $pornhub->get_stars;
    ok $stars;
    isa_ok $stars, 'ARRAY';
    ok $stars->[0]{star}{star_name};
};

subtest 'get_stars_detailed' => sub {
    plan skip_all => 'Method get_stars_detailed resonse is too large';
    my $stars = $pornhub->get_stars_detailed;
    ok $stars;
    isa_ok $stars, 'ARRAY';
    ok $stars->[0];
    isa_ok $stars->[0], 'HASH';
    ok $stars->[0]{star}{star_name};
};

done_testing;
