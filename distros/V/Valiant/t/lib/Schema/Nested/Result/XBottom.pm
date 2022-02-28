package Schema::Nested::Result::XBottom;

use base 'Schema::Result';

__PACKAGE__->table("bottom");

__PACKAGE__->add_columns(
  bottom_id => { data_type => 'integer', is_nullable => 0, is_auto_increment => 1 },
  bottom_value => { data_type => 'varchar', is_nullable => 0, size => 48 },
  middle_id => { data_type => 'integer', is_nullable => 0, is_foreign_key => 1 }
);

__PACKAGE__->set_primary_key("bottom_id");

__PACKAGE__->belongs_to(
  middle =>
  'Schema::Nested::Result::XMiddle',
  { 'foreign.middle_id' => 'self.middle_id' },
);

__PACKAGE__->has_many(
  children =>
  'Schema::Nested::Result::XChild',
  { 'foreign.bottom_id' => 'self.bottom_id' },
);

__PACKAGE__->validates( children => ( set_size => {min=>3} ));
__PACKAGE__->validates( bottom_value => (presence => 1, length => [4,48] ));
__PACKAGE__->validates_with(sub {
    my ($self, $opts) = @_;
    $self->errors->add(undef, 'No CCC') if (($self->bottom_value||'') eq 'ccc');
  });

__PACKAGE__->accept_nested_for('children');
1;
