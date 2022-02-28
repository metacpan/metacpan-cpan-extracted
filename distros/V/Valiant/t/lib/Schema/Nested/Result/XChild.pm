package Schema::Nested::Result::XChild;

use base 'Schema::Result';

__PACKAGE__->table("xchild");

__PACKAGE__->add_columns(
  id => { data_type => 'bigint', is_nullable => 0, is_auto_increment => 1 },  
  bottom_id => { data_type => 'integer', is_nullable => 0, is_foreign_key => 1 },
  child_value => { data_type => 'varchar', is_nullable => 0, size => 48 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
  bottom => 'Schema::Nested::Result::XBottom',
  { 'foreign.bottom_id' => 'self.bottom_id' },
);

__PACKAGE__->validates(child_value => (presence=>1, length=>[5,18]));

1;
