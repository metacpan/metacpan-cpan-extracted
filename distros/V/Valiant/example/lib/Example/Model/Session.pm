package Example::Model::Session;

use Moo;
use Example::Syntax;

extends 'Catalyst::Model';
with 'Catalyst::Component::InstancePerContext';

has user_id => (is=>'rw', clearer=>1, predicate=>1);
has todo_query => (is=>'rw', clearer=>1, predicate=>1);
has contacts_query => (is=>'rw', clearer=>1, predicate=>1);

sub build_per_context_instance($self, $c) {
  return bless $c->session, ref($self);
}

sub logout($self) {
  $self->clear_user_id;
  $self->clear_todo_query;
  $self->clear_contacts_query
}

1;
