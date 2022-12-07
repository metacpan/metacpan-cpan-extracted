package Example::Schema::ResultSet::Person;

use Example::Syntax;
use base 'Example::Schema::ResultSet';

sub find_by_id($self, $id) {
  return $self->find({id=>$id});
}

sub account_for($self, $user) {
  my $account = $self->find(
    { 'me.id' => $user->id },
    { prefetch => ['profile', {profile=>'state'}, {profile=>'employment'}, 'credit_cards', {person_roles => 'role' }] }
  );
  $account->build_related_if_empty('profile'); # Needed since the relationship is optional
  $account->profile->status('pending') unless defined($account->profile->status);
  return $account;
}

sub unauthenticated_user($self, $args=+{}) {
  return $self->new_result($args);  
}

1;
