package Example::Schema::Result::Contact;

use Example::Syntax;
use base 'Example::Schema::Result';

__PACKAGE__->table("contact");
__PACKAGE__->load_components(qw/Valiant::Result/);

__PACKAGE__->add_columns(
  id => { data_type => 'bigint', is_nullable => 0, is_auto_increment => 1 },
  person_id => { data_type => 'integer', is_nullable => 0, is_foreign_key => 1 },
  first_name => { data_type => 'varchar', is_nullable => 0, size => 24 },
  last_name => { data_type => 'varchar', is_nullable => 0, size => 48 },
  notes => { data_type => 'text', is_nullable => 1 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
  person =>
  'Example::Schema::Result::Person',
  { 'foreign.id' => 'self.person_id' }
);

__PACKAGE__->has_many(
  emails =>
  'Example::Schema::Result::Contact::Email',
  { 'foreign.contact_id' => 'self.id' }
);

__PACKAGE__->has_many(
  phones =>
  'Example::Schema::Result::Contact::Phone',
  { 'foreign.contact_id' => 'self.id' }
);

__PACKAGE__->validates(first_name => (presence=>1, length=>[2,24]));
__PACKAGE__->validates(last_name => (presence=>1, length=>[2,48]));

__PACKAGE__->accept_nested_for('emails', +{allow_destroy=>1});
__PACKAGE__->accept_nested_for('phones', +{allow_destroy=>1});

sub set_from_request($self, $r) {
  $self->set_columns_recursively($r->nested_params)
      ->insert_or_update;
  return $self->valid;
}

1;
