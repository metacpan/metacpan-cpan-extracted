use strict;
use warnings;

use Test::More;

use_ok('WWW::Tumblr');
use_ok('WWW::Tumblr::Test');

my $blog = WWW::Tumblr::Test::blog();

my $posts = $blog->posts;

ok $posts,                              'posts is set';

ok ref $posts,                          'posts is s reference';
is ref $posts, 'HASH',                  'a HASH reference';

ok ! $blog->posts( id => 1234567890 ),  'this should be an error';
ok $blog->posts( type => 'video' ),     'this should be fine';
ok $blog->posts_queue,                  'posts/queue';
ok $blog->posts_draft,                  'posts/draft';
ok $blog->posts_submission,             'posts/submission';

done_testing();


