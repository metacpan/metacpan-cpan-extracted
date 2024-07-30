package Example::Schema::Result::Employment;

use strict;
use warnings;

use base 'Example::Schema::Result';

__PACKAGE__->table("employment");

__PACKAGE__->add_columns(
  id => { data_type => 'integer', is_nullable => 0, is_auto_increment => 1, tags => ['radio_value'] },
  label => { data_type => 'varchar', is_nullable => 0, size => '24', tags=>['radio_label'] },
);

__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint(['label']);

__PACKAGE__->has_many(
  profile =>
  'Example::Schema::Result::Profile',
  { 'foreign.employment_id' => 'self.id' }
);

1;
