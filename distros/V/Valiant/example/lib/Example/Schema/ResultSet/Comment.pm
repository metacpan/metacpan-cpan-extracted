package Example::Schema::ResultSet::Comment;

use Example::Syntax;
use base 'Example::Schema::ResultSet';

sub find_with_person($self, $id) {
  return $self->find({id=>$id}, {prefetch=>'person'});
}

sub build_for_user($self, $person) {
  return $self->new_result({person_id=>$person->id});
}
1;
