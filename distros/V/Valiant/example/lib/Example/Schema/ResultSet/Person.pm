package Example::Schema::ResultSet::Person;

use Example::Syntax;
use base 'Example::Schema::ResultSet';

sub find_by_id($self, $id) {
  return $self->find({id=>$id});
}

sub account_for($self, $user) {
  return $self->find_account($user->id);
}

sub find_account($self, $id) {
  my $account = $self->find(
    { 'me.id' => $id },
    { prefetch => ['profile', {profile=>'state'}, {profile=>'employment'}, 'credit_cards', {person_roles => 'role' }] }
  );
  $account->build_related_if_empty('profile'); # Needed since the relationship is optional
  $account->profile->build_related_if_empty('employment'); # Needed since the relationship is optional
  $account->profile->status('pending') unless defined($account->profile->status);
  return $account;
}

sub accessible_people_for($self, $user) {
  # For now a user can only access themselves
  return $self->search(
    { 'me.id' => $user->id },
  );
} 

sub unauthenticated_user($self, $args=+{}) {
  return $self->new_result($args);  
}

1;
