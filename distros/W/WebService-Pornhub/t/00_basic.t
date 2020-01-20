use strict;
use Test::More;

use_ok('WebService::Pornhub');

subtest 'new' => sub {
    new_ok('WebService::Pornhub');
};

subtest 'methods' => sub {
    my @methods = qw/
      search
      get_video
      get_embed_code
      get_deleted_videos
      is_video_active
      get_categories
      get_tags
      get_stars
      get_stars_detailed
    /;
    for my $method (@methods) {
        can_ok('WebService::Pornhub', $method);
    }
};

subtest 'ua' => sub {
    my $pornhub = WebService::Pornhub->new( timeout => 10 );
    is($pornhub->ua->agent, 'WebService::Pornhub/' . $WebService::Pornhub::VERSION);
    is($pornhub->ua->timeout, 10);
};

done_testing;
