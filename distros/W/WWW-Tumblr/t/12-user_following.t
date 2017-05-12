use strict;
use warnings;

use Test::More;

use_ok('WWW::Tumblr');
use_ok('WWW::Tumblr::Test');

my $user = WWW::Tumblr::Test::user();

my $following = $user->following();

ok $following,                       'user following is fine';
ok ref $following eq 'HASH',         'response is a hash reference';

done_testing();


