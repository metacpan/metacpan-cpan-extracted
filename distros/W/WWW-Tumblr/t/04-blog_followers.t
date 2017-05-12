use strict;
use warnings;

use Test::More;

use_ok('WWW::Tumblr');
use_ok('WWW::Tumblr::Test');

my $blog = WWW::Tumblr::Test::blog();

my $followers = $blog->followers;

ok $followers,                              'followers is set';

ok ref $followers,                          'followers is s reference';
is ref $followers, 'HASH',                  'a HASH reference';
ok defined $followers->{total_users},       'total users is there';
ok defined $followers->{users},             'users is there';
ok ref $followers->{users},                 'users is a reference';
is ref $followers->{users}, 'ARRAY',        'users is an array reference';

done_testing();


