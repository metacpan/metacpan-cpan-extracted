package Schema::Nested::Result::Role;

use strict;
use warnings;

use base 'Schema::Result';

__PACKAGE__->table("role");

__PACKAGE__->add_columns(
  id => { data_type => 'integer', is_nullable => 0, is_auto_increment => 1 },
  label => { data_type => 'varchar', is_nullable => 0, size => '24' },
);

__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint(['label']);

__PACKAGE__->has_many(
  person_roles =>
  'Schema::Nested::Result::PersonRole',
  { 'foreign.role_id' => 'self.id' }
);

__PACKAGE__->validates(label=>(presence=>1,with=>'is_existing_label'));

sub is_existing_label {
  my ($self, $attribute_name, $value) = @_;
  return if my $result = $self->result_source->resultset->find({$attribute_name=>$value});
  $self->errors->add($attribute_name, \'{{value}} is not a valid'); 
}

1;
