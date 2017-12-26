use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new(
  'Wishlist',
  {database => ':temp:'}
);

my $model = $t->app->model;
is_deeply $model->all_users, [], 'No existing users';

my $user_id = $model->add_user({
  name => 'Zoidberg',
  username => 'lilzoid',
  password => 'zoid101',
});
ok $user_id, 'add_user returned a value';
my $user = $model->user('lilzoid');
is_deeply $user, {
  id => $user_id,
  username => 'lilzoid',
  name => 'Zoidberg',
  items => [],
}, 'correct initial user state';
is_deeply $model->all_users, [{name => 'Zoidberg', username => 'lilzoid'}], 'user in list of users';

ok $model->check_password('lilzoid', 'zoid101'), 'correct password';
ok !$model->check_password('lilzoid', 'bad pass'), 'incorrect password';
ok !$model->check_password('lilzoid', ''), 'incorrect password';
ok !$model->check_password('lilzoid', undef), 'incorrect password';

my $item_id = $model->add_item($user, {
  title => 'Dark Matter',
  url   => 'lordnibbler.org',
});
ok $item_id, 'add_item returned a value';
$user = $model->user('lilzoid');
is_deeply $user, {
  id => $user_id,
  username => 'lilzoid',
  name => 'Zoidberg',
  items => [
    {
      id => $item_id,
      purchased => 0,
      title => 'Dark Matter',
      url   => 'lordnibbler.org',
    },
  ],
}, 'correct initial user state';

done_testing;

