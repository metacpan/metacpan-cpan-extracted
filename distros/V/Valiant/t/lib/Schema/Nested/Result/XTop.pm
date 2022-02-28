package Schema::Nested::Result::XTop;

use base 'Schema::Result';

__PACKAGE__->table("top");

__PACKAGE__->add_columns(
  top_id => { data_type => 'integer', is_nullable => 0, is_auto_increment => 1 },
  top_value => { data_type => 'varchar', is_nullable => 0, size => 48 },
);

__PACKAGE__->set_primary_key("top_id");

__PACKAGE__->has_one(
  middle =>
  'Schema::Nested::Result::XMiddle',
  { 'foreign.top_id' => 'self.top_id' },
);


__PACKAGE__->validates( top_value => ( presence => 1, length => [4,48] ));
#__PACKAGE__->validates( middle => ( result => +{ validations => 1} ));
__PACKAGE__->accept_nested_for( middle => +{ update_only => 1 } );

1;
