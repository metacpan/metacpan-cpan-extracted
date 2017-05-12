use strict;
use warnings;

use Test::More;

use_ok('WWW::Tumblr');
use_ok('WWW::Tumblr::Test');

my $user = WWW::Tumblr::Test::user();

my $dashboard = $user->dashboard();

ok $dashboard,                       'user dashboard is fine';
ok ref $dashboard eq 'HASH',         'response is a hash reference';

done_testing();


