package Schema::Nested::Result::Child;

use base 'Schema::Result';

__PACKAGE__->table("child");

__PACKAGE__->add_columns(
  id => { data_type => 'bigint', is_nullable => 0, is_auto_increment => 1 },  
  parent_id => { data_type => 'integer', is_nullable => 0, is_foreign_key => 1 },
  value => { data_type => 'varchar', is_nullable => 0, size => 48 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
  parent =>
  'Schema::Nested::Result::Parent',
  { 'foreign.id' => 'self.parent_id' },
);

__PACKAGE__->validates(value => (presence=>1, length=>[5,18]));

1;
