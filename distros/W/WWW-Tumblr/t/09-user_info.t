use strict;
use warnings;

use Test::More;

use_ok('WWW::Tumblr');
use_ok('WWW::Tumblr::Test');

my $user = WWW::Tumblr::Test::user();

my $info = $user->info();

ok $info,                       'user info is fine';
ok ref $info eq 'HASH',         'response is a hash reference';

done_testing();


