use utf8;
use Test::More tests => 17;
use Test::Exception;

use_ok('WebService::Booklog');

my ($obj, $dat);
lives_ok { $obj = WebService::Booklog->new; } 'new';

lives_ok { $dat = $obj->get_minishelf('yak1ex'); } 'get_minishelf';
is($dat->{tana}{account}, 'yak1ex', 'tana->account');
is_deeply($dat->{category}, {}, 'no category');
is(@{$dat->{books}}, 5, 'books');
my %id = map { $_->{id} => 1 } @{$dat->{books}};

lives_ok { $dat = $obj->get_minishelf('yak1ex', rank => 5); } 'get_minishelf with rank';
is($dat->{tana}{account}, 'yak1ex', 'tana->account');
is_deeply($dat->{category}, {}, 'no category');
cmp_ok(@{$dat->{books}}, '>', 0, 'books');
isnt((grep { $id{$_} } map { $_->{id} } @{$dat->{books}}), 5, 'difference check');

lives_ok { $dat = $obj->get_minishelf('yak1ex', category => 2275669); } 'get_minishelf with category';
is($dat->{tana}{account}, 'yak1ex', 'tana->account');
is($dat->{category}{name}, '技術書', 'category name');
is($dat->{category}{id}, 2275669, 'category ID');
cmp_ok(@{$dat->{books}}, '>', 0, 'books');
isnt((grep { $id{$_} } map { $_->{id} } @{$dat->{books}}), 5, 'difference check');
