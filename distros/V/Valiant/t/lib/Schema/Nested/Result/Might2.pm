package Schema::Nested::Result::Might2;

use base 'Schema::Result';

__PACKAGE__->table("might");

__PACKAGE__->add_columns(
  id => { data_type => 'bigint', is_nullable => 0, is_auto_increment => 1 },
  one_id => { data_type => 'integer', is_nullable => 0, is_foreign_key => 1 },
  value => { data_type => 'varchar', is_nullable => 0, size => 48 },
);

__PACKAGE__->validates(value => (presence=>1, length=>[1,8]));

__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint(['one_id']);
__PACKAGE__->add_unique_constraint(['value']);

__PACKAGE__->belongs_to(
  one =>
  'Schema::Nested::Result::One2',
  { 'foreign.one_id' => 'self.one_id' }
);

__PACKAGE__->accept_nested_for('one');

1;
