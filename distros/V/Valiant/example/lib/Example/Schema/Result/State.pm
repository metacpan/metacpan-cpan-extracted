package Example::Schema::Result::State;

use strict;
use warnings;

use base 'Example::Schema::Result';

__PACKAGE__->table("state");
__PACKAGE__->load_components(qw/Valiant::Result/);

__PACKAGE__->add_columns(
  id => { data_type => 'integer', is_nullable => 0, is_auto_increment => 1 },
  name => { data_type => 'varchar', is_nullable => 0, size => '24' },
  abbreviation => { data_type => 'varchar', is_nullable => 0, size => '24' },
);

__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint(['name']);
__PACKAGE__->add_unique_constraint(['abbreviation']);

__PACKAGE__->validates(name => (presence=>1, length=>[2,18], with=>'isa_state_name'));

__PACKAGE__->has_many(
   profiles =>
  'Example::Schema::Result::Profile',
  { 'foreign.state_id' => 'self.id' }
);

sub isa_state_name {
  my ($self, $attribute_name, $value) = @_;
  return if $self->result_source->resultset->find({name=>$value});
  $self->errors->add($attribute_name, '{{value}} is not a State name'); 
}

1;
