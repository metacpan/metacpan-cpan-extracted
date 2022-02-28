package Example::Schema::ResultSet::Person;

use Example::Syntax;
use base 'Example::Schema::ResultSet';

sub find_by_id($self, $id) {
  return $self->find({id=>$id});
}

sub authenticate($self, $username='', $password='') {
  my $user = $self->find_or_new({username=>$username});
  $user->errors->add(undef, 'Invalid login credentials')
    unless $user->in_storage && $user->check_password($password);
  return $user;
}

1;
