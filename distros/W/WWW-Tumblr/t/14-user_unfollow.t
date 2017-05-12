use strict;
use warnings;

use Test::More;

use_ok('WWW::Tumblr');
use_ok('WWW::Tumblr::Test');

my $user = WWW::Tumblr::Test::user();

my $unfollow = $user->unfollow( url => 'whenyouliveinamsterdam.tumblr.com' );

ok $unfollow,                       'user unfollow is fine';

done_testing();


