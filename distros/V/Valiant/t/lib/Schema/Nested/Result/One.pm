package Schema::Nested::Result::One;

use base 'Schema::Result';

__PACKAGE__->table("one");

# Ok so there's two types of one to one relationships.   The first is
# identifying, where the owning table PK is part of the PK.   Use this
# when changing the relationship changes the identity of the record (that
# is it would impact downstream relationships).   However if the FK isn't
# part of the PK and instead is just a stand alone UNIQUE FK that means in
# theory you can reassign the record to another record in the parent table
# without changing its core identitiy.  Think of it like this. Non identifying
# would be like if a person could own a special sword (of which there is only
# one) but that sword could be given to another person. Identifying would be
# something like a Persons parents or other similar demographic info.  You can't
# really change that so its identifiying.
#
# Think of the non identifying one-one as a type of one-many but where the FK is required to be unique.
#
# For the purposes of this test it doesn't matter since the rules look at PK to
# FK or any other unique fields.   To make life simple I will just have an identifying
# relationship.

__PACKAGE__->add_columns(
  one_id => { data_type => 'integer', is_nullable => 0, is_foreign_key => 1 },
  value => { data_type => 'varchar', is_nullable => 0, size => 48 },
);

__PACKAGE__->set_primary_key("one_id");

__PACKAGE__->belongs_to(
  oneone =>
  'Schema::Nested::Result::OneOne',
  { 'foreign.id' => 'self.one_id' },
);

__PACKAGE__->might_have(
  might =>
  'Schema::Nested::Result::Might',
  { 'foreign.one_id' => 'self.one_id' },
);

__PACKAGE__->add_unique_constraint(['value']);

__PACKAGE__->validates(value => (presence=>1, length=>[2,48]));
__PACKAGE__->validates(might => ( result=>+{validations=>1} ));
#__PACKAGE__->validates(oneone => ( result=>+{validations=>1} ));

__PACKAGE__->accept_nested_for(
  might => {
    update_only => 1,
    reject_if => sub {
      my ($self, $params) = @_;
      return ($params->{value}||'') eq 'test14' ? 1:0;
    },
  }
);

__PACKAGE__->accept_nested_for('oneone', {update_only=>1});

1;
