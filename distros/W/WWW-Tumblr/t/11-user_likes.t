use strict;
use warnings;

use Test::More;

use_ok('WWW::Tumblr');
use_ok('WWW::Tumblr::Test');

my $user = WWW::Tumblr::Test::user();

my $likes = $user->likes();

ok $likes,                       'user likes is fine';
ok ref $likes eq 'HASH',         'response is a hash reference';

done_testing();


