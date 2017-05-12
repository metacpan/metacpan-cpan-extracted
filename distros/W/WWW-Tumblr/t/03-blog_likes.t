use strict;
use warnings;

use Test::More;

use_ok('WWW::Tumblr');
use_ok('WWW::Tumblr::Test');

my $blog = WWW::Tumblr::Test::blog();
my $info = $blog->info;

if ( $info && $info->{share_likes} ) {
    my $likes = $blog->likes();
    ok $likes,                          'ok response';
    ok ref $likes,                      'response a reference';
    is ref $likes, 'HASH',              'reference is a HASH';
    
    ok defined $likes->{liked_posts},   'liked_posts present';
    ok defined $likes->{liked_count},   'liked_count present';
}

done_testing();


