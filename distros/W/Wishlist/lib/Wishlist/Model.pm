package Wishlist::Model;
use Mojo::Base -base;

use Carp ();
use Passwords ();

has sqlite => sub { Carp::croak 'sqlite is required' };

sub add_user {
  my ($self, $user) = @_;
  Carp::croak 'password is required'
    unless $user->{password};
  $user->{password} = Passwords::password_hash($user->{password});
  return $self
    ->sqlite
    ->db
    ->insert(users => $user)
    ->last_insert_id;
}

sub check_password {
  my ($self, $username, $password) = @_;
  return undef unless $password;
  my $user = $self
    ->sqlite
    ->db
    ->select(
      'users' => ['password'],
      {username => $username},
    )->hash;
  return undef unless $user;
  return Passwords::password_verify(
    $password,
    $user->{password},
  );
}

sub user {
  my ($self, $username) = @_;
  my $sql = <<'  SQL';
    select
      user.id,
      user.name,
      user.username,
      (
        select
          json_group_array(item)
        from (
          select json_object(
            'id',        items.id,
            'title',     items.title,
            'url',       items.url,
            'purchased', items.purchased
          ) as item
          from items
          where items.user_id=user.id
        )
      ) as items
    from users user
    where user.username=?
  SQL
  return $self
    ->sqlite
    ->db
    ->query($sql, $username)
    ->expand(json => 'items')
    ->hash;
}

sub all_users {
  my $self = shift;
  return $self
    ->sqlite
    ->db
    ->select(
      'users' => [qw/username name/],
      undef,
      {-asc => 'name'},
    )
    ->hashes;
}

sub add_item {
  my ($self, $user, $item) = @_;
  $item->{user_id} = $user->{id};
  return $self
    ->sqlite
    ->db
    ->insert('items' => $item)
    ->last_insert_id;
}

sub update_item {
  my ($self, $item, $purchased) = @_;
  return $self
    ->sqlite
    ->db
    ->update(
      'items',
      {purchased => $purchased},
      {id => $item->{id}},
    )->rows;
}

sub remove_item {
  my ($self, $item) = @_;
  return $self
    ->sqlite
    ->db
    ->delete(
      'items',
      {id => $item->{id}},
    )->rows;
}

1;

