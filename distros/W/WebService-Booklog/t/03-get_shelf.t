use utf8;
use Test::More tests => 24;
use Test::Exception;

use_ok('WebService::Booklog');

my ($obj, $dat);
lives_ok { $obj = WebService::Booklog->new; } 'new';

lives_ok { $dat = $obj->get_shelf('yak1ex'); } 'get_shelf';
is($dat->{user}{account}, 'yak1ex', 'user->account');
is($dat->{category_id}, 0, 'no category');
is(@{$dat->{books}}, 25, 'books');
my %id = map { $_->{id} => 1 } @{$dat->{books}};

lives_ok { $dat = $obj->get_shelf('yak1ex', rank => 5); } 'get_shelf with rank';
is($dat->{user}{account}, 'yak1ex', 'user->account');
is($dat->{category_id}, 0, 'no category');
cmp_ok(@{$dat->{books}}, '>', 0, 'books');
isnt((grep { $id{$_} } map { $_->{id} } @{$dat->{books}}), 25, 'difference check');

lives_ok { $dat = $obj->get_shelf('yak1ex', category => 2275669); } 'get_shelf with category';
is($dat->{user}{account}, 'yak1ex', 'user->account');
is($dat->{category_id}, 2275669, 'category id');
cmp_ok(@{$dat->{books}}, '>', 0, 'books');
isnt((grep { $id{$_} } map { $_->{id} } @{$dat->{books}}), 25, 'difference check');

lives_ok { $dat = $obj->get_shelf('yak1ex', 'sort' => 'release_desc'); } 'get_shelf';
is($dat->{user}{account}, 'yak1ex', 'user->account');
is($dat->{category_id}, 0, 'no category');
is($dat->{'sort'}, 'release_desc', 'sort'); 
is(@{$dat->{books}}, 25, 'books');
my @date = map { $_->{item}{release_date} } @{$dat->{books}};
is(@date, 25, 'release date');
is_deeply(\@date, [sort { $b cmp $a } @date], 'sort order');
isnt((grep { $id{$_} } map { $_->{id} } @{$dat->{books}}), 25, 'difference check');
