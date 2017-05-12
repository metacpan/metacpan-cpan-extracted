use strict;
use warnings;

use Test::More;
use File::Spec;
use File::Basename qw( dirname );
use Cwd 'abs_path';

use_ok('WWW::Tumblr');
use_ok('WWW::Tumblr::Test');

my $blog = WWW::Tumblr::Test::blog();

my $post = $blog->post(
    type => 'photo',
    data => [ glob File::Spec->catfile( dirname( abs_path( $0 ) ), 'data', '*.jpg' ) ],
);

ok $post,       'data posting';

done_testing();


