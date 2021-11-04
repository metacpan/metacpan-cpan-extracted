package Example::Schema::ResultSet::Person;

use Example::Base;
use base 'Example::Schema::ResultSet';

sub authenticate($self, $username='', $password='') {
  my $user = $self->find_or_new({username=>$username});
  $user->errors->add(undef, 'Invalid login credentials')
    unless $user->in_storage && $user->check_password($password);
  return $user;
}

1;
